<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\RefreshToken;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

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
}
