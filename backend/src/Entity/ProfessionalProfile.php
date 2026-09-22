<?php

declare(strict_types=1);

namespace App\Entity;

use App\Enum\VerificationStatus;
use App\Repository\ProfessionalProfileRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity(repositoryClass: ProfessionalProfileRepository::class)]
#[ORM\Table(name: 'professional_profile')]
class ProfessionalProfile
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    private Uuid $id;

    #[ORM\OneToOne]
    #[ORM\JoinColumn(nullable: false, unique: true, onDelete: 'CASCADE')]
    private User $user;

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(nullable: true, onDelete: 'SET NULL')]
    private ?District $district = null;

    #[ORM\Column(length: 120)]
    private string $displayName;

    #[ORM\Column(type: 'text', nullable: true)]
    private ?string $bio = null;

    #[ORM\Column(type: 'smallint', nullable: true)]
    private ?int $experienceYears = null;

    #[ORM\Column(type: 'json')]
    private array $languages = [];

    #[ORM\Column(enumType: VerificationStatus::class, length: 20)]
    private VerificationStatus $verificationStatus = VerificationStatus::DRAFT;

    #[ORM\Column(options: ['default' => true])]
    private bool $active = true;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $updatedAt;

    public function __construct(User $user, string $displayName)
    {
        $this->id = Uuid::v7();
        $this->user = $user;
        $this->displayName = trim($displayName);
        $this->createdAt = new \DateTimeImmutable();
        $this->updatedAt = $this->createdAt;
    }

    public function getId(): Uuid { return $this->id; }
    public function getUser(): User { return $this->user; }
    public function getDistrict(): ?District { return $this->district; }
    public function getDisplayName(): string { return $this->displayName; }
    public function getBio(): ?string { return $this->bio; }
    public function getExperienceYears(): ?int { return $this->experienceYears; }
    public function getLanguages(): array { return $this->languages; }
    public function getVerificationStatus(): VerificationStatus { return $this->verificationStatus; }
    public function isActive(): bool { return $this->active; }

    public function update(
        string $displayName,
        ?string $bio,
        ?int $experienceYears,
        array $languages,
        ?District $district,
    ): void {
        $this->displayName = trim($displayName);
        $this->bio = $bio !== null && trim($bio) !== '' ? trim($bio) : null;
        $this->experienceYears = $experienceYears;
        $this->languages = array_values(array_unique($languages));
        $this->district = $district;
        $this->updatedAt = new \DateTimeImmutable();
    }

    public function submitForVerification(): void
    {
        $this->verificationStatus = VerificationStatus::PENDING;
        $this->updatedAt = new \DateTimeImmutable();
    }
    public function approve(): void
    {
        $this->verificationStatus = VerificationStatus::APPROVED;
        $this->updatedAt = new \DateTimeImmutable();
    }

    public function reject(): void
    {
        $this->verificationStatus = VerificationStatus::REJECTED;
        $this->updatedAt = new \DateTimeImmutable();
    }
}
