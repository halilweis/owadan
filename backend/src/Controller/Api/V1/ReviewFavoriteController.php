<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\Booking;
use App\Entity\Favorite;
use App\Entity\ProfessionalProfile;
use App\Entity\Review;
use App\Entity\User;
use App\Enum\BookingStatus;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Uid\Uuid;

final class ReviewFavoriteController extends AbstractController
{
    #[Route('/api/v1/bookings/{id}/review', methods: ['POST'])]
    public function createReview(
        Booking $booking,
        Request $request,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        if ($booking->getCustomer()->getId() !== $user->getId()) {
            return $this->json(['error' => ['code' => 'FORBIDDEN']], 403);
        }

        if ($booking->getStatus() !== BookingStatus::COMPLETED) {
            return $this->json([
                'error' => [
                    'code' => 'BOOKING_NOT_COMPLETED',
                    'message' => 'Only completed bookings can be reviewed.',
                ],
            ], 409);
        }

        $existing = $entityManager->getRepository(Review::class)->findOneBy([
            'booking' => $booking,
        ]);

        if ($existing instanceof Review) {
            return $this->json([
                'error' => [
                    'code' => 'REVIEW_ALREADY_EXISTS',
                    'message' => 'This booking has already been reviewed.',
                ],
            ], 409);
        }

        $payload = $request->toArray();
        $rating = (int) ($payload['rating'] ?? 0);

        if ($rating < 1 || $rating > 5) {
            return $this->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'rating must be between 1 and 5.',
                ],
            ], 422);
        }

        $review = new Review(
            $booking,
            $user,
            $booking->getProfessional(),
            $rating,
            isset($payload['comment']) ? (string) $payload['comment'] : null,
        );

        $entityManager->persist($review);
        $entityManager->flush();

        return $this->json([
            'data' => [
                'review' => $this->reviewPayload($review),
            ],
        ], 201);
    }

    #[Route('/api/v1/professionals/{id}/reviews', methods: ['GET'])]
    public function professionalReviews(
        string $id,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        try {
            $uuid = Uuid::fromString($id);
        } catch (\InvalidArgumentException) {
            return $this->json(['error' => ['code' => 'NOT_FOUND']], 404);
        }

        $profile = $entityManager->find(ProfessionalProfile::class, $uuid);

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'NOT_FOUND']], 404);
        }

        $reviews = $entityManager->getRepository(Review::class)->findBy(
            ['professional' => $profile],
            ['createdAt' => 'DESC'],
        );

        return $this->json([
            'data' => [
                'reviews' => array_map(
                    fn (Review $review) => $this->reviewPayload($review),
                    $reviews,
                ),
            ],
        ]);
    }

    #[Route('/api/v1/me/favorites', methods: ['GET'])]
    public function favorites(
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        $favorites = $entityManager->getRepository(Favorite::class)->findBy(
            ['customer' => $user],
            ['createdAt' => 'DESC'],
        );

        return $this->json([
            'data' => [
                'favorites' => array_map(
                    static fn (Favorite $favorite) => [
                        'id' => (string) $favorite->getId(),
                        'professionalId' => (string) $favorite->getProfessional()->getId(),
                        'displayName' => $favorite->getProfessional()->getDisplayName(),
                        'createdAt' => $favorite->getCreatedAt()->format(DATE_ATOM),
                    ],
                    $favorites,
                ),
            ],
        ]);
    }

    #[Route('/api/v1/me/favorites/{professionalId}', methods: ['POST'])]
    public function addFavorite(
        string $professionalId,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        try {
            $uuid = Uuid::fromString($professionalId);
        } catch (\InvalidArgumentException) {
            return $this->json(['error' => ['code' => 'NOT_FOUND']], 404);
        }

        $professional = $entityManager->find(ProfessionalProfile::class, $uuid);

        if (!$professional instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'NOT_FOUND']], 404);
        }

        $existing = $entityManager->getRepository(Favorite::class)->findOneBy([
            'customer' => $user,
            'professional' => $professional,
        ]);

        if ($existing instanceof Favorite) {
            return $this->json([
                'data' => [
                    'favorite' => [
                        'id' => (string) $existing->getId(),
                        'professionalId' => (string) $professional->getId(),
                    ],
                ],
            ]);
        }

        $favorite = new Favorite($user, $professional);

        $entityManager->persist($favorite);
        $entityManager->flush();

        return $this->json([
            'data' => [
                'favorite' => [
                    'id' => (string) $favorite->getId(),
                    'professionalId' => (string) $professional->getId(),
                ],
            ],
        ], 201);
    }

    #[Route('/api/v1/me/favorites/{professionalId}', methods: ['DELETE'])]
    public function removeFavorite(
        string $professionalId,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED']], 401);
        }

        try {
            $uuid = Uuid::fromString($professionalId);
        } catch (\InvalidArgumentException) {
            return $this->json(['error' => ['code' => 'NOT_FOUND']], 404);
        }

        $professional = $entityManager->find(ProfessionalProfile::class, $uuid);

        if (!$professional instanceof ProfessionalProfile) {
            return $this->json(['error' => ['code' => 'NOT_FOUND']], 404);
        }

        $favorite = $entityManager->getRepository(Favorite::class)->findOneBy([
            'customer' => $user,
            'professional' => $professional,
        ]);

        if ($favorite instanceof Favorite) {
            $entityManager->remove($favorite);
            $entityManager->flush();
        }

        return $this->json([
            'data' => [
                'removed' => true,
            ],
        ]);
    }

    private function reviewPayload(Review $review): array
    {
        return [
            'id' => (string) $review->getId(),
            'bookingId' => (string) $review->getBooking()->getId(),
            'professionalId' => (string) $review->getProfessional()->getId(),
            'rating' => $review->getRating(),
            'comment' => $review->getComment(),
            'createdAt' => $review->getCreatedAt()->format(DATE_ATOM),
        ];
    }
}