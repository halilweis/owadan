<?php

declare(strict_types=1);

namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity]
#[ORM\Table(name: 'availability_exception')]
class AvailabilityException
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    private Uuid $id;

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private ProfessionalProfile $professional;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $startsAt;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $endsAt;

    #[ORM\Column(length: 20)]
    private string $type;

    #[ORM\Column(type: 'text', nullable: true)]
    private ?string $note = null;

    public function __construct(
        ProfessionalProfile $professional,
        \DateTimeImmutable $startsAt,
        \DateTimeImmutable $endsAt,
        string $type,
        ?string $note = null,
    ) {
        $this->id = Uuid::v7();
        $this->professional = $professional;
        $this->startsAt = $startsAt;
        $this->endsAt = $endsAt;
        $this->type = $type;
        $this->note = $note;
    }

    public function getId(): Uuid { return $this->id; }
    public function getProfessional(): ProfessionalProfile { return $this->professional; }
    public function getStartsAt(): \DateTimeImmutable { return $this->startsAt; }
    public function getEndsAt(): \DateTimeImmutable { return $this->endsAt; }
    public function getType(): string { return $this->type; }
    public function getNote(): ?string { return $this->note; }
}