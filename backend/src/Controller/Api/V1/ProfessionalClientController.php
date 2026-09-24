<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\Booking;
use App\Entity\ProfessionalProfile;
use App\Entity\User;
use App\Enum\BookingStatus;
use App\Repository\ProfessionalProfileRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;
use App\Entity\ProfessionalClientNote;
use Symfony\Component\HttpFoundation\Request;

final class ProfessionalClientController extends AbstractController
{
    #[Route('/api/v1/pro/clients', methods: ['GET'])]
    public function clients(
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json([
                'error' => [
                    'code' => 'UNAUTHENTICATED',
                ],
            ], 401);
        }

        $profile = $profiles->findOneByUser($user);

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json([
                'error' => [
                    'code' => 'PROFILE_REQUIRED',
                ],
            ], 409);
        }

        $rows = $entityManager->createQueryBuilder()
            ->select('customer.id AS customerId')
            ->addSelect('customer.phoneNumber AS phoneNumber')
            ->addSelect('COUNT(b.id) AS appointmentCount')
            ->addSelect('MAX(b.startsAt) AS lastVisit')
            ->from(Booking::class, 'b')
            ->join('b.customer', 'customer')
            ->where('b.professional = :professional')
            ->andWhere('b.status IN (:statuses)')
            ->setParameter('professional', $profile)
            ->setParameter('statuses', [
                BookingStatus::CONFIRMED,
                BookingStatus::COMPLETED,
                BookingStatus::NO_SHOW,
            ])
            ->groupBy('customer.id')
            ->addGroupBy('customer.phoneNumber')
            ->orderBy('lastVisit', 'DESC')
            ->getQuery()
            ->getArrayResult();

        return $this->json([
            'data' => [
                'clients' => array_map(
                    static fn (array $row): array => [
                        'customerId' => (string) $row['customerId'],
                        'phoneNumber' => $row['phoneNumber'],
                        'appointmentCount' => (int) $row['appointmentCount'],
                        'lastVisit' => $row['lastVisit'],
                    ],
                    $rows,
                ),
            ],
        ]);
    }

    #[Route('/api/v1/pro/clients/{customerId}', methods: ['GET'])]
    public function clientHistory(
        string $customerId,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json([
                'error' => [
                    'code' => 'UNAUTHENTICATED',
                ],
            ], 401);
        }

        $profile = $profiles->findOneByUser($user);

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json([
                'error' => [
                    'code' => 'PROFILE_REQUIRED',
                ],
            ], 409);
        }

        $customer = $entityManager->find(User::class, $customerId);

        if (!$customer instanceof User) {
            return $this->json([
                'error' => [
                    'code' => 'CLIENT_NOT_FOUND',
                ],
            ], 404);
        }

        $bookings = $entityManager->createQueryBuilder()
            ->select('b')
            ->from(Booking::class, 'b')
            ->where('b.professional = :professional')
            ->andWhere('b.customer = :customer')
            ->setParameter('professional', $profile)
            ->setParameter('customer', $customer)
            ->orderBy('b.startsAt', 'DESC')
            ->getQuery()
            ->getResult();

        if ($bookings === []) {
            return $this->json([
                'error' => [
                    'code' => 'CLIENT_NOT_FOUND',
                ],
            ], 404);
        }

        $clientNote = $entityManager
            ->getRepository(ProfessionalClientNote::class)
            ->findOneBy([
                'professional' => $profile,
                'customer' => $customer,
            ]);
            
        return $this->json([
            'data' => [
                'client' => [
                    'id' => (string) $customer->getId(),
                    'phoneNumber' => $customer->getPhoneNumber(),
                    'appointmentCount' => count($bookings),
                    'note' => $clientNote?->getNote(),
                    'appointments' => array_map(
                        static fn (Booking $booking): array => [
                            'id' => (string) $booking->getId(),
                            'serviceName' => $booking->getServiceName(),
                            'startsAt' => $booking->getStartsAt()->format(DATE_ATOM),
                            'endsAt' => $booking->getEndsAt()->format(DATE_ATOM),
                            'status' => $booking->getStatus()->value,
                            'priceType' => $booking->getPriceType(),
                            'price' => $booking->getPrice(),
                            'currency' => $booking->getCurrency(),
                            'note' => $booking->getNote(),
                        ],
                        $bookings,
                    ),
                ],
            ],
        ]);
    }

    #[Route('/api/v1/pro/clients/{customerId}/note', methods: ['PUT'])]
    public function updateClientNote(
        string $customerId,
        Request $request,
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json([
                'error' => [
                    'code' => 'UNAUTHENTICATED',
                ],
            ], 401);
        }

        $profile = $profiles->findOneByUser($user);

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json([
                'error' => [
                    'code' => 'PROFILE_REQUIRED',
                ],
            ], 409);
        }

        $customer = $entityManager->find(User::class, $customerId);

        if (!$customer instanceof User) {
            return $this->json([
                'error' => [
                    'code' => 'CLIENT_NOT_FOUND',
                ],
            ], 404);
        }

        $hasRelationship = (int) $entityManager->createQueryBuilder()
            ->select('COUNT(b.id)')
            ->from(Booking::class, 'b')
            ->where('b.professional = :professional')
            ->andWhere('b.customer = :customer')
            ->setParameter('professional', $profile)
            ->setParameter('customer', $customer)
            ->getQuery()
            ->getSingleScalarResult();

        if ($hasRelationship === 0) {
            return $this->json([
                'error' => [
                    'code' => 'CLIENT_NOT_FOUND',
                ],
            ], 404);
        }

        $payload = $request->toArray();
        $noteText = isset($payload['note'])
            ? (string) $payload['note']
            : null;

        $clientNote = $entityManager
            ->getRepository(ProfessionalClientNote::class)
            ->findOneBy([
                'professional' => $profile,
                'customer' => $customer,
            ]);

        if (!$clientNote instanceof ProfessionalClientNote) {
            $clientNote = new ProfessionalClientNote(
                $profile,
                $customer,
                $noteText,
            );

            $entityManager->persist($clientNote);
        } else {
            $clientNote->setNote($noteText);
        }

        $entityManager->flush();

        return $this->json([
            'data' => [
                'note' => [
                    'customerId' => (string) $customer->getId(),
                    'note' => $clientNote->getNote(),
                    'updatedAt' => $clientNote->getUpdatedAt()->format(DATE_ATOM),
                ],
            ],
        ]);
    }
}