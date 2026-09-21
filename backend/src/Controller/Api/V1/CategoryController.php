<?php
namespace App\Controller\Api\V1;

use App\Repository\CategoryRepository;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

final class CategoryController extends AbstractController
{
    #[Route('/api/v1/categories', methods:['GET'])]
    public function __invoke(CategoryRepository $categories): JsonResponse
    {
        $data = array_map(static fn($category) => [
            'id' => $category->getId(),
            'slug' => $category->getSlug(),
            'name' => $category->getNameI18n(),
        ], $categories->findActiveRoots());

        return $this->json(['data' => $data, 'meta' => ['count' => count($data)]]);
    }
}
