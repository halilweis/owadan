<?php

declare(strict_types=1);

namespace App\Tests\Api;

use App\Entity\Booking;
use App\Entity\Category;
use App\Entity\ProfessionalProfile;
use App\Entity\ProfessionalService;
use App\Entity\Review;
use App\Entity\User;
use App\Entity\WorkingHours;
use App\Enum\PriceType;
use App\Service\Auth\TokenIssuer;
use Doctrine\ORM\EntityManagerInterface;
use Lexik\Bundle\JWTAuthenticationBundle\Services\JWTTokenManagerInterface;
use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;
use Symfony\Bundle\FrameworkBundle\KernelBrowser;

final class HighRiskApiTest extends WebTestCase
{
    private EntityManagerInterface $entityManager;
    private KernelBrowser $client;

    protected function setUp(): void
    {
        self::ensureKernelShutdown();

        $this->client = static::createClient();

        $this->entityManager = static::getContainer()
            ->get(EntityManagerInterface::class);

        $this->entityManager
            ->getConnection()
            ->executeStatement(
                'TRUNCATE TABLE review, booking, working_hours, professional_service, professional_profile, refresh_token, notification, app_user, category RESTART IDENTITY CASCADE'
            );
    }

    public function testRefreshTokenRotationInvalidatesOldToken(): void
    {
        $user = new User('+99361000001');

        $this->entityManager->persist($user);
        $this->entityManager->flush();

        /** @var TokenIssuer $issuer */
        $issuer = static::getContainer()->get(TokenIssuer::class);

        $first = $issuer->issue($user);

        $this->client->jsonRequest(
            'POST',
            '/api/v1/auth/refresh',
            [
                'refreshToken' => $first['refreshToken'],
            ],
        );

        self::assertResponseIsSuccessful();

        $response = json_decode(
            $this->client->getResponse()->getContent() ?: '',
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        $newRefreshToken = $response['data']['tokens']['refreshToken'];

        self::assertNotSame(
            $first['refreshToken'],
            $newRefreshToken,
        );

        $this->client->jsonRequest(
            'POST',
            '/api/v1/auth/refresh',
            [
                'refreshToken' => $first['refreshToken'],
            ],
        );

        self::assertResponseStatusCodeSame(401);

        $response = json_decode(
            $this->client->getResponse()->getContent() ?: '',
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        self::assertSame(
            'REFRESH_TOKEN_INVALID',
            $response['error']['code'] ?? null,
        );
    }

    public function testLogoutAllRevokesEveryRefreshToken(): void
    {
        $user = new User('+99361000002');

        $this->entityManager->persist($user);
        $this->entityManager->flush();

        /** @var TokenIssuer $issuer */
        $issuer = static::getContainer()->get(TokenIssuer::class);

        /** @var JWTTokenManagerInterface $jwt */
        $jwt = static::getContainer()->get(
            JWTTokenManagerInterface::class
        );

        $sessionOne = $issuer->issue($user);
        $sessionTwo = $issuer->issue($user);

        $accessToken = $jwt->create($user);

        $this->client->request(
            'POST',
            '/api/v1/auth/logout-all',
            server: [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $accessToken,
            ],
        );

        self::assertResponseIsSuccessful();

        $this->client->jsonRequest(
            'POST',
            '/api/v1/auth/refresh',
            [
                'refreshToken' => $sessionOne['refreshToken'],
            ],
        );

        self::assertResponseStatusCodeSame(401);

        $this->client->jsonRequest(
            'POST',
            '/api/v1/auth/refresh',
            [
                'refreshToken' => $sessionTwo['refreshToken'],
            ],
        );

        self::assertResponseStatusCodeSame(401);
    }

    public function testCustomerCannotReviewAnotherCustomersBooking(): void
    {
        [
            $owner,
            $otherCustomer,
            $professional,
            $service,
            $booking,
        ] = $this->createCompletedBookingFixture();

        /** @var JWTTokenManagerInterface $jwt */
        $jwt = static::getContainer()->get(
            JWTTokenManagerInterface::class
        );

        $token = $jwt->create($otherCustomer);

        $this->client->jsonRequest(
            'POST',
            '/api/v1/bookings/' . $booking->getId() . '/review',
            [
                'rating' => 5,
                'comment' => 'Should not be allowed',
            ],
            [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $token,
            ],
        );

        self::assertResponseStatusCodeSame(403);

        self::assertNull(
            $this->entityManager
                ->getRepository(Review::class)
                ->findOneBy(['booking' => $booking])
        );
    }

    public function testDuplicateReviewIsRejected(): void
    {
        [
            $customer,
            $otherCustomer,
            $professional,
            $service,
            $booking,
        ] = $this->createCompletedBookingFixture();

        /** @var JWTTokenManagerInterface $jwt */
        $jwt = static::getContainer()->get(
            JWTTokenManagerInterface::class
        );

        $token = $jwt->create($customer);

        $this->client->jsonRequest(
            'POST',
            '/api/v1/bookings/' . $booking->getId() . '/review',
            [
                'rating' => 5,
                'comment' => 'Excellent',
            ],
            [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $token,
            ],
        );

        self::assertResponseStatusCodeSame(201);

        $this->client->jsonRequest(
            'POST',
            '/api/v1/bookings/' . $booking->getId() . '/review',
            [
                'rating' => 4,
                'comment' => 'Duplicate',
            ],
            [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $token,
            ],
        );

        self::assertResponseStatusCodeSame(409);

        $response = json_decode(
            $this->client->getResponse()->getContent() ?: '',
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        self::assertSame(
            'REVIEW_ALREADY_EXISTS',
            $response['error']['code'] ?? null,
        );

        self::assertSame(
            1,
            $this->entityManager
                ->getRepository(Review::class)
                ->count(['booking' => $booking])
        );
    }

    private function createCompletedBookingFixture(): array
    {
        $customer = new User('+99361000101');
        $otherCustomer = new User('+99361000102');
        $professionalUser = new User('+99361000103');

        $profile = new ProfessionalProfile(
            $professionalUser,
            'Test Professional',
        );

        $profile->submitForVerification();
        $profile->approve();

        $category = new Category(
            'test-hair',
            [
                'tk' => 'Saç',
                'ru' => 'Волосы',
                'en' => 'Hair',
            ],
        );

        $service = new ProfessionalService(
            $profile,
            $category,
            'Test Haircut',
            60,
            PriceType::FIXED,
            '100.00',
        );

        $startsAt = new \DateTimeImmutable('+2 days 10:00');
        $endsAt = $startsAt->modify('+60 minutes');

        $booking = new Booking(
            $customer,
            $profile,
            $service,
            $startsAt,
            $endsAt,
            $service->getName(),
            $service->getPriceType()->value,
            $service->getPrice(),
            $service->getCurrency(),
        );

        $booking->confirm();
        $booking->complete();

        foreach ([
            $customer,
            $otherCustomer,
            $professionalUser,
            $profile,
            $category,
            $service,
            $booking,
        ] as $entity) {
            $this->entityManager->persist($entity);
        }

        $this->entityManager->flush();

        return [
            $customer,
            $otherCustomer,
            $profile,
            $service,
            $booking,
        ];
    }
}