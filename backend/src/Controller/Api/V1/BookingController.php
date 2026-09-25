<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\AvailabilityException;
use App\Entity\Booking;
use App\Entity\ProfessionalService;
use App\Entity\ProfessionalProfile;
use App\Entity\User;
use App\Entity\WorkingHours;
use App\Enum\BookingStatus;
use App\Repository\ProfessionalProfileRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;
use Doctrine\DBAL\Exception\DriverException;
use App\Service\NotificationService;
use OpenApi\Attributes as OA;

final class BookingController extends AbstractController
{
    #[OA\Post(
        path: '/api/v1/bookings',
        summary: 'Create a booking',
        tags: ['Bookings'],
        security: [['Bearer' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['serviceId', 'startsAt'],
                properties: [
                    new OA\Property(
                        property: 'serviceId',
                        type: 'string',
                        format: 'uuid'
                    ),
                    new OA\Property(
                        property: 'startsAt',
                        type: 'string',
                        format: 'date-time',
                        example: '2026-10-03T11:00:00+05:00'
                    ),
                    new OA\Property(
                        property: 'note',
                        type: 'string',
                        nullable: true,
                        example: 'First visit'
                    ),
                ],
            ),
        ),
        responses: [
            new OA\Response(response: 201, description: 'Booking created'),
            new OA\Response(response: 401, description: 'Authentication required'),
            new OA\Response(response: 409, description: 'Requested time unavailable'),
            new OA\Response(response: 422, description: 'Invalid booking data'),
        ],
    )]

    #[Route('/api/v1/bookings', methods: ['POST'])]
    public function create(
        Request $request,
        EntityManagerInterface $entityManager,
        NotificationService $notifications,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $payload = $request->toArray();

        $service = $entityManager->find(
            ProfessionalService::class,
            (string) ($payload['serviceId'] ?? '')
        );

        if (!$service instanceof ProfessionalService || !$service->isActive()) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'serviceId is invalid.',
                ],
            ], 422);
        }

        $professional = $service->getProfessional();

        if (!$professional->isActive()) {
            return $this->json([
                'error' => [
                    'code' => 'PROFESSIONAL_UNAVAILABLE',
                    'message' => 'Professional is not active.',
                ],
            ], 409);
        }

        try {
            $startsAt = new \DateTimeImmutable((string) ($payload['startsAt'] ?? ''));
        } catch (\Exception) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'startsAt is invalid.',
                ],
            ], 422);
        }

        if ($startsAt <= new \DateTimeImmutable()) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'startsAt must be in the future.',
                ],
            ], 422);
        }

        $endsAt = $startsAt->modify(
            sprintf('+%d minutes', $service->getDurationMinutes())
        );

        if (!$this->isInsideAvailableWindow($professional, $startsAt, $endsAt, $entityManager)) {
            return $this->json([
                'error' => [
                    'code' => 'OUTSIDE_WORKING_HOURS',
                    'message' => 'Requested time is outside working hours.',
                ],
            ], 409);
        }

        if ($this->hasBlockedException($professional->getId()->toRfc4122(), $startsAt, $endsAt, $entityManager)) {
            return $this->json([
                'error' => [
                    'code' => 'TIME_BLOCKED',
                    'message' => 'Requested time is blocked.',
                ],
            ], 409);
        }

        if ($this->hasBookingOverlap($professional->getId()->toRfc4122(), $startsAt, $endsAt, $entityManager)) {
            return $this->json([
                'error' => [
                    'code' => 'TIME_NOT_AVAILABLE',
                    'message' => 'Requested time overlaps an existing booking.',
                ],
            ], 409);
        }

        $booking = new Booking(
            $user,
            $professional,
            $service,
            $startsAt,
            $endsAt,
            $service->getName(),
            $service->getPriceType()->value,
            $service->getPrice(),
            $service->getCurrency(),
            isset($payload['note']) ? (string) $payload['note'] : null,
        );

    $entityManager->persist($booking);
        $notifications->create(
        $professional->getUser(),
        'NEW_BOOKING',
        'New booking request',
        sprintf('%s requested %s.', $user->getPhoneNumber(), $service->getName()),
        [
            'bookingId' => (string) $booking->getId(),
            'serviceName' => $service->getName(),
            'startsAt' => $startsAt->format(DATE_ATOM),
        ],
    );

    try {
        $entityManager->flush();
    } catch (DriverException $exception) {
        if ($exception->getSQLState() === '23P01') {
            return $this->json([
                'error' => [
                    'code' => 'TIME_NOT_AVAILABLE',
                    'message' => 'Requested time is no longer available.',
                ],
            ], 409);
        }

        throw $exception;
    }

        return $this->json([
            'data' => [
                'booking' => $this->bookingPayload($booking),
            ],
        ], 201);
    }

    #[Route('/api/v1/me/bookings', methods: ['GET'])]
    public function mine(EntityManagerInterface $entityManager): JsonResponse
    {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $bookings = $entityManager->getRepository(Booking::class)->findBy(
            ['customer' => $user],
            ['startsAt' => 'DESC'],
        );

        return $this->json([
            'data' => [
                'bookings' => array_map(
                    fn (Booking $booking) => $this->bookingPayload($booking),
                    $bookings,
                ),
            ],
        ]);
    }

    #[Route('/api/v1/bookings/{id}/cancel', methods: ['POST'])]
    public function cancel(
        Booking $booking,
        EntityManagerInterface $entityManager,
        NotificationService $notifications,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        if ($booking->getCustomer()->getId() !== $user->getId()) {
            return $this->json(['error' => ['code' => 'FORBIDDEN']], 403);
        }

        if (!in_array($booking->getStatus(), [
            BookingStatus::PENDING,
            BookingStatus::CONFIRMED,
        ], true)) {
            return $this->json([
                'error' => [
                    'code' => 'INVALID_BOOKING_STATE',
                    'message' => 'Booking cannot be cancelled in its current state.',
                ],
            ], 409);
        }

        $booking->cancelByCustomer();

        $notifications->create(
            $booking->getProfessional()->getUser(),
            'BOOKING_CANCELLED',
            'Booking cancelled',
            sprintf('A customer cancelled the booking for %s.', $booking->getServiceName()),
            [
                'bookingId' => (string) $booking->getId(),
            ],
        );
        
        $entityManager->flush();

        return $this->json([
            'data' => [
                'booking' => $this->bookingPayload($booking),
            ],
        ]);
    }

    private function isInsideAvailableWindow(
        ProfessionalProfile $professional,
        \DateTimeImmutable $startsAt,
        \DateTimeImmutable $endsAt,
        EntityManagerInterface $entityManager,
    ): bool {
        $dayOfWeek = (int) $startsAt->format('N');
        $startTime = $startsAt->format('H:i');
        $endTime = $endsAt->format('H:i');

        $workingHoursCount = $entityManager->createQueryBuilder()
            ->select('COUNT(w.id)')
            ->from(WorkingHours::class, 'w')
            ->where('w.professional = :professional')
            ->andWhere('w.dayOfWeek = :day')
            ->andWhere('w.active = true')
            ->andWhere('w.startTime <= :startTime')
            ->andWhere('w.endTime >= :endTime')
            ->setParameter('professional', $professional)
            ->setParameter('day', $dayOfWeek)
            ->setParameter('startTime', $startTime)
            ->setParameter('endTime', $endTime)
            ->getQuery()
            ->getSingleScalarResult();

        if ((int) $workingHoursCount > 0) {
            return true;
        }

        $extraCount = $entityManager->createQueryBuilder()
            ->select('COUNT(a.id)')
            ->from(AvailabilityException::class, 'a')
            ->where('a.professional = :professional')
            ->andWhere('a.type = :type')
            ->andWhere('a.startsAt <= :startsAt')
            ->andWhere('a.endsAt >= :endsAt')
            ->setParameter('professional', $professional)
            ->setParameter('type', 'EXTRA')
            ->setParameter('startsAt', $startsAt)
            ->setParameter('endsAt', $endsAt)
            ->getQuery()
            ->getSingleScalarResult();

        return (int) $extraCount > 0;
    }

    private function hasBlockedException(
        string $professionalId,
        \DateTimeImmutable $startsAt,
        \DateTimeImmutable $endsAt,
        EntityManagerInterface $entityManager,
    ): bool {
        $count = $entityManager->createQueryBuilder()
            ->select('COUNT(a.id)')
            ->from(AvailabilityException::class, 'a')
            ->join('a.professional', 'p')
            ->where('p.id = :professionalId')
            ->andWhere('a.type = :type')
            ->andWhere('a.startsAt < :endsAt')
            ->andWhere('a.endsAt > :startsAt')
            ->setParameter('professionalId', $professionalId)
            ->setParameter('type', 'BLOCKED')
            ->setParameter('startsAt', $startsAt)
            ->setParameter('endsAt', $endsAt)
            ->getQuery()
            ->getSingleScalarResult();

        return (int) $count > 0;
    }

    private function hasBookingOverlap(
        string $professionalId,
        \DateTimeImmutable $startsAt,
        \DateTimeImmutable $endsAt,
        EntityManagerInterface $entityManager,
    ): bool {
        $count = $entityManager->createQueryBuilder()
            ->select('COUNT(b.id)')
            ->from(Booking::class, 'b')
            ->join('b.professional', 'p')
            ->where('p.id = :professionalId')
            ->andWhere('b.status IN (:statuses)')
            ->andWhere('b.startsAt < :endsAt')
            ->andWhere('b.endsAt > :startsAt')
            ->setParameter('professionalId', $professionalId)
            ->setParameter('statuses', [
                BookingStatus::PENDING,
                BookingStatus::CONFIRMED,
            ])
            ->setParameter('startsAt', $startsAt)
            ->setParameter('endsAt', $endsAt)
            ->getQuery()
            ->getSingleScalarResult();

        return (int) $count > 0;
    }

    private function bookingPayload(Booking $booking): array
    {
        return [
            'id' => (string) $booking->getId(),
            'professionalId' => (string) $booking->getProfessional()->getId(),
            'serviceId' => (string) $booking->getService()->getId(),
            'serviceName' => $booking->getServiceName(),
            'startsAt' => $booking->getStartsAt()->format(DATE_ATOM),
            'endsAt' => $booking->getEndsAt()->format(DATE_ATOM),
            'status' => $booking->getStatus()->value,
            'priceType' => $booking->getPriceType(),
            'price' => $booking->getPrice(),
            'currency' => $booking->getCurrency(),
            'note' => $booking->getNote(),
        ];
    }
}