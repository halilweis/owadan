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
use Symfony\Component\HttpFoundation\Request;
use App\Service\ProfessionalSummaryService;

final class ProfessionalController extends AbstractController
{
    #[Route('/api/v1/professionals', methods: ['GET'])]
    public function index(
        Request $request,
        ProfessionalProfileRepository $profiles,
        ProfessionalSummaryService $summaryService,
    ): JsonResponse {
        $page = max(1, $request->query->getInt('page', 1));
        $size = min(50, max(1, $request->query->getInt('size', 20)));

        $filters = [
            'category' => $request->query->get('category'),
            'districtId' => $request->query->get('districtId'),
            'minPrice' => $request->query->get('minPrice'),
            'maxPrice' => $request->query->get('maxPrice'),
            'verified' => $request->query->get('verified'),
            'sort' => $request->query->get('sort', 'name'),
            'page' => $page,
            'size' => $size,
        ];

        $result = $profiles->searchPublicProfiles($filters);

        return $this->json([
            'data' => array_map(
                fn (ProfessionalProfile $profile) => [
                    ...$this->profilePayload($profile),
                    ...$summaryService->getSummary($profile),
                ],
                $result['items'],
            ),
            'meta' => [
                'page' => $page,
                'size' => $size,
                'total' => $result['total'],
                'pages' => (int) ceil($result['total'] / $size),
            ],
        ]);
    }

    #[Route('/api/v1/professionals/{id}', methods: ['GET'])]
    public function show(string $id, ProfessionalProfileRepository $profiles, ProfessionalSummaryService $summaryService): JsonResponse
    {
        $profile = $profiles->find($id);
        if (!$profile instanceof ProfessionalProfile || !$profile->isActive() || $profile->getVerificationStatus() !== VerificationStatus::APPROVED) {
            return $this->json(['error' => ['code' => 'PROFESSIONAL_NOT_FOUND', 'message' => 'Professional not found.']], 404);
        }

        return $this->json([
            'data' => [
                ...$this->profilePayload($profile),
                ...$summaryService->getSummary($profile),
            ],
        ]);
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
