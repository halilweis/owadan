<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\AdminAuditLog;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

final class AdminAuditController extends AbstractController
{
    #[Route('/api/v1/admin/audit-logs', methods: ['GET'])]
    public function index(
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $logs = $entityManager
            ->getRepository(AdminAuditLog::class)
            ->findBy(
                [],
                ['createdAt' => 'DESC'],
                100,
            );

        return $this->json([
            'data' => [
                'auditLogs' => array_map(
                    static fn (AdminAuditLog $log): array => [
                        'id' => (string) $log->getId(),
                        'adminId' => (string) $log->getAdmin()->getId(),
                        'action' => $log->getAction(),
                        'entityType' => $log->getEntityType(),
                        'entityId' => $log->getEntityId(),
                        'metadata' => $log->getMetadata(),
                        'createdAt' => $log->getCreatedAt()->format(DATE_ATOM),
                    ],
                    $logs,
                ),
            ],
        ]);
    }
}