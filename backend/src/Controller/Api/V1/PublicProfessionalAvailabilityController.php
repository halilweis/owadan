<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\AvailabilityException;
use App\Entity\PortfolioItem;
use App\Entity\ProfessionalProfile;
use App\Entity\WorkingHours;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Uid\Uuid;

final class PublicProfessionalAvailabilityController extends AbstractController
{
    #[Route('/api/v1/professionals/{id}/portfolio', methods: ['GET'])]
    public function portfolio(
        string $id,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $profile = $entityManager->find(ProfessionalProfile::class, Uuid::fromString($id));

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'NOT_FOUND']], 404);
        }

        $items = $entityManager->getRepository(PortfolioItem::class)->findBy([
            'professional' => $profile,
            'active' => true,
        ]);

        return $this->json([
            'data' => [
                'portfolio' => array_map(
                    static fn (PortfolioItem $item) => [
                        'id' => (string) $item->getId(),
                        'imageUrl' => $item->getImageUrl(),
                        'title' => $item->getTitle(),
                        'description' => $item->getDescription(),
                        'featured' => $item->isFeatured(),
                    ],
                    $items
                ),
            ],
        ]);
    }

    #[Route('/api/v1/professionals/{id}/availability', methods: ['GET'])]
    public function availability(
        string $id,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $profile = $entityManager->find(ProfessionalProfile::class, Uuid::fromString($id));

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'NOT_FOUND']], 404);
        }

        $workingHours = $entityManager->getRepository(WorkingHours::class)->findBy([
            'professional' => $profile,
            'active' => true,
        ], [
            'dayOfWeek' => 'ASC',
        ]);

        $exceptions = $entityManager->getRepository(AvailabilityException::class)->findBy([
            'professional' => $profile,
        ], [
            'startsAt' => 'ASC',
        ]);

        return $this->json([
            'data' => [
                'workingHours' => array_map(
                    static fn (WorkingHours $hours) => [
                        'dayOfWeek' => $hours->getDayOfWeek(),
                        'startTime' => $hours->getStartTime(),
                        'endTime' => $hours->getEndTime(),
                    ],
                    $workingHours
                ),
                'exceptions' => array_map(
                    static fn (AvailabilityException $exception) => [
                        'id' => (string) $exception->getId(),
                        'startsAt' => $exception->getStartsAt()->format(DATE_ATOM),
                        'endsAt' => $exception->getEndsAt()->format(DATE_ATOM),
                        'type' => $exception->getType(),
                        'note' => $exception->getNote(),
                    ],
                    $exceptions
                ),
            ],
        ]);
    }
}