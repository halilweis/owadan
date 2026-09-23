<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\AvailabilityException;
use App\Entity\PortfolioItem;
use App\Entity\ProfessionalProfile;
use App\Entity\WorkingHours;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Uid\Uuid;
use App\Entity\Booking;
use App\Entity\ProfessionalService;
use App\Enum\BookingStatus;
use Symfony\Component\HttpFoundation\Request;
use App\Enum\VerificationStatus;

final class PublicProfessionalAvailabilityController extends AbstractController
{
    #[Route('/api/v1/professionals/{id}/portfolio', methods: ['GET'])]
    public function portfolio(
        string $id,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $profile = $entityManager->find(ProfessionalProfile::class, Uuid::fromString($id));

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'NOT_FOUND']], 404);
        }

        $items = $entityManager->getRepository(PortfolioItem::class)->findBy([
            'professional' => $profile,
            'active' => true,
        ]);

        return $this->json([
            'data' => [
                'portfolio' => array_map(
                    static fn (PortfolioItem $item) => [
                        'id' => (string) $item->getId(),
                        'imageUrl' => $item->getImageUrl(),
                        'title' => $item->getTitle(),
                        'description' => $item->getDescription(),
                        'featured' => $item->isFeatured(),
                    ],
                    $items
                ),
            ],
        ]);
    }

    #[Route('/api/v1/professionals/{id}/availability', methods: ['GET'])]
    public function availability(
        string $id,
        Request $request,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        try {
            $profileId = Uuid::fromString($id);
        } catch (\InvalidArgumentException) {
            return $this->json(['error' => ['code' => 'NOT_FOUND']], 404);
        }

        $profile = $entityManager->find(ProfessionalProfile::class, $profileId);

        if (!$profile instanceof ProfessionalProfile || !$profile->isActive() || $profile->getVerificationStatus() !== VerificationStatus::APPROVED) {
            return $this->json(['error' => ['code' => 'NOT_FOUND']], 404);
        }

        $serviceId = trim((string) $request->query->get('serviceId', ''));
        $date = trim((string) $request->query->get('date', ''));

        if ($serviceId === '' || $date === '') {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'serviceId and date are required.',
                ],
            ], 422);
        }

        try {
            $serviceUuid = Uuid::fromString($serviceId);
        } catch (\InvalidArgumentException) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'serviceId is invalid.',
                ],
            ], 422);
        }

        $service = $entityManager->find(ProfessionalService::class, $serviceUuid);

        if (
            !$service instanceof ProfessionalService
            || !$service->isActive()
            || $service->getProfessional()->getId() !== $profile->getId()
        ) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'serviceId is invalid.',
                ],
            ], 422);
        }

        $timezone = new \DateTimeZone('Asia/Ashgabat');

        try {
            $day = new \DateTimeImmutable($date . ' 00:00:00', $timezone);
        } catch (\Exception) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'date must use YYYY-MM-DD format.',
                ],
            ], 422);
        }

        if ($day->format('Y-m-d') !== $date) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'date must use YYYY-MM-DD format.',
                ],
            ], 422);
        }

        $dayOfWeek = (int) $day->format('N');

        $workingHours = $entityManager->getRepository(WorkingHours::class)->findBy([
            'professional' => $profile,
            'dayOfWeek' => $dayOfWeek,
            'active' => true,
        ], [
            'startTime' => 'ASC',
        ]);

        $dayEnd = $day->modify('+1 day');

        $exceptions = $entityManager->createQueryBuilder()
            ->select('a')
            ->from(AvailabilityException::class, 'a')
            ->where('a.professional = :professional')
            ->andWhere('a.startsAt < :dayEnd')
            ->andWhere('a.endsAt > :dayStart')
            ->setParameter('professional', $profile)
            ->setParameter('dayStart', $day)
            ->setParameter('dayEnd', $dayEnd)
            ->getQuery()
            ->getResult();

        $bookings = $entityManager->createQueryBuilder()
            ->select('b')
            ->from(Booking::class, 'b')
            ->where('b.professional = :professional')
            ->andWhere('b.startsAt < :dayEnd')
            ->andWhere('b.endsAt > :dayStart')
            ->andWhere('b.status IN (:statuses)')
            ->setParameter('professional', $profile)
            ->setParameter('dayStart', $day)
            ->setParameter('dayEnd', $dayEnd)
            ->setParameter('statuses', [
                BookingStatus::PENDING,
                BookingStatus::CONFIRMED,
            ])
            ->getQuery()
            ->getResult();

        $windows = [];

        foreach ($workingHours as $hours) {
            $windows[] = [
                'start' => new \DateTimeImmutable(
                    $date . ' ' . $hours->getStartTime(),
                    $timezone
                ),
                'end' => new \DateTimeImmutable(
                    $date . ' ' . $hours->getEndTime(),
                    $timezone
                ),
            ];
        }

        foreach ($exceptions as $exception) {
            if ($exception->getType() === 'EXTRA') {
                $windows[] = [
                    'start' => $exception->getStartsAt(),
                    'end' => $exception->getEndsAt(),
                ];
            }
        }

        $duration = $service->getDurationMinutes();
        $stepMinutes = 30;
        $slots = [];

        foreach ($windows as $window) {
            $slotStart = $window['start'];

            while (true) {
                $slotEnd = $slotStart->modify(sprintf('+%d minutes', $duration));

                if ($slotEnd > $window['end']) {
                    break;
                }

                $blocked = false;

                foreach ($exceptions as $exception) {
                    if (
                        $exception->getType() === 'BLOCKED'
                        && $exception->getStartsAt() < $slotEnd
                        && $exception->getEndsAt() > $slotStart
                    ) {
                        $blocked = true;
                        break;
                    }
                }

                if (!$blocked) {
                    foreach ($bookings as $booking) {
                        if (
                            $booking->getStartsAt() < $slotEnd
                            && $booking->getEndsAt() > $slotStart
                        ) {
                            $blocked = true;
                            break;
                        }
                    }
                }

                if (!$blocked && $slotStart > new \DateTimeImmutable('now', $timezone)) {
                    $slots[] = [
                        'startsAt' => $slotStart->format(DATE_ATOM),
                        'endsAt' => $slotEnd->format(DATE_ATOM),
                    ];
                }

                $slotStart = $slotStart->modify(
                    sprintf('+%d minutes', $stepMinutes)
                );
            }
        }

        usort(
            $slots,
            static fn (array $a, array $b): int =>
                strcmp($a['startsAt'], $b['startsAt'])
        );

        return $this->json([
            'data' => [
                'professionalId' => (string) $profile->getId(),
                'serviceId' => (string) $service->getId(),
                'date' => $date,
                'durationMinutes' => $duration,
                'slots' => $slots,
            ],
        ]);
    }
}