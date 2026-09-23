<?php

declare(strict_types=1);

namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity]
#[ORM\Table(name: 'favorite')]
#[ORM\UniqueConstraint(name: 'uniq_favorite_customer_professional', columns: ['customer_id', 'professional_id'])]
class Favorite
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    private Uuid $id;

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private User $customer;

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private ProfessionalProfile $professional;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    public function __construct(
        User $customer,
        ProfessionalProfile $professional,
    ) {
        $this->id = Uuid::v7();
        $this->customer = $customer;
        $this->professional = $professional;
        $this->createdAt = new \DateTimeImmutable();
    }

    public function getId(): Uuid { return $this->id; }
    public function getCustomer(): User { return $this->customer; }
    public function getProfessional(): ProfessionalProfile { return $this->professional; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
}