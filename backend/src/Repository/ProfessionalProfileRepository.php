<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\ProfessionalProfile;
use App\Entity\User;
use App\Enum\VerificationStatus;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

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

    /** @return list<ProfessionalProfile> */
    public function findPublicProfiles(int $limit = 50): array
    {
        return $this->createQueryBuilder('p')
            ->andWhere('p.active = :active')
            ->andWhere('p.verificationStatus = :status')
            ->setParameter('active', true)
            ->setParameter('status', VerificationStatus::APPROVED)
            ->orderBy('p.displayName', 'ASC')
            ->setMaxResults($limit)
            ->getQuery()
            ->getResult();
    }
}
