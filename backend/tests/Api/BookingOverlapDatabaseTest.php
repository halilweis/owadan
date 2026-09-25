<?php

declare(strict_types=1);

namespace App\Tests\Api;

use App\Entity\Booking;
use App\Entity\Category;
use App\Entity\ProfessionalProfile;
use App\Entity\ProfessionalService;
use App\Entity\User;
use App\Enum\PriceType;
use Doctrine\DBAL\Exception\DriverException;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

final class BookingOverlapDatabaseTest extends KernelTestCase
{
    private EntityManagerInterface $entityManager;

    protected function setUp(): void
    {
        self::bootKernel();

        $this->entityManager = static::getContainer()
            ->get(EntityManagerInterface::class);

        $this->entityManager
            ->getConnection()
            ->executeStatement(
                'TRUNCATE TABLE review, booking, working_hours, availability_exception, professional_service, professional_profile, refresh_token, notification, app_user, category RESTART IDENTITY CASCADE'
            );
    }

    protected function tearDown(): void
    {
        if ($this->entityManager->isOpen()) {
            $this->entityManager->clear();
        }

        parent::tearDown();
    }

    public function testDatabaseRejectsOverlappingActiveBookings(): void
    {
        [$customerOne, $customerTwo, $profile, $service] = $this->createFixture();

        $startsAt = new \DateTimeImmutable('+2 days 10:00');
        $endsAt = $startsAt->modify('+60 minutes');

        $first = new Booking(
            $customerOne,
            $profile,
            $service,
            $startsAt,
            $endsAt,
            $service->getName(),
            $service->getPriceType()->value,
            $service->getPrice(),
            $service->getCurrency(),
        );

        $first->confirm();

        $this->entityManager->persist($first);
        $this->entityManager->flush();

        $second = new Booking(
            $customerTwo,
            $profile,
            $service,
            $startsAt->modify('+30 minutes'),
            $endsAt->modify('+30 minutes'),
            $service->getName(),
            $service->getPriceType()->value,
            $service->getPrice(),
            $service->getCurrency(),
        );

        $second->confirm();

        $this->entityManager->persist($second);

        try {
            $this->entityManager->flush();
            self::fail('Expected PostgreSQL to reject overlapping bookings.');
        } catch (DriverException $exception) {
            self::assertSame('23P01', $exception->getSQLState());
        }
    }

    public function testDatabaseAllowsBackToBackBookings(): void
    {
        [$customerOne, $customerTwo, $profile, $service] = $this->createFixture();

        $startsAt = new \DateTimeImmutable('+3 days 10:00');
        $endsAt = $startsAt->modify('+60 minutes');

        $first = new Booking(
            $customerOne,
            $profile,
            $service,
            $startsAt,
            $endsAt,
            $service->getName(),
            $service->getPriceType()->value,
            $service->getPrice(),
            $service->getCurrency(),
        );

        $first->confirm();

        $second = new Booking(
            $customerTwo,
            $profile,
            $service,
            $endsAt,
            $endsAt->modify('+60 minutes'),
            $service->getName(),
            $service->getPriceType()->value,
            $service->getPrice(),
            $service->getCurrency(),
        );

        $second->confirm();

        $this->entityManager->persist($first);
        $this->entityManager->persist($second);
        $this->entityManager->flush();

        self::assertNotNull($first->getId());
        self::assertNotNull($second->getId());
    }

    public function testCancelledBookingDoesNotBlockSameTime(): void
    {
        [$customerOne, $customerTwo, $profile, $service] = $this->createFixture();

        $startsAt = new \DateTimeImmutable('+4 days 10:00');
        $endsAt = $startsAt->modify('+60 minutes');

        $cancelled = new Booking(
            $customerOne,
            $profile,
            $service,
            $startsAt,
            $endsAt,
            $service->getName(),
            $service->getPriceType()->value,
            $service->getPrice(),
            $service->getCurrency(),
        );

        $cancelled->cancelByCustomer();

        $replacement = new Booking(
            $customerTwo,
            $profile,
            $service,
            $startsAt,
            $endsAt,
            $service->getName(),
            $service->getPriceType()->value,
            $service->getPrice(),
            $service->getCurrency(),
        );

        $replacement->confirm();

        $this->entityManager->persist($cancelled);
        $this->entityManager->persist($replacement);
        $this->entityManager->flush();

        self::assertNotNull($cancelled->getId());
        self::assertNotNull($replacement->getId());
    }

    /**
     * @return array{
     *     0: User,
     *     1: User,
     *     2: ProfessionalProfile,
     *     3: ProfessionalService
     * }
     */
    private function createFixture(): array
    {
        $customerOne = new User('+99361001001');
        $customerTwo = new User('+99361001002');
        $professionalUser = new User('+99361001003');

        $profile = new ProfessionalProfile(
            $professionalUser,
            'Overlap Test Professional',
        );

        $profile->submitForVerification();
        $profile->approve();

        $category = new Category(
            'overlap-test',
            [
                'tk' => 'Synag',
                'ru' => 'Тест',
                'en' => 'Test',
            ],
        );

        $service = new ProfessionalService(
            $profile,
            $category,
            'Overlap Test Service',
            60,
            PriceType::FIXED,
            '100.00',
        );

        foreach ([
            $customerOne,
            $customerTwo,
            $professionalUser,
            $profile,
            $category,
            $service,
        ] as $entity) {
            $this->entityManager->persist($entity);
        }

        $this->entityManager->flush();

        return [
            $customerOne,
            $customerTwo,
            $profile,
            $service,
        ];
    }
}
