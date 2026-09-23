<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260922121226 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE booking (id UUID NOT NULL, starts_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, ends_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, status VARCHAR(40) NOT NULL, service_name VARCHAR(120) NOT NULL, price_type VARCHAR(20) NOT NULL, price NUMERIC(10, 2) DEFAULT NULL, currency VARCHAR(3) NOT NULL, note TEXT DEFAULT NULL, created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, customer_id UUID NOT NULL, professional_id UUID NOT NULL, service_id UUID NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE INDEX IDX_E00CEDDE9395C3F3 ON booking (customer_id)');
        $this->addSql('CREATE INDEX IDX_E00CEDDEDB77003 ON booking (professional_id)');
        $this->addSql('CREATE INDEX IDX_E00CEDDEED5CA9E6 ON booking (service_id)');
        $this->addSql('ALTER TABLE booking ADD CONSTRAINT FK_E00CEDDE9395C3F3 FOREIGN KEY (customer_id) REFERENCES app_user (id) ON DELETE CASCADE NOT DEFERRABLE');
        $this->addSql('ALTER TABLE booking ADD CONSTRAINT FK_E00CEDDEDB77003 FOREIGN KEY (professional_id) REFERENCES professional_profile (id) ON DELETE CASCADE NOT DEFERRABLE');
        $this->addSql('ALTER TABLE booking ADD CONSTRAINT FK_E00CEDDEED5CA9E6 FOREIGN KEY (service_id) REFERENCES professional_service (id) ON DELETE RESTRICT NOT DEFERRABLE');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE booking DROP CONSTRAINT FK_E00CEDDE9395C3F3');
        $this->addSql('ALTER TABLE booking DROP CONSTRAINT FK_E00CEDDEDB77003');
        $this->addSql('ALTER TABLE booking DROP CONSTRAINT FK_E00CEDDEED5CA9E6');
        $this->addSql('DROP TABLE booking');
    }
}
