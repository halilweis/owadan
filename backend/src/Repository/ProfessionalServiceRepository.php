<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\ProfessionalProfile;
use App\Entity\ProfessionalService;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/** @extends ServiceEntityRepository<ProfessionalService> */
final class ProfessionalServiceRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, ProfessionalService::class);
    }

    /** @return list<ProfessionalService> */
    public function findActiveForProfessional(ProfessionalProfile $professional): array
    {
        return $this->findBy(
            ['professional' => $professional, 'active' => true],
            ['name' => 'ASC'],
        );
    }
}
