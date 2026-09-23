<?php

declare(strict_types=1);

namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity]
#[ORM\Table(name: 'review')]
#[ORM\UniqueConstraint(name: 'uniq_review_booking', columns: ['booking_id'])]
class Review
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    private Uuid $id;

    #[ORM\OneToOne]
    #[ORM\JoinColumn(nullable: false, unique: true, onDelete: 'CASCADE')]
    private Booking $booking;

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private User $customer;

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private ProfessionalProfile $professional;

    #[ORM\Column(type: 'smallint')]
    private int $rating;

    #[ORM\Column(type: 'text', nullable: true)]
    private ?string $comment = null;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    public function __construct(
        Booking $booking,
        User $customer,
        ProfessionalProfile $professional,
        int $rating,
        ?string $comment = null,
    ) {
        $this->id = Uuid::v7();
        $this->booking = $booking;
        $this->customer = $customer;
        $this->professional = $professional;
        $this->rating = $rating;
        $this->comment = $comment !== null && trim($comment) !== '' ? trim($comment) : null;
        $this->createdAt = new \DateTimeImmutable();
    }

    public function getId(): Uuid { return $this->id; }
    public function getBooking(): Booking { return $this->booking; }
    public function getCustomer(): User { return $this->customer; }
    public function getProfessional(): ProfessionalProfile { return $this->professional; }
    public function getRating(): int { return $this->rating; }
    public function getComment(): ?string { return $this->comment; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
}