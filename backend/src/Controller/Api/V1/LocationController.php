<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\City;
use App\Entity\District;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

final class LocationController extends AbstractController
{
    #[Route('/api/v1/locations', methods: ['GET'])]
    public function index(EntityManagerInterface $entityManager): JsonResponse
    {
        $cities = $entityManager->getRepository(City::class)->findBy(
            [],
            ['name' => 'ASC'],
        );

        $data = [];

        foreach ($cities as $city) {
            if (!$city instanceof City || $city->getId() === null) {
                continue;
            }

            $districts = $entityManager->getRepository(District::class)->findBy(
                ['city' => $city],
                ['name' => 'ASC'],
            );

            $data[] = [
                'id' => $city->getId(),
                'name' => $city->getName(),
                'districts' => array_map(
                    static fn (District $district): array => [
                        'id' => $district->getId(),
                        'cityId' => $city->getId(),
                        'name' => $district->getName(),
                    ],
                    $districts,
                ),
            ];
        }

        return $this->json([
            'data' => [
                'cities' => $data,
            ],
        ]);
    }
}