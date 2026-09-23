<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\Booking;
use App\Entity\ProfessionalProfile;
use App\Entity\User;
use App\Enum\BookingStatus;
use App\Repository\ProfessionalProfileRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;
use App\Service\NotificationService;

final class ProfessionalBookingController extends AbstractController
{
    #[Route('/api/v1/pro/bookings', methods: ['GET'])]
    public function list(
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $profile = $profiles->findOneByUser($user);

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'PROFILE_REQUIRED']], 409);
        }

        $bookings = $entityManager->getRepository(Booking::class)->findBy(
            ['professional' => $profile],
            ['startsAt' => 'ASC'],
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

    #[Route('/api/v1/pro/bookings/{id}/confirm', methods: ['POST'])]
    public function confirm(
        Booking $booking,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
        NotificationService $notifications,
    ): JsonResponse {
        $profile = $this->requireProfessional($profiles);

        if ($profile instanceof JsonResponse) {
            return $profile;
        }

        if ($booking->getProfessional()->getId() !== $profile->getId()) {
            return $this->json(['error' => ['code' => 'FORBIDDEN']], 403);
        }

        if ($booking->getStatus() !== BookingStatus::PENDING) {
            return $this->invalidState();
        }

        $booking->confirm();

        $notifications->create(
            $booking->getCustomer(),
            'BOOKING_CONFIRMED',
            'Booking confirmed',
            sprintf('Your booking for %s has been confirmed.', $booking->getServiceName()),
            [
                'bookingId' => (string) $booking->getId(),
                'startsAt' => $booking->getStartsAt()->format(DATE_ATOM),
            ],
        );
        $entityManager->flush();

        return $this->json([
            'data' => [
                'booking' => $this->bookingPayload($booking),
            ],
        ]);
    }

    #[Route('/api/v1/pro/bookings/{id}/decline', methods: ['POST'])]
    public function decline(
        Booking $booking,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
        NotificationService $notifications,
    ): JsonResponse {
        $profile = $this->requireProfessional($profiles);

        if ($profile instanceof JsonResponse) {
            return $profile;
        }

        if ($booking->getProfessional()->getId() !== $profile->getId()) {
            return $this->json(['error' => ['code' => 'FORBIDDEN']], 403);
        }

        if ($booking->getStatus() !== BookingStatus::PENDING) {
            return $this->invalidState();
        }

        $booking->decline();

        $notifications->create(
            $booking->getCustomer(),
            'BOOKING_DECLINED',
            'Booking declined',
            sprintf('Your booking for %s was declined.', $booking->getServiceName()),
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

    #[Route('/api/v1/pro/bookings/{id}/cancel', methods: ['POST'])]
    public function cancel(
        Booking $booking,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
        NotificationService $notifications,
    ): JsonResponse {
        $profile = $this->requireProfessional($profiles);

        if ($profile instanceof JsonResponse) {
            return $profile;
        }

        if ($booking->getProfessional()->getId() !== $profile->getId()) {
            return $this->json(['error' => ['code' => 'FORBIDDEN']], 403);
        }

        if (!in_array($booking->getStatus(), [
            BookingStatus::PENDING,
            BookingStatus::CONFIRMED,
        ], true)) {
            return $this->invalidState();
        }

        $booking->cancelByProfessional();

        $notifications->create(
            $booking->getCustomer(),
                'BOOKING_CANCELLED',
                'Booking cancelled',
                sprintf('Your booking for %s was cancelled by the professional.', $booking->getServiceName()),
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

    #[Route('/api/v1/pro/bookings/{id}/complete', methods: ['POST'])]
    public function complete(
        Booking $booking,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
        NotificationService $notifications,
    ): JsonResponse {
        $profile = $this->requireProfessional($profiles);

        if ($profile instanceof JsonResponse) {
            return $profile;
        }

        if ($booking->getProfessional()->getId() !== $profile->getId()) {
            return $this->json(['error' => ['code' => 'FORBIDDEN']], 403);
        }

        if ($booking->getStatus() !== BookingStatus::CONFIRMED) {
            return $this->invalidState();
        }

        $booking->complete();

        $notifications->create(
            $booking->getCustomer(),
            'BOOKING_COMPLETED',
            'Booking completed',
            sprintf('Your appointment for %s is complete. You can now leave a review.', $booking->getServiceName()),
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

    #[Route('/api/v1/pro/bookings/{id}/no-show', methods: ['POST'])]
    public function noShow(
        Booking $booking,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
        NotificationService $notifications,
    ): JsonResponse {
        $profile = $this->requireProfessional($profiles);

        if ($profile instanceof JsonResponse) {
            return $profile;
        }

        if ($booking->getProfessional()->getId() !== $profile->getId()) {
            return $this->json(['error' => ['code' => 'FORBIDDEN']], 403);
        }

        if ($booking->getStatus() !== BookingStatus::CONFIRMED) {
            return $this->invalidState();
        }

        $booking->markNoShow();

        $notifications->create(
            $booking->getCustomer(),
            'BOOKING_NO_SHOW',
            'Booking marked as no-show',
            sprintf('Your booking for %s was marked as no-show.', $booking->getServiceName()),
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

    private function requireProfessional(
        ProfessionalProfileRepository $profiles,
    ): ProfessionalProfile|JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $profile = $profiles->findOneByUser($user);

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'PROFILE_REQUIRED']], 409);
        }

        return $profile;
    }

    private function invalidState(): JsonResponse
    {
        return $this->json([
            'error' => [
                'code' => 'INVALID_BOOKING_STATE',
                'message' => 'Booking cannot be changed in its current state.',
            ],
        ], 409);
    }

    private function bookingPayload(Booking $booking): array
    {
        return [
            'id' => (string) $booking->getId(),
            'customerId' => (string) $booking->getCustomer()->getId(),
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