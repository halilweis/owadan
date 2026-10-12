<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\AvailabilityException;
use App\Entity\PortfolioItem;
use App\Entity\ProfessionalProfile;
use App\Entity\ProfessionalService;
use App\Entity\User;
use App\Entity\WorkingHours;
use App\Repository\ProfessionalProfileRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;
use App\Enum\VerificationStatus;
use Symfony\Component\HttpKernel\KernelInterface;

final class ProfessionalAvailabilityController extends AbstractController
{
    #[Route('/api/v1/pro/portfolio', methods: ['POST'])]
    public function createPortfolioItem(
        Request $request,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $profile = $profiles->findOneByUser($user);

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'PROFILE_REQUIRED']], 409);
        }

        $payload = $request->toArray();

        $imageUrl = trim((string) ($payload['imageUrl'] ?? ''));

        if ($imageUrl === '') {
            return $this->json(['error' => ['code' => 'VALIDATION_ERROR', 'message' => 'imageUrl is required.']], 422);
        }

        $service = null;

        if (!empty($payload['serviceId'])) {
            $service = $entityManager->find(
                ProfessionalService::class,
                $payload['serviceId'],
            );

            if (
                !$service instanceof ProfessionalService
                || $service->getProfessional()->getId()->toRfc4122()
                    !== $profile->getId()->toRfc4122()
            ) {
                return $this->json([
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'serviceId is invalid.',
                    ],
                ], 422);
            }
        }

        $item = new PortfolioItem($profile, $imageUrl, $service);

        $item->update(
            $imageUrl,
            isset($payload['title']) ? (string) $payload['title'] : null,
            isset($payload['description']) ? (string) $payload['description'] : null,
            $service,
            (bool) ($payload['featured'] ?? false),
            (bool) ($payload['active'] ?? true),
        );

        $entityManager->persist($item);
        $entityManager->flush();

        return $this->json([
            'data' => [
                'portfolioItem' => $this->portfolioPayload($item),
            ],
        ], 201);
    }

    #[Route('/api/v1/pro/working-hours', methods: ['GET'])]
    public function workingHours(
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $profile = $profiles->findOneByUser($user);

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'PROFILE_REQUIRED']], 409);
        }

        $hours = $entityManager
            ->getRepository(WorkingHours::class)
            ->findBy(
                [
                    'professional' => $profile,
                    'active' => true,
                ],
                [
                    'dayOfWeek' => 'ASC',
                    'startTime' => 'ASC',
                ],
            );

        return $this->json([
            'data' => [
                'items' => array_map(
                    static fn (WorkingHours $item): array => [
                        'id' => $item->getId()->toRfc4122(),
                        'dayOfWeek' => $item->getDayOfWeek(),
                        'startTime' => $item->getStartTime(),
                        'endTime' => $item->getEndTime(),
                    ],
                    $hours,
                ),
            ],
        ]);
    }

    #[Route('/api/v1/pro/working-hours', methods: ['PUT'])]
    public function setWorkingHours(
        Request $request,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $profile = $profiles->findOneByUser($user);

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'PROFILE_REQUIRED']], 409);
        }

        $payload = $request->toArray();
        $items = $payload['items'] ?? null;

        if (!is_array($items)) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'items must be an array.',
                ],
            ], 422);
        }

        $validated = [];

        foreach ($items as $item) {
            if (!is_array($item)) {
                return $this->json([
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Each working-hours item must be an object.',
                    ],
                ], 422);
            }

            $dayOfWeek = (int) ($item['dayOfWeek'] ?? 0);
            $startTime = (string) ($item['startTime'] ?? '');
            $endTime = (string) ($item['endTime'] ?? '');

            if ($dayOfWeek < 1 || $dayOfWeek > 7) {
                return $this->json([
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'dayOfWeek must be between 1 and 7.',
                    ],
                ], 422);
            }

            if (
                !preg_match('/^\d{2}:\d{2}$/', $startTime)
                || !preg_match('/^\d{2}:\d{2}$/', $endTime)
            ) {
                return $this->json([
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'startTime and endTime must use HH:MM format.',
                    ],
                ], 422);
            }

            if ($startTime >= $endTime) {
                return $this->json([
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'startTime must be before endTime.',
                    ],
                ], 422);
            }

            $validated[] = [
                'dayOfWeek' => $dayOfWeek,
                'startTime' => $startTime,
                'endTime' => $endTime,
            ];
        }

        $entityManager->createQueryBuilder()
            ->delete(WorkingHours::class, 'w')
            ->where('w.professional = :profile')
            ->setParameter('profile', $profile)
            ->getQuery()
            ->execute();

        foreach ($validated as $item) {
            $hours = new WorkingHours(
                $profile,
                $item['dayOfWeek'],
                $item['startTime'],
                $item['endTime'],
            );

            $entityManager->persist($hours);
        }

        $entityManager->flush();

        return $this->json([
            'data' => [
                'updated' => true,
                'items' => $validated,
            ],
        ]);
    }

    #[Route('/api/v1/pro/availability-exceptions', methods: ['GET'])]
    public function availabilityExceptions(
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $profile = $profiles->findOneByUser($user);

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'PROFILE_REQUIRED']], 409);
        }

        $items = $entityManager
            ->getRepository(AvailabilityException::class)
            ->findBy(
                ['professional' => $profile],
                ['startsAt' => 'ASC'],
            );

        return $this->json([
            'data' => [
                'items' => array_map(
                    static fn (AvailabilityException $item): array => [
                        'id' => $item->getId()->toRfc4122(),
                        'startsAt' => $item->getStartsAt()->format(DATE_ATOM),
                        'endsAt' => $item->getEndsAt()->format(DATE_ATOM),
                        'type' => $item->getType(),
                        'note' => $item->getNote(),
                    ],
                    $items,
                ),
            ],
        ]);
    }

    #[Route('/api/v1/pro/availability-exceptions', methods: ['POST'])]
    public function createAvailabilityException(
        Request $request,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $profile = $profiles->findOneByUser($user);

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'PROFILE_REQUIRED']], 409);
        }

        $payload = $request->toArray();

        try {
            $startsAt = new \DateTimeImmutable((string) ($payload['startsAt'] ?? ''));
            $endsAt = new \DateTimeImmutable((string) ($payload['endsAt'] ?? ''));
        } catch (\Exception) {
            return $this->json(['error' => ['code' => 'VALIDATION_ERROR', 'message' => 'Invalid date/time.']], 422);
        }

        if ($startsAt >= $endsAt) {
            return $this->json(['error' => ['code' => 'VALIDATION_ERROR', 'message' => 'startsAt must be before endsAt.']], 422);
        }

        $type = strtoupper(trim((string) ($payload['type'] ?? '')));

        if (!in_array($type, ['BLOCKED', 'EXTRA'], true)) {
            return $this->json(['error' => ['code' => 'VALIDATION_ERROR', 'message' => 'type must be BLOCKED or EXTRA.']], 422);
        }

        $exception = new AvailabilityException(
            $profile,
            $startsAt,
            $endsAt,
            $type,
            isset($payload['note']) ? (string) $payload['note'] : null,
        );

        $entityManager->persist($exception);
        $entityManager->flush();

        return $this->json([
            'data' => [
                'availabilityException' => [
                    'id' => (string) $exception->getId(),
                    'startsAt' => $exception->getStartsAt()->format(DATE_ATOM),
                    'endsAt' => $exception->getEndsAt()->format(DATE_ATOM),
                    'type' => $exception->getType(),
                    'note' => $exception->getNote(),
                ],
            ],
        ], 201);
    }

    #[Route('/api/v1/pro/availability-exceptions/{id}', methods: ['DELETE'])]
    public function deleteAvailabilityException(
        string $id,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $profile = $profiles->findOneByUser($user);
        $exception = $entityManager->find(AvailabilityException::class, $id);

        if (
            !$profile instanceof ProfessionalProfile
            || !$exception instanceof AvailabilityException
            || $exception->getProfessional()->getId()->toRfc4122()
                !== $profile->getId()->toRfc4122()
        ) {
            return $this->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Availability exception not found.',
                ],
            ], 404);
        }

        $entityManager->remove($exception);
        $entityManager->flush();

        return $this->json([
            'data' => [
                'deleted' => true,
            ],
        ]);
    }

    #[Route('/api/v1/pro/portfolio', methods: ['GET'])]
    public function portfolio(
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $profile = $profiles->findOneByUser($user);

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'PROFILE_REQUIRED']], 409);
        }

        $items = $entityManager
            ->getRepository(PortfolioItem::class)
            ->findBy(
                ['professional' => $profile],
                ['featured' => 'DESC', 'createdAt' => 'DESC'],
            );

        return $this->json([
            'data' => [
                'items' => array_map(
                    fn (PortfolioItem $item): array => $this->portfolioPayload($item),
                    $items,
                ),
            ],
        ]);
    }

    #[Route('/api/v1/pro/portfolio/upload', methods: ['POST'])]
    public function uploadPortfolioImage(
        Request $request,
        ProfessionalProfileRepository $profiles,
        KernelInterface $kernel,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $profile = $profiles->findOneByUser($user);

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'PROFILE_REQUIRED']], 409);
        }

        $file = $request->files->get('image');

        if ($file === null) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'image is required.',
                ],
            ], 422);
        }

        if ($file->getSize() !== false && $file->getSize() > 8 * 1024 * 1024) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'Image must be 8 MB or smaller.',
                ],
            ], 422);
        }

        $mimeType = (string) $file->getMimeType();

        $extensions = [
            'image/jpeg' => 'jpg',
            'image/png' => 'png',
            'image/webp' => 'webp',
        ];

        if (!isset($extensions[$mimeType])) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'Only JPEG, PNG, and WEBP images are allowed.',
                ],
            ], 422);
        }

        $directory = $kernel->getProjectDir() . '/public/uploads/portfolio';

        if (!is_dir($directory) && !mkdir($directory, 0775, true) && !is_dir($directory)) {
            return $this->json([
                'error' => [
                    'code' => 'UPLOAD_FAILED',
                    'message' => 'Unable to create upload directory.',
                ],
            ], 500);
        }

        $fileName = bin2hex(random_bytes(16)) . '.' . $extensions[$mimeType];

        try {
            $file->move($directory, $fileName);
        } catch (\Throwable) {
            return $this->json([
                'error' => [
                    'code' => 'UPLOAD_FAILED',
                    'message' => 'Unable to save image.',
                ],
            ], 500);
        }

        return $this->json([
            'data' => [
                'imageUrl' => '/uploads/portfolio/' . $fileName,
            ],
        ], 201);
    }

    #[Route('/api/v1/pro/portfolio/{id}', methods: ['PUT'])]
    public function updatePortfolioItem(
        string $id,
        Request $request,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $profile = $profiles->findOneByUser($user);
        $item = $entityManager->find(PortfolioItem::class, $id);

        if (
            !$profile instanceof ProfessionalProfile
            || !$item instanceof PortfolioItem
            || $item->getProfessional()->getId()->toRfc4122()
                !== $profile->getId()->toRfc4122()
        ) {
            return $this->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Portfolio item not found.',
                ],
            ], 404);
        }

        $payload = $request->toArray();
        $imageUrl = trim((string) ($payload['imageUrl'] ?? ''));

        if ($imageUrl === '') {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'imageUrl is required.',
                ],
            ], 422);
        }

        $service = null;

        if (!empty($payload['serviceId'])) {
            $service = $entityManager->find(
                ProfessionalService::class,
                $payload['serviceId'],
            );

            if (
                !$service instanceof ProfessionalService
                || $service->getProfessional()->getId()->toRfc4122()
                    !== $profile->getId()->toRfc4122()
            ) {
                return $this->json([
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'serviceId is invalid.',
                    ],
                ], 422);
            }
        }

        $item->update(
            $imageUrl,
            isset($payload['title']) ? (string) $payload['title'] : null,
            isset($payload['description'])
                ? (string) $payload['description']
                : null,
            $service,
            (bool) ($payload['featured'] ?? false),
            (bool) ($payload['active'] ?? true),
        );

        $entityManager->flush();

        return $this->json([
            'data' => [
                'portfolioItem' => $this->portfolioPayload($item),
            ],
        ]);
    }

    #[Route('/api/v1/pro/portfolio/{id}', methods: ['DELETE'])]
    public function deletePortfolioItem(
        string $id,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $profile = $profiles->findOneByUser($user);
        $item = $entityManager->find(PortfolioItem::class, $id);

        if (
            !$profile instanceof ProfessionalProfile
            || !$item instanceof PortfolioItem
            || $item->getProfessional()->getId()->toRfc4122()
                !== $profile->getId()->toRfc4122()
        ) {
            return $this->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Portfolio item not found.',
                ],
            ], 404);
        }

        $entityManager->remove($item);
        $entityManager->flush();

        return $this->json([
            'data' => [
                'deleted' => true,
            ],
        ]);
    }

    #[Route('/api/v1/professionals/{id}/portfolio', methods: ['GET'])]
    public function publicPortfolio(
        string $id,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $profile = $entityManager->find(ProfessionalProfile::class, $id);

        if (
            !$profile instanceof ProfessionalProfile
            || !$profile->isActive()
            || $profile->getVerificationStatus() !== VerificationStatus::APPROVED
        ) {
            return $this->json([
                'error' => [
                    'code' => 'PROFESSIONAL_NOT_FOUND',
                    'message' => 'Professional not found.',
                ],
            ], 404);
        }

        $items = $entityManager
            ->getRepository(PortfolioItem::class)
            ->findBy(
                [
                    'professional' => $profile,
                    'active' => true,
                ],
                [
                    'featured' => 'DESC',
                    'createdAt' => 'DESC',
                ],
            );

        return $this->json([
            'data' => [
                'items' => array_map(
                    fn (PortfolioItem $item): array => $this->portfolioPayload($item),
                    $items,
                ),
            ],
        ]);
    }

    private function portfolioPayload(PortfolioItem $item): array
    {
        return [
            'id' => $item->getId()->toRfc4122(),
            'imageUrl' => $item->getImageUrl(),
            'title' => $item->getTitle(),
            'description' => $item->getDescription(),
            'serviceId' => $item->getService()?->getId()->toRfc4122(),
            'serviceName' => $item->getService()?->getName(),
            'featured' => $item->isFeatured(),
            'active' => $item->isActive(),
        ];
    }
}