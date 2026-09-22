<?php

declare(strict_types=1);

namespace App\Entity;

use App\Enum\PriceType;
use App\Repository\ProfessionalServiceRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity(repositoryClass: ProfessionalServiceRepository::class)]
#[ORM\Table(name: 'professional_service')]
class ProfessionalService
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    private Uuid $id;

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private ProfessionalProfile $professional;

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(nullable: false, onDelete: 'RESTRICT')]
    private Category $category;

    #[ORM\Column(length: 120)]
    private string $name;

    #[ORM\Column(type: 'text', nullable: true)]
    private ?string $description = null;

    #[ORM\Column(type: 'smallint')]
    private int $durationMinutes;

    #[ORM\Column(enumType: PriceType::class, length: 20)]
    private PriceType $priceType;

    #[ORM\Column(type: 'decimal', precision: 12, scale: 2, nullable: true)]
    private ?string $price = null;

    #[ORM\Column(length: 3)]
    private string $currency = 'TMT';

    #[ORM\Column(options: ['default' => true])]
    private bool $active = true;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $updatedAt;

    public function __construct(
        ProfessionalProfile $professional,
        Category $category,
        string $name,
        int $durationMinutes,
        PriceType $priceType,
        ?string $price,
    ) {
        $this->id = Uuid::v7();
        $this->professional = $professional;
        $this->category = $category;
        $this->name = trim($name);
        $this->durationMinutes = $durationMinutes;
        $this->priceType = $priceType;
        $this->price = $price;
        $this->createdAt = new \DateTimeImmutable();
        $this->updatedAt = $this->createdAt;
    }

    public function getId(): Uuid { return $this->id; }
    public function getProfessional(): ProfessionalProfile { return $this->professional; }
    public function getCategory(): Category { return $this->category; }
    public function getName(): string { return $this->name; }
    public function getDescription(): ?string { return $this->description; }
    public function getDurationMinutes(): int { return $this->durationMinutes; }
    public function getPriceType(): PriceType { return $this->priceType; }
    public function getPrice(): ?string { return $this->price; }
    public function getCurrency(): string { return $this->currency; }
    public function isActive(): bool { return $this->active; }

    public function update(
        Category $category,
        string $name,
        ?string $description,
        int $durationMinutes,
        PriceType $priceType,
        ?string $price,
        bool $active,
    ): void {
        $this->category = $category;
        $this->name = trim($name);
        $this->description = $description !== null && trim($description) !== '' ? trim($description) : null;
        $this->durationMinutes = $durationMinutes;
        $this->priceType = $priceType;
        $this->price = $price;
        $this->active = $active;
        $this->updatedAt = new \DateTimeImmutable();
    }
}
