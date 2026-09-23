<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\ProfessionalProfile;
use App\Entity\User;
use App\Enum\VerificationStatus;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;
use App\Entity\ProfessionalService;
use App\Entity\Review;
use Doctrine\ORM\Query\Expr\Join;

/** @extends ServiceEntityRepository<ProfessionalProfile> */
final class ProfessionalProfileRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, ProfessionalProfile::class);
    }

    public function findOneByUser(User $user): ?ProfessionalProfile
    {
        return $this->findOneBy(['user' => $user]);
    }

    /**
     * @param array{
     *     category?: mixed,
     *     districtId?: mixed,
     *     minPrice?: mixed,
     *     maxPrice?: mixed,
     *     verified?: mixed,
     *     sort?: mixed,
     *     page?: int,
     *     size?: int
     * } $filters
     *
     * @return array{
     *     items: list<ProfessionalProfile>,
     *     total: int
     * }
     */
    public function searchPublicProfiles(array $filters): array
    {
        $page = max(1, (int) ($filters['page'] ?? 1));
        $size = min(50, max(1, (int) ($filters['size'] ?? 20)));
        $offset = ($page - 1) * $size;

        $qb = $this->createQueryBuilder('p')
            ->andWhere('p.active = :active')
            ->andWhere('p.verificationStatus = :status')
            ->setParameter('active', true)
            ->setParameter('status', VerificationStatus::APPROVED);

        if (!empty($filters['districtId'])) {
            $qb
                ->andWhere('IDENTITY(p.district) = :districtId')
                ->setParameter('districtId', (int) $filters['districtId']);
        }

        $needsServiceJoin =
            !empty($filters['category'])
            || $filters['minPrice'] !== null
            || $filters['maxPrice'] !== null
            || ($filters['sort'] ?? null) === 'price_asc'
            || ($filters['sort'] ?? null) === 'price_desc';

        if ($needsServiceJoin) {
            $qb
                ->innerJoin(
                    ProfessionalService::class,
                    's',
                    Join::WITH,
                    's.professional = p'
                )
                ->andWhere('s.active = true');
        }

        if (!empty($filters['category'])) {
            $qb
                ->innerJoin('s.category', 'c')
                ->andWhere('c.slug = :category')
                ->andWhere('c.active = true')
                ->setParameter('category', trim((string) $filters['category']));
        }

        if ($filters['minPrice'] !== null && $filters['minPrice'] !== '') {
            $qb
                ->andWhere('s.price IS NOT NULL')
                ->andWhere('s.price >= :minPrice')
                ->setParameter('minPrice', (string) $filters['minPrice']);
        }

        if ($filters['maxPrice'] !== null && $filters['maxPrice'] !== '') {
            $qb
                ->andWhere('s.price IS NOT NULL')
                ->andWhere('s.price <= :maxPrice')
                ->setParameter('maxPrice', (string) $filters['maxPrice']);
        }

        $sort = (string) ($filters['sort'] ?? 'name');

        switch ($sort) {
            case 'price_asc':
                $qb
                    ->addSelect('MIN(s.price) AS HIDDEN minPrice')
                    ->groupBy('p.id')
                    ->orderBy('minPrice', 'ASC');
                break;

            case 'price_desc':
                $qb
                    ->addSelect('MAX(s.price) AS HIDDEN maxPrice')
                    ->groupBy('p.id')
                    ->orderBy('maxPrice', 'DESC');
                break;

            case 'rating':
                $qb
                    ->leftJoin(
                        Review::class,
                        'r',
                        Join::WITH,
                        'r.professional = p'
                    )
                    ->addSelect('COALESCE(AVG(r.rating), 0) AS HIDDEN averageRating')
                    ->groupBy('p.id')
                    ->orderBy('averageRating', 'DESC')
                    ->addOrderBy('p.displayName', 'ASC');
                break;

            case 'name':
            default:
                $qb->orderBy('p.displayName', 'ASC');
                break;
        }

        $countQb = clone $qb;

        $total = count($countQb
            ->setFirstResult(null)
            ->setMaxResults(null)
            ->getQuery()
            ->getResult());

        $items = $qb
            ->setFirstResult($offset)
            ->setMaxResults($size)
            ->getQuery()
            ->getResult();

        return [
            'items' => $items,
            'total' => $total,
        ];
    }
}
