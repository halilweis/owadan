<?php

declare(strict_types=1);

namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity]
#[ORM\Table(name: 'portfolio_item')]
class PortfolioItem
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    private Uuid $id;

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private ProfessionalProfile $professional;

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(nullable: true, onDelete: 'SET NULL')]
    private ?ProfessionalService $service = null;

    #[ORM\Column(length: 255)]
    private string $imageUrl;

    #[ORM\Column(length: 160, nullable: true)]
    private ?string $title = null;

    #[ORM\Column(type: 'text', nullable: true)]
    private ?string $description = null;

    #[ORM\Column(options: ['default' => false])]
    private bool $featured = false;

    #[ORM\Column(options: ['default' => true])]
    private bool $active = true;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $updatedAt;

    public function __construct(
        ProfessionalProfile $professional,
        string $imageUrl,
        ?ProfessionalService $service = null,
    ) {
        $this->id = Uuid::v7();
        $this->professional = $professional;
        $this->imageUrl = trim($imageUrl);
        $this->service = $service;
        $this->createdAt = new \DateTimeImmutable();
        $this->updatedAt = $this->createdAt;
    }

    public function getId(): Uuid { return $this->id; }
    public function getProfessional(): ProfessionalProfile { return $this->professional; }
    public function getService(): ?ProfessionalService { return $this->service; }
    public function getImageUrl(): string { return $this->imageUrl; }
    public function getTitle(): ?string { return $this->title; }
    public function getDescription(): ?string { return $this->description; }
    public function isFeatured(): bool { return $this->featured; }
    public function isActive(): bool { return $this->active; }

    public function update(
        string $imageUrl,
        ?string $title,
        ?string $description,
        ?ProfessionalService $service,
        bool $featured,
        bool $active,
    ): void {
        $this->imageUrl = trim($imageUrl);
        $this->title = $title !== null && trim($title) !== '' ? trim($title) : null;
        $this->description = $description !== null && trim($description) !== '' ? trim($description) : null;
        $this->service = $service;
        $this->featured = $featured;
        $this->active = $active;
        $this->updatedAt = new \DateTimeImmutable();
    }
}