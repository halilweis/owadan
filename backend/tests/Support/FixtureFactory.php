<?php

declare(strict_types=1);

namespace App\Tests\Support;

use App\Entity\Booking;
use App\Entity\Category;
use App\Entity\ProfessionalProfile;
use App\Entity\ProfessionalService;
use App\Entity\User;
use App\Enum\PriceType;
use Doctrine\ORM\EntityManagerInterface;

final class FixtureFactory
{
    public function __construct(
        private readonly EntityManagerInterface $entityManager,
    ) {
    }

    public function createCustomer(string $phoneNumber): User
    {
        $user = new User($phoneNumber);

        $this->entityManager->persist($user);
        $this->entityManager->flush();

        return $user;
    }

    /**
     * @return array{
     *     user: User,
     *     profile: ProfessionalProfile,
     *     category: Category,
     *     service: ProfessionalService
     * }
     */
    public function createProfessionalServiceFixture(
        string $phoneNumber,
        string $displayName = 'Test Professional',
        string $categorySlug = 'test-hair',
        string $serviceName = 'Test Haircut',
        int $durationMinutes = 60,
        string $price = '100.00',
        bool $approved = true,
    ): array {
        $professionalUser = new User($phoneNumber);

        $profile = new ProfessionalProfile(
            $professionalUser,
            $displayName,
        );

        if ($approved) {
            $profile->submitForVerification();
            $profile->approve();
        }

        $category = new Category(
            $categorySlug,
            [
                'tk' => 'Synag',
                'ru' => 'Тест',
                'en' => 'Test',
            ],
        );

        $service = new ProfessionalService(
            $profile,
            $category,
            $serviceName,
            $durationMinutes,
            PriceType::FIXED,
            $price,
        );

        foreach ([
            $professionalUser,
            $profile,
            $category,
            $service,
        ] as $entity) {
            $this->entityManager->persist($entity);
        }

        $this->entityManager->flush();

        return [
            'user' => $professionalUser,
            'profile' => $profile,
            'category' => $category,
            'service' => $service,
        ];
    }

    /**
     * @return array{
     *     customer: User,
     *     otherCustomer: User,
     *     professionalUser: User,
     *     profile: ProfessionalProfile,
     *     category: Category,
     *     service: ProfessionalService,
     *     booking: Booking
     * }
     */
    public function createCompletedBookingFixture(
        string $customerPhone = '+99361000101',
        string $otherCustomerPhone = '+99361000102',
        string $professionalPhone = '+99361000103',
        ?\DateTimeImmutable $startsAt = null,
    ): array {
        $customer = new User($customerPhone);
        $otherCustomer = new User($otherCustomerPhone);

        $professional = $this->createProfessionalServiceFixture(
            phoneNumber: $professionalPhone,
            displayName: 'Test Professional',
            categorySlug: 'test-hair',
            serviceName: 'Test Haircut',
        );

        $startsAt ??= new \DateTimeImmutable('+2 days 10:00');
        $endsAt = $startsAt->modify(
            '+' . $professional['service']->getDurationMinutes() . ' minutes'
        );

        $booking = new Booking(
            $customer,
            $professional['profile'],
            $professional['service'],
            $startsAt,
            $endsAt,
            $professional['service']->getName(),
            $professional['service']->getPriceType()->value,
            $professional['service']->getPrice(),
            $professional['service']->getCurrency(),
        );

        $booking->confirm();
        $booking->complete();

        foreach ([
            $customer,
            $otherCustomer,
            $booking,
        ] as $entity) {
            $this->entityManager->persist($entity);
        }

        $this->entityManager->flush();

        return [
            'customer' => $customer,
            'otherCustomer' => $otherCustomer,
            'professionalUser' => $professional['user'],
            'profile' => $professional['profile'],
            'category' => $professional['category'],
            'service' => $professional['service'],
            'booking' => $booking,
        ];
    }
}
