<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\Category;
use App\Repository\CategoryRepository;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

final class CategoryController extends AbstractController
{
    #[Route('/api/v1/categories', methods: ['GET'])]
    public function index(CategoryRepository $categories): JsonResponse
    {
        $items = $categories->findBy(
            ['active' => true],
            ['sortOrder' => 'ASC', 'id' => 'ASC'],
        );

        $parents = [];
        $children = [];

        foreach ($items as $category) {
            if (!$category instanceof Category) {
                continue;
            }

            if ($category->getParent() === null) {
                $parents[$category->getId()] = [
                    'id' => $category->getId(),
                    'slug' => $category->getSlug(),
                    'nameI18n' => $category->getNameI18n(),
                    'sortOrder' => $category->getSortOrder(),
                    'subcategories' => [],
                ];

                continue;
            }

            $parentId = $category->getParent()->getId();

            $children[$parentId][] = [
                'id' => $category->getId(),
                'slug' => $category->getSlug(),
                'nameI18n' => $category->getNameI18n(),
                'sortOrder' => $category->getSortOrder(),
            ];
        }

        foreach ($children as $parentId => $subcategories) {
            if (isset($parents[$parentId])) {
                $parents[$parentId]['subcategories'] = $subcategories;
            }
        }

        return $this->json([
            'data' => array_values($parents),
        ]);
    }
}