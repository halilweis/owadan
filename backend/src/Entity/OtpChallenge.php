<?php

declare(strict_types=1);

namespace App\Entity;

use App\Repository\OtpChallengeRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity(repositoryClass: OtpChallengeRepository::class)]
#[ORM\Table(name: 'otp_challenge')]
class OtpChallenge
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    private Uuid $id;

    #[ORM\Column(length: 32)]
    private string $phoneNumber;

    #[ORM\Column(length: 64)]
    private string $codeHash;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $expiresAt;

    #[ORM\Column(type: 'datetime_immutable', nullable: true)]
    private ?\DateTimeImmutable $consumedAt = null;

    #[ORM\Column(options: ['default' => 0])]
    private int $attempts = 0;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    public function __construct(string $phoneNumber, string $codeHash, \DateTimeImmutable $expiresAt)
    {
        $this->id = Uuid::v7();
        $this->phoneNumber = $phoneNumber;
        $this->codeHash = $codeHash;
        $this->expiresAt = $expiresAt;
        $this->createdAt = new \DateTimeImmutable();
    }

    public function getId(): Uuid { return $this->id; }
    public function getPhoneNumber(): string { return $this->phoneNumber; }
    public function getCodeHash(): string { return $this->codeHash; }
    public function getExpiresAt(): \DateTimeImmutable { return $this->expiresAt; }
    public function getConsumedAt(): ?\DateTimeImmutable { return $this->consumedAt; }
    public function getAttempts(): int { return $this->attempts; }

    public function incrementAttempts(): void { ++$this->attempts; }
    public function consume(): void { $this->consumedAt = new \DateTimeImmutable(); }

    public function isExpired(): bool
    {
        return $this->expiresAt <= new \DateTimeImmutable();
    }

    public function isConsumed(): bool
    {
        return $this->consumedAt !== null;
    }
}
