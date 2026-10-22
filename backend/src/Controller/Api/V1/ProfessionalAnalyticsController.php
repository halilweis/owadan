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

final class ProfessionalAnalyticsController extends AbstractController
{
    #[Route('/api/v1/pro/analytics', methods: ['GET'])]
    public function analytics(
        ProfessionalProfileRepository $profiles,
        EntityManagerInterface $entityManager,
    ): JsonResponse {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json([
                'error' => ['code' => 'UNAUTHENTICATED'],
            ], 401);
        }

        $profile = $profiles->findOneByUser($user);

        if (!$profile instanceof ProfessionalProfile) {
            return $this->json([
                'error' => ['code' => 'PROFILE_REQUIRED'],
            ], 409);
        }

        $bookings = $entityManager->getRepository(Booking::class)->findBy(
            ['professional' => $profile],
            ['startsAt' => 'ASC'],
        );

        $now = new \DateTimeImmutable();
        $currentMonth = $now->setTime(0, 0)->modify('first day of this month');
        $firstMonth = $currentMonth->modify('-5 months');

        $months = [];

        for ($i = 0; $i < 6; ++$i) {
            $month = $firstMonth->modify(sprintf('+%d months', $i));
            $key = $month->format('Y-m');

            $months[$key] = [
                'key' => $key,
                'label' => $month->format('M'),
                'revenue' => 0.0,
                'completed' => 0,
                'noShows' => 0,
            ];
        }

        $totalCount = count($bookings);
        $completedCount = 0;
        $noShowCount = 0;
        $totalRevenue = 0.0;
        $monthRevenue = 0.0;
        $currency = 'TMT';
        $services = [];

        foreach ($bookings as $booking) {
            if (!$booking instanceof Booking) {
                continue;
            }

            $currency = $booking->getCurrency();

            $serviceName = $booking->getServiceName();

            if (!isset($services[$serviceName])) {
                $services[$serviceName] = [
                    'name' => $serviceName,
                    'bookings' => 0,
                    'completed' => 0,
                    'revenue' => 0.0,
                ];
            }

            ++$services[$serviceName]['bookings'];

            $monthKey = $booking->getStartsAt()->format('Y-m');

            if ($booking->getStatus() === BookingStatus::COMPLETED) {
                ++$completedCount;
                ++$services[$serviceName]['completed'];

                if (isset($months[$monthKey])) {
                    ++$months[$monthKey]['completed'];
                }

                $price = $booking->getPrice() !== null
                    ? (float) $booking->getPrice()
                    : 0.0;

                $totalRevenue += $price;
                $services[$serviceName]['revenue'] += $price;

                if (isset($months[$monthKey])) {
                    $months[$monthKey]['revenue'] += $price;
                }

                if ($monthKey === $currentMonth->format('Y-m')) {
                    $monthRevenue += $price;
                }
            }

            if ($booking->getStatus() === BookingStatus::NO_SHOW) {
                ++$noShowCount;

                if (isset($months[$monthKey])) {
                    ++$months[$monthKey]['noShows'];
                }
            }
        }

        usort(
            $services,
            static function (array $a, array $b): int {
                $revenueCompare = $b['revenue'] <=> $a['revenue'];

                if ($revenueCompare !== 0) {
                    return $revenueCompare;
                }

                return $b['completed'] <=> $a['completed'];
            },
        );

        $topServices = array_slice($services, 0, 5);

        $completionRate = $totalCount > 0
            ? ($completedCount / $totalCount) * 100
            : 0.0;

        $noShowRate = $totalCount > 0
            ? ($noShowCount / $totalCount) * 100
            : 0.0;

        return $this->json([
            'data' => [
                'analytics' => [
                    'currency' => $currency,
                    'totalRevenue' => round($totalRevenue, 2),
                    'monthRevenue' => round($monthRevenue, 2),
                    'completedCount' => $completedCount,
                    'noShowCount' => $noShowCount,
                    'totalCount' => $totalCount,
                    'completionRate' => round($completionRate, 1),
                    'noShowRate' => round($noShowRate, 1),
                    'months' => array_values(array_map(
                        static function (array $month): array {
                            $month['revenue'] = round(
                                (float) $month['revenue'],
                                2,
                            );

                            return $month;
                        },
                        $months,
                    )),
                    'topServices' => array_values(array_map(
                        static function (array $service): array {
                            $service['revenue'] = round(
                                (float) $service['revenue'],
                                2,
                            );

                            return $service;
                        },
                        $topServices,
                    )),
                ],
            ],
        ]);
    }
}