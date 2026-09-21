<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\OtpChallenge;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

final class OtpChallengeRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, OtpChallenge::class);
    }

    public function findLatestUsable(string $phoneNumber): ?OtpChallenge
    {
        return $this->createQueryBuilder('o')
            ->andWhere('o.phoneNumber = :phone')
            ->andWhere('o.consumedAt IS NULL')
            ->andWhere('o.expiresAt > :now')
            ->setParameter('phone', $phoneNumber)
            ->setParameter('now', new \DateTimeImmutable())
            ->orderBy('o.createdAt', 'DESC')
            ->setMaxResults(1)
            ->getQuery()
            ->getOneOrNullResult();
    }
}
