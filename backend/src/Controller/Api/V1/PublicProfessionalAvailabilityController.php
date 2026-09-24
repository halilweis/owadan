<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\PortfolioItem;
use App\Entity\ProfessionalProfile;
use App\Entity\ProfessionalService;
use App\Enum\VerificationStatus;
use App\Service\AvailabilityService;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Uid\Uuid;

final class PublicProfessionalAvailabilityController extends AbstractController
{
    #[Route('/api/v1/professionals/{id}/portfolio', methods: ['GET'])]
    public function portfolio(
        string $id,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        try {
            $profileId = Uuid::fromString($id);
        } catch (\InvalidArgumentException) {
            return $this->json(['error' => ['code' => 'NOT_FOUND']], 404);
        }

        $profile = $entityManager->find(ProfessionalProfile::class, $profileId);

        if (
            !$profile instanceof ProfessionalProfile
            || !$profile->isActive()
            || $profile->getVerificationStatus() !== VerificationStatus::APPROVED
        ) {
            return $this->json(['error' => ['code' => 'NOT_FOUND']], 404);
        }

        $items = $entityManager->getRepository(PortfolioItem::class)->findBy(
            [
                'professional' => $profile,
                'active' => true,
            ],
            ['featured' => 'DESC'],
        );

        return $this->json([
            'data' => [
                'portfolio' => array_map(
                    static fn (PortfolioItem $item): array => [
                        'id' => (string) $item->getId(),
                        'imageUrl' => $item->getImageUrl(),
                        'title' => $item->getTitle(),
                        'description' => $item->getDescription(),
                        'featured' => $item->isFeatured(),
                    ],
                    $items,
                ),
            ],
        ]);
    }

    #[Route('/api/v1/professionals/{id}/availability', methods: ['GET'])]
    public function availability(
        string $id,
        Request $request,
        EntityManagerInterface $entityManager,
        AvailabilityService $availabilityService,
    ): JsonResponse {
        try {
            $profileId = Uuid::fromString($id);
        } catch (\InvalidArgumentException) {
            return $this->json(['error' => ['code' => 'NOT_FOUND']], 404);
        }

        $profile = $entityManager->find(ProfessionalProfile::class, $profileId);

        if (
            !$profile instanceof ProfessionalProfile
            || !$profile->isActive()
            || $profile->getVerificationStatus() !== VerificationStatus::APPROVED
        ) {
            return $this->json(['error' => ['code' => 'NOT_FOUND']], 404);
        }

        $serviceId = trim((string) $request->query->get('serviceId', ''));
        $date = trim((string) $request->query->get('date', ''));

        if ($serviceId === '' || $date === '') {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'serviceId and date are required.',
                ],
            ], 422);
        }

        try {
            $serviceUuid = Uuid::fromString($serviceId);
        } catch (\InvalidArgumentException) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'serviceId is invalid.',
                ],
            ], 422);
        }

        $service = $entityManager->find(ProfessionalService::class, $serviceUuid);

        if (
            !$service instanceof ProfessionalService
            || !$service->isActive()
            || $service->getProfessional()->getId()->toRfc4122() !== $profile->getId()->toRfc4122()
        ) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'serviceId is invalid.',
                ],
            ], 422);
        }

        $timezone = new \DateTimeZone('Asia/Ashgabat');

        try {
            $day = new \DateTimeImmutable($date . ' 00:00:00', $timezone);
        } catch (\Exception) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'date must use YYYY-MM-DD format.',
                ],
            ], 422);
        }

        if ($day->format('Y-m-d') !== $date) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'date must use YYYY-MM-DD format.',
                ],
            ], 422);
        }

        $slots = $availabilityService->getSlots($profile, $service, $day);

        return $this->json([
            'data' => [
                'professionalId' => $profile->getId()->toRfc4122(),
                'serviceId' => $service->getId()->toRfc4122(),
                'date' => $date,
                'durationMinutes' => $service->getDurationMinutes(),
                'slots' => array_map(
                    static fn (array $slot): array => [
                        'startsAt' => $slot['startsAt']->format(DATE_ATOM),
                        'endsAt' => $slot['endsAt']->format(DATE_ATOM),
                    ],
                    $slots,
                ),
            ],
        ]);
    }
}
