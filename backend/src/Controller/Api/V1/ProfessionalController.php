<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\ProfessionalProfile;
use App\Entity\ProfessionalService;
use App\Enum\VerificationStatus;
use App\Repository\ProfessionalProfileRepository;
use App\Repository\ProfessionalServiceRepository;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

final class ProfessionalController extends AbstractController
{
    #[Route('/api/v1/professionals', methods: ['GET'])]
    public function index(ProfessionalProfileRepository $profiles): JsonResponse
    {
        return $this->json(['data' => array_map(
            fn (ProfessionalProfile $profile) => $this->profilePayload($profile),
            $profiles->findPublicProfiles(),
        )]);
    }

    #[Route('/api/v1/professionals/{id}', methods: ['GET'])]
    public function show(string $id, ProfessionalProfileRepository $profiles): JsonResponse
    {
        $profile = $profiles->find($id);
        if (!$profile instanceof ProfessionalProfile || !$profile->isActive() || $profile->getVerificationStatus() !== VerificationStatus::APPROVED) {
            return $this->json(['error' => ['code' => 'PROFESSIONAL_NOT_FOUND', 'message' => 'Professional not found.']], 404);
        }

        return $this->json(['data' => $this->profilePayload($profile)]);
    }

    #[Route('/api/v1/professionals/{id}/services', methods: ['GET'])]
    public function services(
        string $id,
        ProfessionalProfileRepository $profiles,
        ProfessionalServiceRepository $services,
    ): JsonResponse {
        $profile = $profiles->find($id);
        if (!$profile instanceof ProfessionalProfile || !$profile->isActive() || $profile->getVerificationStatus() !== VerificationStatus::APPROVED) {
            return $this->json(['error' => ['code' => 'PROFESSIONAL_NOT_FOUND', 'message' => 'Professional not found.']], 404);
        }

        return $this->json(['data' => array_map(
            fn (ProfessionalService $service) => $this->servicePayload($service),
            $services->findActiveForProfessional($profile),
        )]);
    }

    private function profilePayload(ProfessionalProfile $profile): array
    {
        return [
            'id' => $profile->getId()->toRfc4122(),
            'displayName' => $profile->getDisplayName(),
            'bio' => $profile->getBio(),
            'experienceYears' => $profile->getExperienceYears(),
            'languages' => $profile->getLanguages(),
            'verificationStatus' => $profile->getVerificationStatus()->value,
        ];
    }

    private function servicePayload(ProfessionalService $service): array
    {
        return [
            'id' => $service->getId()->toRfc4122(),
            'categoryId' => $service->getCategory()->getId(),
            'name' => $service->getName(),
            'description' => $service->getDescription(),
            'durationMinutes' => $service->getDurationMinutes(),
            'priceType' => $service->getPriceType()->value,
            'price' => $service->getPrice(),
            'currency' => $service->getCurrency(),
        ];
    }
}
