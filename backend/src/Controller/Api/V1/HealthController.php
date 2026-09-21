<?php
namespace App\Controller\Api\V1;

use Doctrine\DBAL\Connection;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

final class HealthController extends AbstractController
{
    #[Route('/health', methods:['GET'])]
    public function health(): JsonResponse
    {
        return $this->json(['status' => 'ok', 'service' => 'owadan-api']);
    }

    #[Route('/ready', methods:['GET'])]
    public function ready(Connection $connection): JsonResponse
    {
        $connection->executeQuery('SELECT 1')->fetchOne();
        return $this->json(['status' => 'ready', 'database' => 'ok']);
    }
}
