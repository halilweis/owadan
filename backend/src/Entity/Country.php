<?php
namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
class Country
{
    #[ORM\Id, ORM\GeneratedValue, ORM\Column]
    private ?int $id = null;
    #[ORM\Column(length: 2, unique: true)]
    private string $code;
    #[ORM\Column(length: 120)]
    private string $name;
    public function __construct(string $code, string $name) { $this->code=$code; $this->name=$name; }
    public function getId(): ?int { return $this->id; }
}
