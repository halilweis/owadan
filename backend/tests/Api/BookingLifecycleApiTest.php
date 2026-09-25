<?php

declare(strict_types=1);

namespace App\Tests\Api;

use App\Entity\Booking;
use App\Entity\Notification;
use App\Entity\Review;
use App\Entity\WorkingHours;
use App\Enum\BookingStatus;
use App\Tests\Support\DatabaseResetTrait;
use App\Tests\Support\FixtureFactory;
use Doctrine\ORM\EntityManagerInterface;
use Lexik\Bundle\JWTAuthenticationBundle\Services\JWTTokenManagerInterface;
use Symfony\Bundle\FrameworkBundle\KernelBrowser;
use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class BookingLifecycleApiTest extends WebTestCase
{
    use DatabaseResetTrait;

    private KernelBrowser $client;
    private EntityManagerInterface $entityManager;
    private JWTTokenManagerInterface $jwt;
    private FixtureFactory $fixtures;

    protected function setUp(): void
    {
        self::ensureKernelShutdown();

        $this->client = static::createClient();
        $this->entityManager = static::getContainer()->get(EntityManagerInterface::class);
        $this->jwt = static::getContainer()->get(JWTTokenManagerInterface::class);

        $this->resetDatabase($this->entityManager);
        $this->fixtures = new FixtureFactory($this->entityManager);
    }

    public function testFullCreateConfirmCompleteAndReviewLifecycle(): void
    {
        $fixture = $this->createBookableFixture(
            '+99361003401',
            '+99361003402',
            'booking-full',
        );

        $customerToken = $this->jwt->create($fixture['customer']);
        $professionalToken = $this->jwt->create($fixture['professionalUser']);

        $this->client->jsonRequest(
            'POST',
            '/api/v1/bookings',
            [
                'serviceId' => (string) $fixture['service']->getId(),
                'startsAt' => $fixture['startsAt']->format(DATE_ATOM),
                'note' => 'Lifecycle integration test',
            ],
            [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $customerToken,
            ],
        );

        self::assertResponseStatusCodeSame(201);

        $bookingId = $this->responseJson()['data']['booking']['id'];
        self::assertSame(
            BookingStatus::PENDING->value,
            $this->responseJson()['data']['booking']['status'],
        );

        $this->client->request(
            'POST',
            '/api/v1/pro/bookings/' . $bookingId . '/confirm',
            server: [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $professionalToken,
            ],
        );

        self::assertResponseIsSuccessful();
        self::assertSame(
            BookingStatus::CONFIRMED->value,
            $this->responseJson()['data']['booking']['status'],
        );

        $this->client->request(
            'POST',
            '/api/v1/pro/bookings/' . $bookingId . '/complete',
            server: [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $professionalToken,
            ],
        );

        self::assertResponseIsSuccessful();
        self::assertSame(
            BookingStatus::COMPLETED->value,
            $this->responseJson()['data']['booking']['status'],
        );

        $this->client->jsonRequest(
            'POST',
            '/api/v1/bookings/' . $bookingId . '/review',
            [
                'rating' => 5,
                'comment' => 'Lifecycle completed successfully',
            ],
            [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $customerToken,
            ],
        );

        self::assertResponseStatusCodeSame(201);
        self::assertSame(5, $this->responseJson()['data']['review']['rating']);

        self::assertSame(
            1,
            $this->entityManager->getRepository(Review::class)->count([]),
        );

        self::assertGreaterThanOrEqual(
            4,
            $this->entityManager->getRepository(Notification::class)->count([]),
        );
    }

    public function testProfessionalCanDeclinePendingBooking(): void
    {
        $fixture = $this->createBookableFixture(
            '+99361003403',
            '+99361003404',
            'booking-decline',
        );

        $booking = $this->persistPendingBooking($fixture);
        $professionalToken = $this->jwt->create($fixture['professionalUser']);

        $this->client->request(
            'POST',
            '/api/v1/pro/bookings/' . $booking->getId() . '/decline',
            server: [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $professionalToken,
            ],
        );

        self::assertResponseIsSuccessful();
        self::assertSame(
            BookingStatus::DECLINED->value,
            $this->responseJson()['data']['booking']['status'],
        );
    }

    public function testCustomerCanCancelPendingBooking(): void
    {
        $fixture = $this->createBookableFixture(
            '+99361003405',
            '+99361003406',
            'booking-customer-cancel',
        );

        $booking = $this->persistPendingBooking($fixture);
        $customerToken = $this->jwt->create($fixture['customer']);

        $this->client->request(
            'POST',
            '/api/v1/bookings/' . $booking->getId() . '/cancel',
            server: [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $customerToken,
            ],
        );

        self::assertResponseIsSuccessful();
        self::assertSame(
            BookingStatus::CANCELLED_BY_CUSTOMER->value,
            $this->responseJson()['data']['booking']['status'],
        );
    }

    public function testProfessionalCanMarkConfirmedBookingNoShow(): void
    {
        $fixture = $this->createBookableFixture(
            '+99361003407',
            '+99361003408',
            'booking-no-show',
        );

        $booking = $this->persistPendingBooking($fixture);
        $booking->confirm();
        $this->entityManager->flush();

        $professionalToken = $this->jwt->create($fixture['professionalUser']);

        $this->client->request(
            'POST',
            '/api/v1/pro/bookings/' . $booking->getId() . '/no-show',
            server: [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $professionalToken,
            ],
        );

        self::assertResponseIsSuccessful();
        self::assertSame(
            BookingStatus::NO_SHOW->value,
            $this->responseJson()['data']['booking']['status'],
        );
    }

    public function testAnotherProfessionalCannotChangeBooking(): void
    {
        $fixture = $this->createBookableFixture(
            '+99361003409',
            '+99361003410',
            'booking-owner',
        );

        $other = $this->fixtures->createProfessionalServiceFixture(
            phoneNumber: '+99361003411',
            displayName: 'Other Booking Professional',
            categorySlug: 'booking-other',
            serviceName: 'Other Booking Service',
        );

        $other['user']->setRoles([
            'ROLE_CUSTOMER',
            'ROLE_PROFESSIONAL',
        ]);
        $this->entityManager->flush();

        $booking = $this->persistPendingBooking($fixture);
        $otherToken = $this->jwt->create($other['user']);

        $this->client->request(
            'POST',
            '/api/v1/pro/bookings/' . $booking->getId() . '/confirm',
            server: [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $otherToken,
            ],
        );

        self::assertResponseStatusCodeSame(403);
    }

    /**
     * @return array{
     *     customer: \App\Entity\User,
     *     professionalUser: \App\Entity\User,
     *     profile: \App\Entity\ProfessionalProfile,
     *     service: \App\Entity\ProfessionalService,
     *     startsAt: \DateTimeImmutable
     * }
     */
    private function createBookableFixture(
        string $customerPhone,
        string $professionalPhone,
        string $slug,
    ): array {
        $customer = $this->fixtures->createCustomer($customerPhone);

        $professional = $this->fixtures->createProfessionalServiceFixture(
            phoneNumber: $professionalPhone,
            displayName: 'Booking Professional',
            categorySlug: $slug,
            serviceName: 'Booking Service',
            durationMinutes: 60,
        );

        $professional['user']->setRoles([
            'ROLE_CUSTOMER',
            'ROLE_PROFESSIONAL',
        ]);

        $startsAt = (new \DateTimeImmutable('+8 days'))
            ->setTime(10, 0, 0);

        $workingHours = new WorkingHours(
            $professional['profile'],
            (int) $startsAt->format('N'),
            '09:00',
            '18:00',
        );

        $this->entityManager->persist($workingHours);
        $this->entityManager->flush();

        return [
            'customer' => $customer,
            'professionalUser' => $professional['user'],
            'profile' => $professional['profile'],
            'service' => $professional['service'],
            'startsAt' => $startsAt,
        ];
    }

    /**
     * @param array{
     *     customer: \App\Entity\User,
     *     professionalUser: \App\Entity\User,
     *     profile: \App\Entity\ProfessionalProfile,
     *     service: \App\Entity\ProfessionalService,
     *     startsAt: \DateTimeImmutable
     * } $fixture
     */
    private function persistPendingBooking(array $fixture): Booking
    {
        $booking = new Booking(
            $fixture['customer'],
            $fixture['profile'],
            $fixture['service'],
            $fixture['startsAt'],
            $fixture['startsAt']->modify('+60 minutes'),
            $fixture['service']->getName(),
            $fixture['service']->getPriceType()->value,
            $fixture['service']->getPrice(),
            $fixture['service']->getCurrency(),
            'Lifecycle state test',
        );

        $this->entityManager->persist($booking);
        $this->entityManager->flush();

        return $booking;
    }

    /**
     * @return array<string, mixed>
     */
    private function responseJson(): array
    {
        return json_decode(
            $this->client->getResponse()->getContent() ?: '',
            true,
            512,
            JSON_THROW_ON_ERROR,
        );
    }
}
