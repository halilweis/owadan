<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20260930154500 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Add editable customer display name and preferred language';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('ALTER TABLE app_user ADD display_name VARCHAR(120) DEFAULT NULL');
        $this->addSql("ALTER TABLE app_user ADD preferred_language VARCHAR(2) DEFAULT 'en' NOT NULL");
    }

    public function down(Schema $schema): void
    {
        $this->addSql('ALTER TABLE app_user DROP display_name');
        $this->addSql('ALTER TABLE app_user DROP preferred_language');
    }
}
