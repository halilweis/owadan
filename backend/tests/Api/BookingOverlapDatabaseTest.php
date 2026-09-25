<?php

declare(strict_types=1);

namespace App\Tests\Api;

use App\Entity\Booking;
use App\Tests\Support\DatabaseResetTrait;
use App\Tests\Support\FixtureFactory;
use Doctrine\DBAL\Exception\DriverException;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

final class BookingOverlapDatabaseTest extends KernelTestCase
{
    use DatabaseResetTrait;

    private EntityManagerInterface $entityManager;
    private FixtureFactory $fixtures;

    protected function setUp(): void
    {
        self::bootKernel();

        $this->entityManager = static::getContainer()
            ->get(EntityManagerInterface::class);

        $this->resetDatabase($this->entityManager);

        $this->fixtures = new FixtureFactory(
            $this->entityManager,
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

        self::assertSame(
            2,
            $this->entityManager
                ->getRepository(Booking::class)
                ->count([])
        );
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

        self::assertSame(
            2,
            $this->entityManager
                ->getRepository(Booking::class)
                ->count([])
        );
    }

    private function createFixture(): array
    {
        $customerOne = $this->fixtures
            ->createCustomer('+99361001001');

        $customerTwo = $this->fixtures
            ->createCustomer('+99361001002');

        $professional = $this->fixtures
            ->createProfessionalServiceFixture(
                phoneNumber: '+99361001003',
                displayName: 'Overlap Test Professional',
                categorySlug: 'overlap-test',
                serviceName: 'Overlap Test Service',
            );

        return [
            $customerOne,
            $customerTwo,
            $professional['profile'],
            $professional['service'],
        ];
    }
}
