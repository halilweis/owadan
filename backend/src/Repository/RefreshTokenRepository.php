<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\RefreshToken;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;
use App\Entity\User;

final class RefreshTokenRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, RefreshToken::class);
    }

    public function findUsableByPlainToken(string $plainToken): ?RefreshToken
    {
        $token = $this->findOneBy(['tokenHash' => hash('sha256', $plainToken)]);

        return $token instanceof RefreshToken && $token->isUsable() ? $token : null;
    }

    public function revokeAllForUser(User $user): int
    {
        return $this->createQueryBuilder('r')
            ->update()
            ->set('r.revokedAt', ':now')
            ->where('r.user = :user')
            ->andWhere('r.revokedAt IS NULL')
            ->setParameter('user', $user)
            ->setParameter('now', new \DateTimeImmutable())
            ->getQuery()
            ->execute();
    }
}
