<?php

declare(strict_types=1);

namespace App\Service\Auth;

use App\Entity\RefreshToken;
use App\Entity\User;
use App\Repository\RefreshTokenRepository;
use Doctrine\ORM\EntityManagerInterface;
use Lexik\Bundle\JWTAuthenticationBundle\Services\JWTTokenManagerInterface;
use Symfony\Component\DependencyInjection\Attribute\Autowire;

final class TokenIssuer
{
    public function __construct(
        private readonly JWTTokenManagerInterface $jwtManager,
        private readonly RefreshTokenRepository $refreshTokens,
        private readonly EntityManagerInterface $entityManager,
        #[Autowire('%env(int:JWT_ACCESS_TTL)%')] private readonly int $accessTtl,
        #[Autowire('%env(int:JWT_REFRESH_TTL)%')] private readonly int $refreshTtl,
    ) {
    }

    /** @return array{accessToken:string,refreshToken:string,tokenType:string,expiresIn:int} */
    public function issue(User $user): array
    {
        $plainRefreshToken = rtrim(strtr(base64_encode(random_bytes(48)), '+/', '-_'), '=');
        $refreshToken = new RefreshToken(
            $user,
            hash('sha256', $plainRefreshToken),
            new \DateTimeImmutable(sprintf('+%d seconds', $this->refreshTtl)),
        );

        $this->entityManager->persist($refreshToken);
        $this->entityManager->flush();

        return [
            'accessToken' => $this->jwtManager->create($user),
            'refreshToken' => $plainRefreshToken,
            'tokenType' => 'Bearer',
            'expiresIn' => $this->accessTtl,
        ];
    }

    /** @return array{accessToken:string,refreshToken:string,tokenType:string,expiresIn:int}|null */
    public function rotate(string $plainRefreshToken): ?array
    {
        $existing = $this->refreshTokens->findUsableByPlainToken($plainRefreshToken);
        if (!$existing instanceof RefreshToken || !$existing->getUser()->isActive()) {
            return null;
        }

        $user = $existing->getUser();
        $existing->revoke();
        $this->entityManager->flush();

        return $this->issue($user);
    }

    public function revoke(string $plainRefreshToken): bool
    {
        $existing = $this->refreshTokens->findUsableByPlainToken($plainRefreshToken);
        if (!$existing instanceof RefreshToken) {
            return false;
        }

        $existing->revoke();
        $this->entityManager->flush();

        return true;
    }

    public function revokeAll(User $user): int
    {
        return $this->refreshTokens->revokeAllForUser($user);
    }
}
