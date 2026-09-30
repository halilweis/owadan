<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use OpenApi\Attributes as OA;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

final class AccountController extends AbstractController
{
    private const LANGUAGES = ['tk', 'ru', 'en'];

    #[OA\Get(
        path: '/api/v1/me/profile',
        summary: 'Get the current customer profile',
        tags: ['Account'],
        security: [['Bearer' => []]],
        responses: [
            new OA\Response(response: 200, description: 'Customer profile'),
            new OA\Response(response: 401, description: 'Authentication required'),
        ],
    )]
    #[Route('/api/v1/me/profile', methods: ['GET'])]
    public function profile(): JsonResponse
    {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json([
                'error' => [
                    'code' => 'UNAUTHENTICATED',
                    'message' => 'Authentication required.',
                ],
            ], 401);
        }

        return $this->json([
            'data' => ['user' => $this->payload($user)],
        ]);
    }

    #[OA\Patch(
        path: '/api/v1/me/profile',
        summary: 'Update the current customer profile',
        tags: ['Account'],
        security: [['Bearer' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                properties: [
                    new OA\Property(property: 'displayName', type: ['string', 'null'], maxLength: 120),
                    new OA\Property(property: 'preferredLanguage', type: 'string', enum: ['tk', 'ru', 'en']),
                ],
            ),
        ),
        responses: [
            new OA\Response(response: 200, description: 'Profile updated'),
            new OA\Response(response: 401, description: 'Authentication required'),
            new OA\Response(response: 422, description: 'Validation error'),
        ],
    )]
    #[Route('/api/v1/me/profile', methods: ['PATCH'])]
    public function update(Request $request, EntityManagerInterface $entityManager): JsonResponse
    {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json([
                'error' => [
                    'code' => 'UNAUTHENTICATED',
                    'message' => 'Authentication required.',
                ],
            ], 401);
        }

        $payload = $request->toArray();

        if (array_key_exists('displayName', $payload)) {
            $displayName = $payload['displayName'];

            if ($displayName !== null && !is_string($displayName)) {
                return $this->validationError('displayName must be a string or null.');
            }

            $normalized = is_string($displayName) ? trim($displayName) : null;

            if ($normalized !== null && mb_strlen($normalized) > 120) {
                return $this->validationError('displayName must be at most 120 characters.');
            }

            $user->setDisplayName($normalized);
        }

        if (array_key_exists('preferredLanguage', $payload)) {
            $language = strtolower(trim((string) $payload['preferredLanguage']));

            if (!in_array($language, self::LANGUAGES, true)) {
                return $this->validationError('preferredLanguage must be one of: tk, ru, en.');
            }

            $user->setPreferredLanguage($language);
        }

        $entityManager->flush();

        return $this->json([
            'data' => ['user' => $this->payload($user)],
        ]);
    }

    private function payload(User $user): array
    {
        return [
            'id' => $user->getId()->toRfc4122(),
            'phoneNumber' => $user->getPhoneNumber(),
            'displayName' => $user->getDisplayName(),
            'preferredLanguage' => $user->getPreferredLanguage(),
            'roles' => $user->getRoles(),
        ];
    }

    private function validationError(string $message): JsonResponse
    {
        return $this->json([
            'error' => [
                'code' => 'VALIDATION_ERROR',
                'message' => $message,
            ],
        ], 422);
    }
}
