<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\AvailabilityException;
use App\Entity\Booking;
use App\Entity\ProfessionalProfile;
use App\Entity\ProfessionalService;
use App\Entity\WorkingHours;
use App\Enum\BookingStatus;
use Doctrine\ORM\EntityManagerInterface;

final class AvailabilityService
{
    private const DEFAULT_STEP_MINUTES = 30;
    private const DEFAULT_LOOKAHEAD_DAYS = 14;
    private const TIMEZONE = 'Asia/Ashgabat';

    public function __construct(
        private readonly EntityManagerInterface $entityManager,
    ) {
    }

    /**
     * @return list<array{startsAt: \DateTimeImmutable, endsAt: \DateTimeImmutable}>
     */
    public function getSlots(
        ProfessionalProfile $profile,
        ProfessionalService $service,
        \DateTimeImmutable $day,
        int $stepMinutes = self::DEFAULT_STEP_MINUTES,
    ): array {
        if ($stepMinutes < 1) {
            throw new \InvalidArgumentException('stepMinutes must be greater than zero.');
        }

        $timezone = new \DateTimeZone(self::TIMEZONE);
        $day = $day->setTimezone($timezone)->setTime(0, 0);
        $date = $day->format('Y-m-d');
        $dayEnd = $day->modify('+1 day');
        $dayOfWeek = (int) $day->format('N');

        $workingHours = $this->entityManager
            ->getRepository(WorkingHours::class)
            ->findBy(
                [
                    'professional' => $profile,
                    'dayOfWeek' => $dayOfWeek,
                    'active' => true,
                ],
                ['startTime' => 'ASC'],
            );

        $exceptions = $this->entityManager->createQueryBuilder()
            ->select('a')
            ->from(AvailabilityException::class, 'a')
            ->where('a.professional = :professional')
            ->andWhere('a.startsAt < :dayEnd')
            ->andWhere('a.endsAt > :dayStart')
            ->setParameter('professional', $profile)
            ->setParameter('dayStart', $day)
            ->setParameter('dayEnd', $dayEnd)
            ->orderBy('a.startsAt', 'ASC')
            ->getQuery()
            ->getResult();

        $bookings = $this->entityManager->createQueryBuilder()
            ->select('b')
            ->from(Booking::class, 'b')
            ->where('b.professional = :professional')
            ->andWhere('b.startsAt < :dayEnd')
            ->andWhere('b.endsAt > :dayStart')
            ->andWhere('b.status IN (:statuses)')
            ->setParameter('professional', $profile)
            ->setParameter('dayStart', $day)
            ->setParameter('dayEnd', $dayEnd)
            ->setParameter('statuses', [
                BookingStatus::PENDING,
                BookingStatus::CONFIRMED,
            ])
            ->orderBy('b.startsAt', 'ASC')
            ->getQuery()
            ->getResult();

        $windows = [];

        foreach ($workingHours as $hours) {
            $windows[] = [
                'start' => new \DateTimeImmutable(
                    sprintf('%s %s', $date, $hours->getStartTime()),
                    $timezone,
                ),
                'end' => new \DateTimeImmutable(
                    sprintf('%s %s', $date, $hours->getEndTime()),
                    $timezone,
                ),
            ];
        }

        foreach ($exceptions as $exception) {
            if ($exception->getType() !== 'EXTRA') {
                continue;
            }

            $windows[] = [
                'start' => $exception->getStartsAt()->setTimezone($timezone),
                'end' => $exception->getEndsAt()->setTimezone($timezone),
            ];
        }

        $durationMinutes = $service->getDurationMinutes();
        $now = new \DateTimeImmutable('now', $timezone);
        $slotsByStart = [];

        foreach ($windows as $window) {
            $slotStart = $window['start'];

            while ($slotStart < $window['end']) {
                $slotEnd = $slotStart->modify(sprintf('+%d minutes', $durationMinutes));

                if ($slotEnd > $window['end']) {
                    break;
                }

                if (
                    $slotStart > $now
                    && !$this->isBlocked($slotStart, $slotEnd, $exceptions)
                    && !$this->overlapsBooking($slotStart, $slotEnd, $bookings)
                ) {
                    $slotsByStart[$slotStart->format(DATE_ATOM)] = [
                        'startsAt' => $slotStart,
                        'endsAt' => $slotEnd,
                    ];
                }

                $slotStart = $slotStart->modify(sprintf('+%d minutes', $stepMinutes));
            }
        }

        $slots = array_values($slotsByStart);

        usort(
            $slots,
            static fn (array $a, array $b): int => $a['startsAt'] <=> $b['startsAt'],
        );

        return $slots;
    }

    public function findNextAvailableAt(
        ProfessionalProfile $profile,
        int $daysAhead = self::DEFAULT_LOOKAHEAD_DAYS,
    ): ?\DateTimeImmutable {
        if ($daysAhead < 1) {
            return null;
        }

        $services = $this->entityManager
            ->getRepository(ProfessionalService::class)
            ->findBy([
                'professional' => $profile,
                'active' => true,
            ]);

        if ($services === []) {
            return null;
        }

        $timezone = new \DateTimeZone(self::TIMEZONE);
        $today = new \DateTimeImmutable('today', $timezone);

        for ($dayOffset = 0; $dayOffset < $daysAhead; $dayOffset++) {
            $day = $today->modify(sprintf('+%d days', $dayOffset));
            $earliest = null;

            foreach ($services as $service) {
                $slots = $this->getSlots($profile, $service, $day);

                if ($slots === []) {
                    continue;
                }

                $candidate = $slots[0]['startsAt'];

                if ($earliest === null || $candidate < $earliest) {
                    $earliest = $candidate;
                }
            }

            if ($earliest instanceof \DateTimeImmutable) {
                return $earliest;
            }
        }

        return null;
    }

    /** @param list<AvailabilityException> $exceptions */
    private function isBlocked(
        \DateTimeImmutable $startsAt,
        \DateTimeImmutable $endsAt,
        array $exceptions,
    ): bool {
        foreach ($exceptions as $exception) {
            if (
                $exception->getType() === 'BLOCKED'
                && $exception->getStartsAt() < $endsAt
                && $exception->getEndsAt() > $startsAt
            ) {
                return true;
            }
        }

        return false;
    }

    /** @param list<Booking> $bookings */
    private function overlapsBooking(
        \DateTimeImmutable $startsAt,
        \DateTimeImmutable $endsAt,
        array $bookings,
    ): bool {
        foreach ($bookings as $booking) {
            if (
                $booking->getStartsAt() < $endsAt
                && $booking->getEndsAt() > $startsAt
            ) {
                return true;
            }
        }

        return false;
    }

    public function hasAvailabilityOnDate(
        ProfessionalProfile $profile,
        \DateTimeImmutable $day,
    ): bool {
        $services = $this->entityManager
            ->getRepository(ProfessionalService::class)
            ->findBy([
                'professional' => $profile,
                'active' => true,
            ]);

        foreach ($services as $service) {
            if ($this->getSlots($profile, $service, $day) !== []) {
                return true;
            }
        }

        return false;
    }
}
