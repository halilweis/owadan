<?php

declare(strict_types=1);

namespace App\Service\Auth;

use App\Entity\OtpChallenge;
use App\Repository\OtpChallengeRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\DependencyInjection\Attribute\Autowire;

final class OtpManager
{
    private const DEVELOPMENT_CODE = '123456';
    private const MAX_ATTEMPTS = 5;

    public function __construct(
        private readonly OtpChallengeRepository $challenges,
        private readonly EntityManagerInterface $entityManager,
        #[Autowire('%env(APP_SECRET)%')] private readonly string $appSecret,
        #[Autowire('%env(int:OTP_TTL_SECONDS)%')] private readonly int $ttlSeconds,
    ) {
    }

    public function request(string $phoneNumber): string
    {
        $code = self::DEVELOPMENT_CODE;
        $expiresAt = new \DateTimeImmutable(sprintf('+%d seconds', $this->ttlSeconds));
        $challenge = new OtpChallenge($phoneNumber, $this->hashCode($phoneNumber, $code), $expiresAt);

        $this->entityManager->persist($challenge);
        $this->entityManager->flush();

        return $code;
    }

    public function verify(string $phoneNumber, string $code): bool
    {
        $challenge = $this->challenges->findLatestUsable($phoneNumber);
        if (!$challenge instanceof OtpChallenge || $challenge->isExpired() || $challenge->isConsumed()) {
            return false;
        }

        $challenge->incrementAttempts();
        if ($challenge->getAttempts() > self::MAX_ATTEMPTS) {
            $this->entityManager->flush();
            return false;
        }

        $valid = hash_equals($challenge->getCodeHash(), $this->hashCode($phoneNumber, $code));
        if ($valid) {
            $challenge->consume();
        }

        $this->entityManager->flush();

        return $valid;
    }

    private function hashCode(string $phoneNumber, string $code): string
    {
        return hash_hmac('sha256', $phoneNumber.':'.$code, $this->appSecret);
    }
}
