<?php
namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
class City
{
    #[ORM\Id, ORM\GeneratedValue, ORM\Column]
    private ?int $id = null;
    #[ORM\ManyToOne, ORM\JoinColumn(nullable:false)]
    private Country $country;
    #[ORM\Column(length:120)]
    private string $name;
    public function __construct(Country $country, string $name) { $this->country=$country; $this->name=$name; }
}
