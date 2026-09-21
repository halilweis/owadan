<?php
namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
class District
{
    #[ORM\Id, ORM\GeneratedValue, ORM\Column]
    private ?int $id = null;
    #[ORM\ManyToOne, ORM\JoinColumn(nullable:false)]
    private City $city;
    #[ORM\Column(length:120)]
    private string $name;
    public function __construct(City $city, string $name) { $this->city=$city; $this->name=$name; }
}
