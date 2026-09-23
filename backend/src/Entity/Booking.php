<?php

declare(strict_types=1);

namespace App\Entity;

use App\Enum\BookingStatus;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity]
#[ORM\Table(name: 'booking')]
class Booking
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

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(nullable: false, onDelete: 'RESTRICT')]
    private ProfessionalService $service;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $startsAt;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $endsAt;

    #[ORM\Column(enumType: BookingStatus::class, length: 40)]
    private BookingStatus $status = BookingStatus::PENDING;

    #[ORM\Column(length: 120)]
    private string $serviceName;

    #[ORM\Column(length: 20)]
    private string $priceType;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 2, nullable: true)]
    private ?string $price = null;

    #[ORM\Column(length: 3)]
    private string $currency = 'TMT';

    #[ORM\Column(type: 'text', nullable: true)]
    private ?string $note = null;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $updatedAt;

    public function __construct(
        User $customer,
        ProfessionalProfile $professional,
        ProfessionalService $service,
        \DateTimeImmutable $startsAt,
        \DateTimeImmutable $endsAt,
        string $serviceName,
        string $priceType,
        ?string $price,
        string $currency = 'TMT',
        ?string $note = null,
    ) {
        $this->id = Uuid::v7();
        $this->customer = $customer;
        $this->professional = $professional;
        $this->service = $service;
        $this->startsAt = $startsAt;
        $this->endsAt = $endsAt;
        $this->serviceName = $serviceName;
        $this->priceType = $priceType;
        $this->price = $price;
        $this->currency = $currency;
        $this->note = $note;
        $this->createdAt = new \DateTimeImmutable();
        $this->updatedAt = $this->createdAt;
    }

    public function getId(): Uuid { return $this->id; }
    public function getCustomer(): User { return $this->customer; }
    public function getProfessional(): ProfessionalProfile { return $this->professional; }
    public function getService(): ProfessionalService { return $this->service; }
    public function getStartsAt(): \DateTimeImmutable { return $this->startsAt; }
    public function getEndsAt(): \DateTimeImmutable { return $this->endsAt; }
    public function getStatus(): BookingStatus { return $this->status; }
    public function getServiceName(): string { return $this->serviceName; }
    public function getPriceType(): string { return $this->priceType; }
    public function getPrice(): ?string { return $this->price; }
    public function getCurrency(): string { return $this->currency; }
    public function getNote(): ?string { return $this->note; }

    public function confirm(): void
    {
        $this->status = BookingStatus::CONFIRMED;
        $this->updatedAt = new \DateTimeImmutable();
    }

    public function decline(): void
    {
        $this->status = BookingStatus::DECLINED;
        $this->updatedAt = new \DateTimeImmutable();
    }

    public function cancelByCustomer(): void
    {
        $this->status = BookingStatus::CANCELLED_BY_CUSTOMER;
        $this->updatedAt = new \DateTimeImmutable();
    }

    public function cancelByProfessional(): void
    {
        $this->status = BookingStatus::CANCELLED_BY_PROFESSIONAL;
        $this->updatedAt = new \DateTimeImmutable();
    }

    public function complete(): void
    {
        $this->status = BookingStatus::COMPLETED;
        $this->updatedAt = new \DateTimeImmutable();
    }

    public function markNoShow(): void
    {
        $this->status = BookingStatus::NO_SHOW;
        $this->updatedAt = new \DateTimeImmutable();
    }
}