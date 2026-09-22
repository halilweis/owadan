<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260922115845 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE availability_exception (id UUID NOT NULL, starts_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, ends_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, type VARCHAR(20) NOT NULL, note TEXT DEFAULT NULL, professional_id UUID NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE INDEX IDX_5E25FABDB77003 ON availability_exception (professional_id)');
        $this->addSql('CREATE TABLE portfolio_item (id UUID NOT NULL, image_url VARCHAR(255) NOT NULL, title VARCHAR(160) DEFAULT NULL, description TEXT DEFAULT NULL, featured BOOLEAN DEFAULT false NOT NULL, active BOOLEAN DEFAULT true NOT NULL, created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, professional_id UUID NOT NULL, service_id UUID DEFAULT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE INDEX IDX_2F2A62E4DB77003 ON portfolio_item (professional_id)');
        $this->addSql('CREATE INDEX IDX_2F2A62E4ED5CA9E6 ON portfolio_item (service_id)');
        $this->addSql('CREATE TABLE working_hours (id UUID NOT NULL, day_of_week SMALLINT NOT NULL, start_time VARCHAR(5) NOT NULL, end_time VARCHAR(5) NOT NULL, active BOOLEAN DEFAULT true NOT NULL, professional_id UUID NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE INDEX IDX_D72CDC3DDB77003 ON working_hours (professional_id)');
        $this->addSql('ALTER TABLE availability_exception ADD CONSTRAINT FK_5E25FABDB77003 FOREIGN KEY (professional_id) REFERENCES professional_profile (id) ON DELETE CASCADE NOT DEFERRABLE');
        $this->addSql('ALTER TABLE portfolio_item ADD CONSTRAINT FK_2F2A62E4DB77003 FOREIGN KEY (professional_id) REFERENCES professional_profile (id) ON DELETE CASCADE NOT DEFERRABLE');
        $this->addSql('ALTER TABLE portfolio_item ADD CONSTRAINT FK_2F2A62E4ED5CA9E6 FOREIGN KEY (service_id) REFERENCES professional_service (id) ON DELETE SET NULL NOT DEFERRABLE');
        $this->addSql('ALTER TABLE working_hours ADD CONSTRAINT FK_D72CDC3DDB77003 FOREIGN KEY (professional_id) REFERENCES professional_profile (id) ON DELETE CASCADE NOT DEFERRABLE');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE availability_exception DROP CONSTRAINT FK_5E25FABDB77003');
        $this->addSql('ALTER TABLE portfolio_item DROP CONSTRAINT FK_2F2A62E4DB77003');
        $this->addSql('ALTER TABLE portfolio_item DROP CONSTRAINT FK_2F2A62E4ED5CA9E6');
        $this->addSql('ALTER TABLE working_hours DROP CONSTRAINT FK_D72CDC3DDB77003');
        $this->addSql('DROP TABLE availability_exception');
        $this->addSql('DROP TABLE portfolio_item');
        $this->addSql('DROP TABLE working_hours');
    }
}
