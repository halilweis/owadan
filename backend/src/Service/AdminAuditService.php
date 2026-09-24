<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\AdminAuditLog;
use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;

final class AdminAuditService
{
    public function __construct(
        private readonly EntityManagerInterface $entityManager,
    ) {
    }

    public function log(
        User $admin,
        string $action,
        string $entityType,
        string $entityId,
        array $metadata = [],
    ): AdminAuditLog {
        $log = new AdminAuditLog(
            $admin,
            $action,
            $entityType,
            $entityId,
            $metadata,
        );

        $this->entityManager->persist($log);

        return $log;
    }
}