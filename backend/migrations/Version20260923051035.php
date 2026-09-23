<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260923051035 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE favorite (id UUID NOT NULL, created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, customer_id UUID NOT NULL, professional_id UUID NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE UNIQUE INDEX uniq_favorite_customer_professional ON favorite (customer_id, professional_id)');
        $this->addSql('CREATE INDEX IDX_68C58ED99395C3F3 ON favorite (customer_id)');
        $this->addSql('CREATE INDEX IDX_68C58ED9DB77003 ON favorite (professional_id)');
        $this->addSql('CREATE TABLE review (id UUID NOT NULL, rating SMALLINT NOT NULL, comment TEXT DEFAULT NULL, created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, booking_id UUID NOT NULL, customer_id UUID NOT NULL, professional_id UUID NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE UNIQUE INDEX uniq_review_booking ON review (booking_id)');
        $this->addSql('CREATE INDEX IDX_794381C69395C3F3 ON review (customer_id)');
        $this->addSql('CREATE INDEX IDX_794381C6DB77003 ON review (professional_id)');
        $this->addSql('ALTER TABLE favorite ADD CONSTRAINT FK_68C58ED99395C3F3 FOREIGN KEY (customer_id) REFERENCES app_user (id) ON DELETE CASCADE NOT DEFERRABLE');
        $this->addSql('ALTER TABLE favorite ADD CONSTRAINT FK_68C58ED9DB77003 FOREIGN KEY (professional_id) REFERENCES professional_profile (id) ON DELETE CASCADE NOT DEFERRABLE');
        $this->addSql('ALTER TABLE review ADD CONSTRAINT FK_794381C63301C60 FOREIGN KEY (booking_id) REFERENCES booking (id) ON DELETE CASCADE NOT DEFERRABLE');
        $this->addSql('ALTER TABLE review ADD CONSTRAINT FK_794381C69395C3F3 FOREIGN KEY (customer_id) REFERENCES app_user (id) ON DELETE CASCADE NOT DEFERRABLE');
        $this->addSql('ALTER TABLE review ADD CONSTRAINT FK_794381C6DB77003 FOREIGN KEY (professional_id) REFERENCES professional_profile (id) ON DELETE CASCADE NOT DEFERRABLE');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE favorite DROP CONSTRAINT FK_68C58ED99395C3F3');
        $this->addSql('ALTER TABLE favorite DROP CONSTRAINT FK_68C58ED9DB77003');
        $this->addSql('ALTER TABLE review DROP CONSTRAINT FK_794381C63301C60');
        $this->addSql('ALTER TABLE review DROP CONSTRAINT FK_794381C69395C3F3');
        $this->addSql('ALTER TABLE review DROP CONSTRAINT FK_794381C6DB77003');
        $this->addSql('DROP TABLE favorite');
        $this->addSql('DROP TABLE review');
    }
}
