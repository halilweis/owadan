<?php

namespace App\Controller\Api\V1;

use App\Entity\ProfessionalProfile;
use App\Enum\VerificationStatus;
use App\Repository\ProfessionalProfileRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;
use App\Entity\User;
use App\Service\AdminAuditService;

#[Route('/api/v1/admin/professionals')]
final class AdminProfessionalController extends AbstractController
{
    #[Route('/pending', methods: ['GET'])]
    public function pending(ProfessionalProfileRepository $profiles): JsonResponse
    {
        $items = $profiles->findBy([
            'verificationStatus' => VerificationStatus::PENDING,
        ]);

        return $this->json([
            'data' => [
                'professionals' => array_map(
                    static fn (ProfessionalProfile $profile) => [
                        'id' => $profile->getId(),
                        'displayName' => $profile->getDisplayName(),
                        'verificationStatus' => $profile->getVerificationStatus()->value,
                        'active' => $profile->isActive(),
                    ],
                    $items
                ),
            ],
        ]);
    }

    #[Route('/{id}/approve', methods: ['POST'])]
    public function approve(
        ProfessionalProfile $profile,
        EntityManagerInterface $entityManager,
        AdminAuditService $audit,
    ): JsonResponse {
        $profile->approve();

        $admin = $this->getUser();

        if ($admin instanceof User) {
            $audit->log(
                $admin,
                'PROFESSIONAL_APPROVED',
                'ProfessionalProfile',
                (string) $profile->getId(),
                [
                    'displayName' => $profile->getDisplayName(),
                ],
            );
        }

        $entityManager->flush();

        return $this->json([
            'data' => [
                'profile' => [
                    'id' => $profile->getId(),
                    'verificationStatus' => $profile->getVerificationStatus()->value,
                ],
            ],
        ]);
    }

    #[Route('/{id}/reject', methods: ['POST'])]
    public function reject(
        ProfessionalProfile $profile,
        EntityManagerInterface $entityManager,
        AdminAuditService $audit,
    ): JsonResponse {
        $profile->reject();

        $admin = $this->getUser();

        if ($admin instanceof User) {
            $audit->log(
                $admin,
                'PROFESSIONAL_REJECTED',
                'ProfessionalProfile',
                (string) $profile->getId(),
                [
                    'displayName' => $profile->getDisplayName(),
                ],
            );
        }
        $entityManager->flush();

        return $this->json([
            'data' => [
                'profile' => [
                    'id' => $profile->getId(),
                    'verificationStatus' => $profile->getVerificationStatus()->value,
                ],
            ],
        ]);
    }
}