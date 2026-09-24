<?php

declare(strict_types=1);

namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity]
#[ORM\Table(name: 'professional_client_note')]
#[ORM\UniqueConstraint(
    name: 'uniq_professional_client_note',
    columns: ['professional_id', 'customer_id']
)]
class ProfessionalClientNote
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    private Uuid $id;

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private ProfessionalProfile $professional;

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private User $customer;

    #[ORM\Column(type: 'text', nullable: true)]
    private ?string $note = null;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $updatedAt;

    public function __construct(
        ProfessionalProfile $professional,
        User $customer,
        ?string $note = null,
    ) {
        $this->id = Uuid::v7();
        $this->professional = $professional;
        $this->customer = $customer;
        $this->setNote($note);
        $this->updatedAt = new \DateTimeImmutable();
    }

    public function getId(): Uuid
    {
        return $this->id;
    }

    public function getProfessional(): ProfessionalProfile
    {
        return $this->professional;
    }

    public function getCustomer(): User
    {
        return $this->customer;
    }

    public function getNote(): ?string
    {
        return $this->note;
    }

    public function getUpdatedAt(): \DateTimeImmutable
    {
        return $this->updatedAt;
    }

    public function setNote(?string $note): void
    {
        $this->note = $note !== null && trim($note) !== ''
            ? trim($note)
            : null;

        $this->updatedAt = new \DateTimeImmutable();
    }
}