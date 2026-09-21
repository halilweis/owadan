<?php

namespace App\Entity;

use App\Repository\UserRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Security\Core\User\UserInterface;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity(repositoryClass: UserRepository::class)]
#[ORM\Table(name: 'app_user')]
class User implements UserInterface
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    private Uuid $id;

    #[ORM\Column(length: 32, unique: true)]
    private string $phoneNumber;

    #[ORM\Column(type: 'json')]
    private array $roles = ['ROLE_CUSTOMER'];

    #[ORM\Column(options: ['default' => true])]
    private bool $active = true;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    public function __construct(string $phoneNumber)
    {
        $this->id = Uuid::v7();
        $this->phoneNumber = $phoneNumber;
        $this->createdAt = new \DateTimeImmutable();
    }

    public function getId(): Uuid { return $this->id; }
    public function getPhoneNumber(): string { return $this->phoneNumber; }
    public function getUserIdentifier(): string { return $this->phoneNumber; }
    public function getRoles(): array { return array_values(array_unique([...$this->roles, 'ROLE_CUSTOMER'])); }
    public function setRoles(array $roles): self { $this->roles = $roles; return $this; }
    public function isActive(): bool { return $this->active; }
    public function eraseCredentials(): void { }
}
