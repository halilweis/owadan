<?php

declare(strict_types=1);

namespace App\Command;

use App\Entity\Booking;
use App\Entity\Notification;
use App\Enum\BookingStatus;
use App\Service\NotificationService;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use App\Entity\User;

#[AsCommand(
    name: 'app:send-appointment-reminders',
    description: 'Creates reminder notifications for upcoming confirmed bookings.',
)]
final class SendAppointmentRemindersCommand extends Command
{
    public function __construct(
        private readonly EntityManagerInterface $entityManager,
        private readonly NotificationService $notifications,
    ) {
        parent::__construct();
    }

    protected function execute(
        InputInterface $input,
        OutputInterface $output,
    ): int {
        $timezone = new \DateTimeZone('Asia/Ashgabat');
        $now = new \DateTimeImmutable('now', $timezone);

        $windowStart = $now->modify('+23 hours');
        $windowEnd = $now->modify('+25 hours');

        $bookings = $this->entityManager->createQueryBuilder()
            ->select('b')
            ->from(Booking::class, 'b')
            ->where('b.status = :status')
            ->andWhere('b.startsAt >= :windowStart')
            ->andWhere('b.startsAt < :windowEnd')
            ->setParameter('status', BookingStatus::CONFIRMED)
            ->setParameter('windowStart', $windowStart)
            ->setParameter('windowEnd', $windowEnd)
            ->getQuery()
            ->getResult();

        $created = 0;

        foreach ($bookings as $booking) {
            if (!$booking instanceof Booking) {
                continue;
            }

            $customer = $booking->getCustomer();
            $professionalUser = $booking->getProfessional()->getUser();

            if (!$this->reminderAlreadyExists($booking, $customer)) {
                $this->notifications->create(
                    $customer,
                    'APPOINTMENT_REMINDER',
                    'Appointment reminder',
                    sprintf(
                        'Your appointment for %s is tomorrow at %s.',
                        $booking->getServiceName(),
                        $booking->getStartsAt()
                            ->setTimezone($timezone)
                            ->format('H:i'),
                    ),
                    [
                        'bookingId' => (string) $booking->getId(),
                        'startsAt' => $booking->getStartsAt()->format(DATE_ATOM),
                    ],
                    $booking->getId(),
                );

                $created++;
            }

            if (!$this->reminderAlreadyExists($booking, $professionalUser)) {
                $this->notifications->create(
                    $professionalUser,
                    'APPOINTMENT_REMINDER',
                    'Appointment reminder',
                    sprintf(
                        'You have an appointment for %s tomorrow at %s.',
                        $booking->getServiceName(),
                        $booking->getStartsAt()
                            ->setTimezone($timezone)
                            ->format('H:i'),
                    ),
                    [
                        'bookingId' => (string) $booking->getId(),
                        'startsAt' => $booking->getStartsAt()->format(DATE_ATOM),
                    ],
                    $booking->getId(),
                );

                $created++;
            }

            $data = [
                'bookingId' => (string) $booking->getId(),
                'startsAt' => $booking->getStartsAt()->format(DATE_ATOM),
            ];

            $this->notifications->create(
                $booking->getCustomer(),
                'APPOINTMENT_REMINDER',
                'Appointment reminder',
                sprintf(
                    'Your appointment for %s is tomorrow at %s.',
                    $booking->getServiceName(),
                    $booking->getStartsAt()
                        ->setTimezone($timezone)
                        ->format('H:i'),
                ),
                $data,
            );

            $this->notifications->create(
                $booking->getProfessional()->getUser(),
                'APPOINTMENT_REMINDER',
                'Appointment reminder',
                sprintf(
                    'You have an appointment for %s tomorrow at %s.',
                    $booking->getServiceName(),
                    $booking->getStartsAt()
                        ->setTimezone($timezone)
                        ->format('H:i'),
                ),
                $data,
            );

            $created += 2;
        }

        $this->entityManager->flush();

        $output->writeln(sprintf(
            'Created %d reminder notification(s).',
            $created,
        ));

        return Command::SUCCESS;
    }

   private function reminderAlreadyExists(
        Booking $booking,
        User $user,
    ): bool {
        return $this->entityManager
            ->getRepository(Notification::class)
            ->findOneBy([
                'user' => $user,
                'type' => 'APPOINTMENT_REMINDER',
                'bookingId' => $booking->getId(),
            ]) instanceof Notification;
    }
}