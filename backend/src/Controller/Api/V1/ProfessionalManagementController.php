<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\Category;
use App\Entity\District;
use App\Entity\ProfessionalProfile;
use App\Entity\ProfessionalService;
use App\Entity\User;
use App\Enum\PriceType;
use App\Repository\ProfessionalProfileRepository;
use App\Repository\ProfessionalServiceRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

final class ProfessionalManagementController extends AbstractController
{
    #[Route('/api/v1/pro/profile', methods: ['GET'])]
    public function profile(ProfessionalProfileRepository $profiles): JsonResponse
    {
        $user = $this->requireUser();
        if (!$user instanceof User) {
            return $this->unauthenticated();
        }

        $profile = $profiles->findOneByUser($user);
        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['data' => ['profile' => null]]);
        }

        return $this->json(['data' => ['profile' => $this->profilePayload($profile)]]);
    }

    #[Route('/api/v1/pro/profile', methods: ['PUT'])]
    public function upsertProfile(
        Request $request,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->requireUser();
        if (!$user instanceof User) {
            return $this->unauthenticated();
        }

        $payload = $request->toArray();
        $displayName = trim((string) ($payload['displayName'] ?? ''));
        if ($displayName === '' || grapheme_strlen($displayName) > 120) {
            return $this->validationError('displayName is required and must be at most 120 characters.');
        }

        $experienceYears = $payload['experienceYears'] ?? null;
        if ($experienceYears !== null && (!is_int($experienceYears) || $experienceYears < 0 || $experienceYears > 80)) {
            return $this->validationError('experienceYears must be an integer between 0 and 80.');
        }

        $languages = $payload['languages'] ?? [];
        if (!is_array($languages)) {
            return $this->validationError('languages must be an array.');
        }
        $languages = array_values(array_filter(array_map(
            static fn ($value) => is_string($value) ? trim($value) : '',
            $languages,
        ), static fn (string $value) => $value !== ''));

        $district = null;
        if (isset($payload['districtId'])) {
            $district = $entityManager->find(District::class, (int) $payload['districtId']);
            if (!$district instanceof District) {
                return $this->validationError('districtId is invalid.');
            }
        }

        $profile = $profiles->findOneByUser($user);
        $created = false;
        if (!$profile instanceof ProfessionalProfile) {
            $profile = new ProfessionalProfile($user, $displayName);
            $entityManager->persist($profile);
            $created = true;

            $roles = $user->getRoles();
            if (!in_array('ROLE_PROFESSIONAL', $roles, true)) {
                $user->setRoles([...$roles, 'ROLE_PROFESSIONAL']);
            }
        }

        $profile->update(
            $displayName,
            isset($payload['bio']) ? (string) $payload['bio'] : null,
            $experienceYears,
            $languages,
            $district,
        );

        $entityManager->flush();

        return $this->json([
            'data' => [
                'profile' => $this->profilePayload($profile),
                'auth' => [
                    'tokenRefreshRequired' => $created,
                ],
            ],
        ], $created ? 201 : 200);
    }

    #[Route('/api/v1/pro/profile/submit-verification', methods: ['POST'])]
    public function submitVerification(
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->requireUser();
        if (!$user instanceof User) {
            return $this->unauthenticated();
        }

        $profile = $profiles->findOneByUser($user);
        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'PROFILE_REQUIRED', 'message' => 'Create your professional profile first.']], 409);
        }

        $profile->submitForVerification();
        $entityManager->flush();

        return $this->json(['data' => ['profile' => $this->profilePayload($profile)]]);
    }

    #[Route('/api/v1/pro/services', methods: ['POST'])]
    public function createService(
        Request $request,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->requireUser();
        if (!$user instanceof User) {
            return $this->unauthenticated();
        }

        $profile = $profiles->findOneByUser($user);
        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'PROFILE_REQUIRED', 'message' => 'Create your professional profile first.']], 409);
        }

        $validated = $this->validateServicePayload($request->toArray(), $entityManager);
        if ($validated instanceof JsonResponse) {
            return $validated;
        }

        [$category, $name, $description, $durationMinutes, $priceType, $price, $active] = $validated;
        $service = new ProfessionalService($profile, $category, $name, $durationMinutes, $priceType, $price);
        $service->update($category, $name, $description, $durationMinutes, $priceType, $price, $active);
        $entityManager->persist($service);
        $entityManager->flush();

        return $this->json(['data' => ['service' => $this->servicePayload($service)]], 201);
    }

    #[Route('/api/v1/pro/services/{id}', methods: ['PUT'])]
    public function updateService(
        string $id,
        Request $request,
        ProfessionalProfileRepository $profiles,
        ProfessionalServiceRepository $services,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->requireUser();
        if (!$user instanceof User) {
            return $this->unauthenticated();
        }

        $profile = $profiles->findOneByUser($user);
        $service = $services->find($id);
        if (!$profile instanceof ProfessionalProfile || !$service instanceof ProfessionalService || $service->getProfessional()->getId()->toRfc4122() !== $profile->getId()->toRfc4122()) {
            return $this->json(['error' => ['code' => 'SERVICE_NOT_FOUND', 'message' => 'Service not found.']], 404);
        }

        $validated = $this->validateServicePayload($request->toArray(), $entityManager);
        if ($validated instanceof JsonResponse) {
            return $validated;
        }

        [$category, $name, $description, $durationMinutes, $priceType, $price, $active] = $validated;
        $service->update($category, $name, $description, $durationMinutes, $priceType, $price, $active);
        $entityManager->flush();

        return $this->json(['data' => ['service' => $this->servicePayload($service)]]);
    }

    private function validateServicePayload(array $payload, EntityManagerInterface $entityManager): array|JsonResponse
    {
        $category = $entityManager->find(Category::class, (int) ($payload['categoryId'] ?? 0));
        if (!$category instanceof Category || !$category->isActive()) {
            return $this->validationError('categoryId is invalid.');
        }

        $name = trim((string) ($payload['name'] ?? ''));
        if ($name === '' || grapheme_strlen($name) > 120) {
            return $this->validationError('name is required and must be at most 120 characters.');
        }

        $durationMinutes = (int) ($payload['durationMinutes'] ?? 0);
        if ($durationMinutes < 5 || $durationMinutes > 720) {
            return $this->validationError('durationMinutes must be between 5 and 720.');
        }

        $priceType = PriceType::tryFrom((string) ($payload['priceType'] ?? ''));
        if (!$priceType instanceof PriceType) {
            return $this->validationError('priceType must be FIXED, FROM, or ON_REQUEST.');
        }

        $price = isset($payload['price']) && $payload['price'] !== '' ? (string) $payload['price'] : null;
        if ($priceType !== PriceType::ON_REQUEST && ($price === null || !is_numeric($price) || (float) $price < 0)) {
            return $this->validationError('price is required for FIXED and FROM price types.');
        }
        if ($priceType === PriceType::ON_REQUEST) {
            $price = null;
        }

        return [
            $category,
            $name,
            isset($payload['description']) ? (string) $payload['description'] : null,
            $durationMinutes,
            $priceType,
            $price,
            (bool) ($payload['active'] ?? true),
        ];
    }

    private function requireUser(): ?User
    {
        $user = $this->getUser();
        return $user instanceof User ? $user : null;
    }

    private function profilePayload(ProfessionalProfile $profile): array
    {
        return [
            'id' => $profile->getId()->toRfc4122(),
            'displayName' => $profile->getDisplayName(),
            'bio' => $profile->getBio(),
            'experienceYears' => $profile->getExperienceYears(),
            'languages' => $profile->getLanguages(),
            'verificationStatus' => $profile->getVerificationStatus()->value,
            'active' => $profile->isActive(),
        ];
    }

    private function servicePayload(ProfessionalService $service): array
    {
        return [
            'id' => $service->getId()->toRfc4122(),
            'categoryId' => $service->getCategory()->getId(),
            'name' => $service->getName(),
            'description' => $service->getDescription(),
            'durationMinutes' => $service->getDurationMinutes(),
            'priceType' => $service->getPriceType()->value,
            'price' => $service->getPrice(),
            'currency' => $service->getCurrency(),
            'active' => $service->isActive(),
        ];
    }

    private function validationError(string $message): JsonResponse
    {
        return $this->json(['error' => ['code' => 'VALIDATION_ERROR', 'message' => $message]], 422);
    }

    private function unauthenticated(): JsonResponse
    {
        return $this->json(['error' => ['code' => 'UNAUTHENTICATED', 'message' => 'Authentication required.']], 401);
    }
}
