<?php

namespace App\Controller\Api\V1;

use App\Entity\ProfessionalProfile;
use App\Enum\VerificationStatus;
use App\Repository\ProfessionalProfileRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

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
    ): JsonResponse {
        $profile->approve();

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
    ): JsonResponse {
        $profile->reject();

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