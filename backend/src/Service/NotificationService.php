<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\Notification;
use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;

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
    ): Notification {
        $notification = new Notification(
            $user,
            $type,
            $title,
            $message,
            $data,
        );

        $this->entityManager->persist($notification);

        return $notification;
    }
}