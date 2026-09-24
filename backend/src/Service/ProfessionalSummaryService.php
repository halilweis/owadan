<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\ProfessionalProfile;
use App\Entity\ProfessionalService;
use App\Entity\Review;
use Doctrine\ORM\EntityManagerInterface;

final class ProfessionalSummaryService
{
    public function __construct(
        private readonly EntityManagerInterface $entityManager,
        private readonly AvailabilityService $availabilityService,
    ) {
    }

    public function getSummary(ProfessionalProfile $profile): array
    {
        $reviewStats = $this->entityManager->createQueryBuilder()
            ->select('COUNT(r.id) AS reviewCount')
            ->addSelect('AVG(r.rating) AS averageRating')
            ->from(Review::class, 'r')
            ->where('r.professional = :professional')
            ->setParameter('professional', $profile)
            ->getQuery()
            ->getOneOrNullResult();

        $priceStats = $this->entityManager->createQueryBuilder()
            ->select('MIN(s.price) AS minPrice')
            ->from(ProfessionalService::class, 's')
            ->where('s.professional = :professional')
            ->andWhere('s.active = true')
            ->andWhere('s.price IS NOT NULL')
            ->setParameter('professional', $profile)
            ->getQuery()
            ->getOneOrNullResult();

        $nextAvailableAt = $this->availabilityService->findNextAvailableAt($profile);

        return [
            'averageRating' => $reviewStats !== null && $reviewStats['averageRating'] !== null
                ? round((float) $reviewStats['averageRating'], 2)
                : null,
            'reviewCount' => (int) ($reviewStats['reviewCount'] ?? 0),
            'minPrice' => $priceStats['minPrice'] ?? null,
            'currency' => 'TMT',
            'nextAvailableAt' => $nextAvailableAt?->format(DATE_ATOM),
        ];
    }
}
