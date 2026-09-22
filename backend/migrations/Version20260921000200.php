<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20260921000200 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Add professional profiles and professional services';
    }

    public function up(Schema $schema): void
    {
        $this->addSql("CREATE TABLE professional_profile (id UUID NOT NULL, user_id UUID NOT NULL, district_id INT DEFAULT NULL, display_name VARCHAR(120) NOT NULL, bio TEXT DEFAULT NULL, experience_years SMALLINT DEFAULT NULL, languages JSON NOT NULL, verification_status VARCHAR(20) NOT NULL, active BOOLEAN DEFAULT TRUE NOT NULL, created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, PRIMARY KEY(id))");
        $this->addSql('CREATE UNIQUE INDEX UNIQ_PROFESSIONAL_PROFILE_USER ON professional_profile (user_id)');
        $this->addSql('CREATE INDEX IDX_PROFESSIONAL_PROFILE_DISTRICT ON professional_profile (district_id)');
        $this->addSql("COMMENT ON COLUMN professional_profile.id IS '(DC2Type:uuid)'");
        $this->addSql('ALTER TABLE professional_profile ADD CONSTRAINT FK_PROFESSIONAL_PROFILE_USER FOREIGN KEY (user_id) REFERENCES app_user (id) ON DELETE CASCADE NOT DEFERRABLE INITIALLY IMMEDIATE');
        $this->addSql('ALTER TABLE professional_profile ADD CONSTRAINT FK_PROFESSIONAL_PROFILE_DISTRICT FOREIGN KEY (district_id) REFERENCES district (id) ON DELETE SET NULL NOT DEFERRABLE INITIALLY IMMEDIATE');

        $this->addSql("CREATE TABLE professional_service (id UUID NOT NULL, professional_id UUID NOT NULL, category_id INT NOT NULL, name VARCHAR(120) NOT NULL, description TEXT DEFAULT NULL, duration_minutes SMALLINT NOT NULL, price_type VARCHAR(20) NOT NULL, price NUMERIC(12, 2) DEFAULT NULL, currency VARCHAR(3) NOT NULL, active BOOLEAN DEFAULT TRUE NOT NULL, created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, PRIMARY KEY(id))");
        $this->addSql('CREATE INDEX IDX_PROFESSIONAL_SERVICE_PROFESSIONAL ON professional_service (professional_id)');
        $this->addSql('CREATE INDEX IDX_PROFESSIONAL_SERVICE_CATEGORY ON professional_service (category_id)');
        $this->addSql("COMMENT ON COLUMN professional_service.id IS '(DC2Type:uuid)'");
        $this->addSql('ALTER TABLE professional_service ADD CONSTRAINT FK_PROFESSIONAL_SERVICE_PROFESSIONAL FOREIGN KEY (professional_id) REFERENCES professional_profile (id) ON DELETE CASCADE NOT DEFERRABLE INITIALLY IMMEDIATE');
        $this->addSql('ALTER TABLE professional_service ADD CONSTRAINT FK_PROFESSIONAL_SERVICE_CATEGORY FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE RESTRICT NOT DEFERRABLE INITIALLY IMMEDIATE');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('DROP TABLE professional_service');
        $this->addSql('DROP TABLE professional_profile');
    }
}
