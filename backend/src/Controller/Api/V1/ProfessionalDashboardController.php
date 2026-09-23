<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\Booking;
use App\Entity\ProfessionalProfile;
use App\Entity\Review;
use App\Entity\User;
use App\Enum\BookingStatus;
use App\Repository\ProfessionalProfileRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

final class ProfessionalDashboardController extends AbstractController
{
    #[Route('/api/v1/pro/dashboard', methods: ['GET'])]
    public function dashboard(
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json([
                'error' => [
                    'code' => 'UNAUTHENTICATED',
                ],
            ], 401);
        }

        $profile = $profiles->findOneByUser($user);

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json([
                'error' => [
                    'code' => 'PROFILE_REQUIRED',
                ],
            ], 409);
        }

        $now = new \DateTimeImmutable();
        $todayStart = $now->setTime(0, 0);
        $todayEnd = $todayStart->modify('+1 day');

        $todayAppointments = $entityManager->createQueryBuilder()
            ->select('COUNT(b.id)')
            ->from(Booking::class, 'b')
            ->where('b.professional = :professional')
            ->andWhere('b.startsAt >= :todayStart')
            ->andWhere('b.startsAt < :todayEnd')
            ->andWhere('b.status IN (:statuses)')
            ->setParameter('professional', $profile)
            ->setParameter('todayStart', $todayStart)
            ->setParameter('todayEnd', $todayEnd)
            ->setParameter('statuses', [
                BookingStatus::PENDING,
                BookingStatus::CONFIRMED,
            ])
            ->getQuery()
            ->getSingleScalarResult();

        $pendingBookings = $entityManager->createQueryBuilder()
            ->select('COUNT(b.id)')
            ->from(Booking::class, 'b')
            ->where('b.professional = :professional')
            ->andWhere('b.status = :status')
            ->setParameter('professional', $profile)
            ->setParameter('status', BookingStatus::PENDING)
            ->getQuery()
            ->getSingleScalarResult();

        $nextAppointment = $entityManager->createQueryBuilder()
            ->select('b')
            ->from(Booking::class, 'b')
            ->where('b.professional = :professional')
            ->andWhere('b.startsAt >= :now')
            ->andWhere('b.status IN (:statuses)')
            ->setParameter('professional', $profile)
            ->setParameter('now', $now)
            ->setParameter('statuses', [
                BookingStatus::PENDING,
                BookingStatus::CONFIRMED,
            ])
            ->orderBy('b.startsAt', 'ASC')
            ->setMaxResults(1)
            ->getQuery()
            ->getOneOrNullResult();

        $completedBookings = $entityManager->createQueryBuilder()
            ->select('COUNT(b.id)')
            ->from(Booking::class, 'b')
            ->where('b.professional = :professional')
            ->andWhere('b.status = :status')
            ->setParameter('professional', $profile)
            ->setParameter('status', BookingStatus::COMPLETED)
            ->getQuery()
            ->getSingleScalarResult();

        $reviewStats = $entityManager->createQueryBuilder()
            ->select('COUNT(r.id) AS reviewCount')
            ->addSelect('AVG(r.rating) AS averageRating')
            ->from(Review::class, 'r')
            ->where('r.professional = :professional')
            ->setParameter('professional', $profile)
            ->getQuery()
            ->getOneOrNullResult();

        return $this->json([
            'data' => [
                'dashboard' => [
                    'todayAppointments' => (int) $todayAppointments,
                    'pendingBookings' => (int) $pendingBookings,
                    'completedBookings' => (int) $completedBookings,
                    'reviewCount' => (int) ($reviewStats['reviewCount'] ?? 0),
                    'averageRating' => isset($reviewStats['averageRating'])
                        ? round((float) $reviewStats['averageRating'], 2)
                        : null,
                    'nextAppointment' => $nextAppointment instanceof Booking
                        ? [
                            'id' => (string) $nextAppointment->getId(),
                            'serviceName' => $nextAppointment->getServiceName(),
                            'startsAt' => $nextAppointment->getStartsAt()->format(DATE_ATOM),
                            'endsAt' => $nextAppointment->getEndsAt()->format(DATE_ATOM),
                            'status' => $nextAppointment->getStatus()->value,
                        ]
                        : null,
                ],
            ],
        ]);
    }
}