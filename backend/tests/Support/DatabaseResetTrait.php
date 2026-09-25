<?php

declare(strict_types=1);

namespace App\Tests\Support;

use Doctrine\ORM\EntityManagerInterface;

trait DatabaseResetTrait
{
    private function resetDatabase(EntityManagerInterface $entityManager): void
    {
        $entityManager
            ->getConnection()
            ->executeStatement(
                'TRUNCATE TABLE
                    review,
                    booking,
                    working_hours,
                    availability_exception,
                    professional_client_note,
                    professional_service,
                    professional_profile,
                    refresh_token,
                    notification,
                    admin_audit_log,
                    app_user,
                    category
                 RESTART IDENTITY CASCADE'
            );
    }
}
