<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260924111356 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE professional_client_note (id UUID NOT NULL, note TEXT DEFAULT NULL, updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, professional_id UUID NOT NULL, customer_id UUID NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE UNIQUE INDEX uniq_professional_client_note ON professional_client_note (professional_id, customer_id)');
        $this->addSql('CREATE INDEX IDX_ACAB5F26DB77003 ON professional_client_note (professional_id)');
        $this->addSql('CREATE INDEX IDX_ACAB5F269395C3F3 ON professional_client_note (customer_id)');
        $this->addSql('ALTER TABLE professional_client_note ADD CONSTRAINT FK_ACAB5F26DB77003 FOREIGN KEY (professional_id) REFERENCES professional_profile (id) ON DELETE CASCADE NOT DEFERRABLE');
        $this->addSql('ALTER TABLE professional_client_note ADD CONSTRAINT FK_ACAB5F269395C3F3 FOREIGN KEY (customer_id) REFERENCES app_user (id) ON DELETE CASCADE NOT DEFERRABLE');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE professional_client_note DROP CONSTRAINT FK_ACAB5F26DB77003');
        $this->addSql('ALTER TABLE professional_client_note DROP CONSTRAINT FK_ACAB5F269395C3F3');
        $this->addSql('DROP TABLE professional_client_note');
    }
}
