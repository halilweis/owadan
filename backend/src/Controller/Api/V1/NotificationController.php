<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\Notification;
use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

final class NotificationController extends AbstractController
{
    #[Route('/api/v1/me/notifications', methods: ['GET'])]
    public function list(EntityManagerInterface $entityManager): JsonResponse
    {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $notifications = $entityManager->getRepository(Notification::class)->findBy(
            ['user' => $user],
            ['createdAt' => 'DESC'],
        );

        return $this->json([
            'data' => [
                'notifications' => array_map(
                    static fn (Notification $notification) => [
                        'id' => (string) $notification->getId(),
                        'type' => $notification->getType(),
                        'title' => $notification->getTitle(),
                        'message' => $notification->getMessage(),
                        'data' => $notification->getData(),
                        'read' => $notification->isRead(),
                        'createdAt' => $notification->getCreatedAt()->format(DATE_ATOM),
                    ],
                    $notifications,
                ),
            ],
        ]);
    }

    #[Route('/api/v1/me/notifications/{id}/read', methods: ['POST'])]
    public function markRead(
        Notification $notification,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        if ($notification->getUser()->getId() !== $user->getId()) {
            return $this->json(['error' => ['code' => 'FORBIDDEN']], 403);
        }

        $notification->markRead();
        $entityManager->flush();

        return $this->json([
            'data' => [
                'read' => true,
            ],
        ]);
    }

    #[Route('/api/v1/me/notifications/unread-count', methods: ['GET'])]
public function unreadCount(EntityManagerInterface $entityManager): JsonResponse
{
    $user = $this->getUser();

    if (!$user instanceof User) {
        return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
    }

    $count = $entityManager->getRepository(Notification::class)->count([
        'user' => $user,
        'read' => false,
    ]);

    return $this->json([
        'data' => [
            'unreadCount' => $count,
        ],
    ]);
}

    #[Route('/api/v1/me/notifications/read-all', methods: ['POST'])]
    public function markAllRead(EntityManagerInterface $entityManager): JsonResponse
    {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $notifications = $entityManager->getRepository(Notification::class)->findBy([
            'user' => $user,
            'read' => false,
        ]);

        foreach ($notifications as $notification) {
            $notification->markRead();
        }

        $entityManager->flush();

        return $this->json([
            'data' => [
                'updated' => count($notifications),
            ],
        ]);
    }
}