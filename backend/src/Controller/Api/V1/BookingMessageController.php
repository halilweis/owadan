<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\Booking;
use App\Entity\BookingMessage;
use App\Entity\ProfessionalProfile;
use App\Entity\User;
use App\Repository\ProfessionalProfileRepository;
use App\Service\NotificationService;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

final class BookingMessageController extends AbstractController
{
    #[Route('/api/v1/bookings/{id}/messages', methods: ['GET'])]
    public function customerMessages(
        Booking $booking,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        if ($booking->getCustomer()->getId() !== $user->getId()) {
            return $this->json(['error' => ['code' => 'FORBIDDEN']], 403);
        }

        return $this->messagesResponse($booking, $entityManager);
    }

    #[Route('/api/v1/bookings/{id}/messages', methods: ['POST'])]
    public function customerSend(
        Booking $booking,
        Request $request,
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

        $message = $this->createMessage(
            $booking,
            $user,
            $request,
            $entityManager,
        );

        if ($message instanceof JsonResponse) {
            return $message;
        }

        $notifications->create(
            $booking->getProfessional()->getUser(),
            'BOOKING_MESSAGE',
            'New appointment message',
            sprintf(
                'New message about %s.',
                $booking->getServiceName(),
            ),
            [
                'bookingId' => (string) $booking->getId(),
                 'conversationRole' => 'PROFESSIONAL',
            ],
        );

        $entityManager->flush();

        return $this->json([
            'data' => [
                'message' => $this->messagePayload($message, $booking),
            ],
        ], 201);
    }

    #[Route('/api/v1/pro/bookings/{id}/messages', methods: ['GET'])]
    public function professionalMessages(
        Booking $booking,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $profile = $this->requireProfessional($profiles);

        if ($profile instanceof JsonResponse) {
            return $profile;
        }

        if ($booking->getProfessional()->getId() !== $profile->getId()) {
            return $this->json(['error' => ['code' => 'FORBIDDEN']], 403);
        }

        return $this->messagesResponse($booking, $entityManager);
    }

    #[Route('/api/v1/pro/bookings/{id}/messages', methods: ['POST'])]
    public function professionalSend(
        Booking $booking,
        Request $request,
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

        $message = $this->createMessage(
            $booking,
            $profile->getUser(),
            $request,
            $entityManager,
        );

        if ($message instanceof JsonResponse) {
            return $message;
        }

        $notifications->create(
            $booking->getCustomer(),
            'BOOKING_MESSAGE',
            'New appointment message',
            sprintf(
                'Your professional sent a message about %s.',
                $booking->getServiceName(),
            ),
            [
                'bookingId' => (string) $booking->getId(),
                 'conversationRole' => 'CUSTOMER',
            ],
        );

        $entityManager->flush();

        return $this->json([
            'data' => [
                'message' => $this->messagePayload($message, $booking),
            ],
        ], 201);
    }

    private function messagesResponse(
        Booking $booking,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $messages = $entityManager
            ->getRepository(BookingMessage::class)
            ->findBy(
                ['booking' => $booking],
                ['createdAt' => 'ASC'],
            );

        return $this->json([
            'data' => [
                'messages' => array_map(
                    fn (BookingMessage $message): array =>
                        $this->messagePayload($message, $booking),
                    $messages,
                ),
            ],
        ]);
    }

    private function createMessage(
        Booking $booking,
        User $sender,
        Request $request,
        EntityManagerInterface $entityManager,
    ): BookingMessage|JsonResponse {
        $payload = $request->toArray();
        $body = trim((string) ($payload['body'] ?? ''));

        if ($body === '' || mb_strlen($body) > 1000) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'body must contain 1 to 1000 characters.',
                ],
            ], 422);
        }

        $message = new BookingMessage($booking, $sender, $body);
        $entityManager->persist($message);

        return $message;
    }

    private function messagePayload(
        BookingMessage $message,
        Booking $booking,
    ): array {
        return [
            'id' => (string) $message->getId(),
            'bookingId' => (string) $booking->getId(),
            'senderRole' =>
                $message->getSender()->getId() ===
                $booking->getCustomer()->getId()
                    ? 'CUSTOMER'
                    : 'PROFESSIONAL',
            'body' => $message->getBody(),
            'createdAt' => $message->getCreatedAt()->format(DATE_ATOM),
        ];
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
}