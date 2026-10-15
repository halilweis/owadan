<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261015154306 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE booking_message (id UUID NOT NULL, body TEXT NOT NULL, created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, booking_id UUID NOT NULL, sender_id UUID NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE INDEX idx_booking_message_booking_created ON booking_message (booking_id, created_at)');
        $this->addSql('CREATE INDEX IDX_EC03755F3301C60 ON booking_message (booking_id)');
        $this->addSql('CREATE INDEX IDX_EC03755FF624B39D ON booking_message (sender_id)');
        $this->addSql('ALTER TABLE booking_message ADD CONSTRAINT FK_EC03755F3301C60 FOREIGN KEY (booking_id) REFERENCES booking (id) ON DELETE CASCADE NOT DEFERRABLE');
        $this->addSql('ALTER TABLE booking_message ADD CONSTRAINT FK_EC03755FF624B39D FOREIGN KEY (sender_id) REFERENCES app_user (id) ON DELETE CASCADE NOT DEFERRABLE');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE booking_message DROP CONSTRAINT FK_EC03755F3301C60');
        $this->addSql('ALTER TABLE booking_message DROP CONSTRAINT FK_EC03755FF624B39D');
        $this->addSql('DROP TABLE booking_message');
    }
}
