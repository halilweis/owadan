<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\Notification;
use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\Uid\Uuid;

final class NotificationService
{
    public function __construct(
        private readonly EntityManagerInterface $entityManager,
    ) {
    }

    public function create(
        User $user,
        string $type,
        string $title,
        ?string $message = null,
        array $data = [],
        ?Uuid $bookingId = null,
    ): Notification {
        $notification = new Notification(
            $user,
            $type,
            $title,
            $message,
            $data,
            $bookingId,
        );

        $this->entityManager->persist($notification);

        return $notification;
    }
}