<?php

declare(strict_types=1);

namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity]
#[ORM\Table(name: 'working_hours')]
class WorkingHours
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    private Uuid $id;

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private ProfessionalProfile $professional;

    #[ORM\Column(type: 'smallint')]
    private int $dayOfWeek;

    #[ORM\Column(length: 5)]
    private string $startTime;

    #[ORM\Column(length: 5)]
    private string $endTime;

    #[ORM\Column(options: ['default' => true])]
    private bool $active = true;

    public function __construct(
        ProfessionalProfile $professional,
        int $dayOfWeek,
        string $startTime,
        string $endTime,
    ) {
        $this->id = Uuid::v7();
        $this->professional = $professional;
        $this->dayOfWeek = $dayOfWeek;
        $this->startTime = $startTime;
        $this->endTime = $endTime;
    }

    public function getId(): Uuid { return $this->id; }
    public function getProfessional(): ProfessionalProfile { return $this->professional; }
    public function getDayOfWeek(): int { return $this->dayOfWeek; }
    public function getStartTime(): string { return $this->startTime; }
    public function getEndTime(): string { return $this->endTime; }
    public function isActive(): bool { return $this->active; }

    public function update(
        int $dayOfWeek,
        string $startTime,
        string $endTime,
        bool $active,
    ): void {
        $this->dayOfWeek = $dayOfWeek;
        $this->startTime = $startTime;
        $this->endTime = $endTime;
        $this->active = $active;
    }
}