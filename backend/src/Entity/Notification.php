<?php

declare(strict_types=1);

namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity]
#[ORM\Table(name: 'notification')]
class Notification
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    private Uuid $id;

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private User $user;

    #[ORM\Column(length: 80)]
    private string $type;

    #[ORM\Column(length: 160)]
    private string $title;

    #[ORM\Column(type: 'text', nullable: true)]
    private ?string $message = null;

    #[ORM\Column(type: 'json')]
    private array $data = [];

    #[ORM\Column(options: ['default' => false])]
    private bool $read = false;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    public function __construct(
        User $user,
        string $type,
        string $title,
        ?string $message = null,
        array $data = [],
    ) {
        $this->id = Uuid::v7();
        $this->user = $user;
        $this->type = trim($type);
        $this->title = trim($title);
        $this->message = $message !== null && trim($message) !== '' ? trim($message) : null;
        $this->data = $data;
        $this->createdAt = new \DateTimeImmutable();
    }

    public function getId(): Uuid { return $this->id; }
    public function getUser(): User { return $this->user; }
    public function getType(): string { return $this->type; }
    public function getTitle(): string { return $this->title; }
    public function getMessage(): ?string { return $this->message; }
    public function getData(): array { return $this->data; }
    public function isRead(): bool { return $this->read; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }

    public function markRead(): void
    {
        $this->read = true;
    }
}