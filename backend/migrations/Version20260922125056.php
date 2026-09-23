<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260922125056 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('CREATE EXTENSION IF NOT EXISTS btree_gist');

        $this->addSql("
            ALTER TABLE booking
            ADD CONSTRAINT booking_no_professional_overlap
            EXCLUDE USING gist (
                professional_id WITH =,
                tsrange(starts_at, ends_at, '[)') WITH &&
            )
            WHERE (status IN ('PENDING', 'CONFIRMED'))
        ");

    }

    public function down(Schema $schema): void
    {
        $this->addSql('ALTER TABLE booking DROP CONSTRAINT IF EXISTS booking_no_professional_overlap');

    }
}
