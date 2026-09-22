<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20260918000100 extends AbstractMigration
{
    public function getDescription(): string { return 'Owadan Sprint 1 initial identity, location and catalog schema'; }

    public function up(Schema $schema): void
    {
        $this->addSql('CREATE TABLE app_user (id UUID NOT NULL, phone_number VARCHAR(32) NOT NULL, roles JSON NOT NULL, active BOOLEAN DEFAULT TRUE NOT NULL, created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, PRIMARY KEY(id))');
        $this->addSql('CREATE UNIQUE INDEX UNIQ_APP_USER_PHONE ON app_user (phone_number)');
        $this->addSql('CREATE TABLE country (id SERIAL NOT NULL, code VARCHAR(2) NOT NULL, name VARCHAR(120) NOT NULL, PRIMARY KEY(id))');
        $this->addSql('CREATE UNIQUE INDEX UNIQ_COUNTRY_CODE ON country (code)');
        $this->addSql('CREATE TABLE city (id SERIAL NOT NULL, country_id INT NOT NULL, name VARCHAR(120) NOT NULL, PRIMARY KEY(id))');
        $this->addSql('CREATE INDEX IDX_CITY_COUNTRY ON city (country_id)');
        $this->addSql('ALTER TABLE city ADD CONSTRAINT FK_CITY_COUNTRY FOREIGN KEY (country_id) REFERENCES country (id) NOT DEFERRABLE INITIALLY IMMEDIATE');
        $this->addSql('CREATE TABLE district (id SERIAL NOT NULL, city_id INT NOT NULL, name VARCHAR(120) NOT NULL, PRIMARY KEY(id))');
        $this->addSql('CREATE INDEX IDX_DISTRICT_CITY ON district (city_id)');
        $this->addSql('ALTER TABLE district ADD CONSTRAINT FK_DISTRICT_CITY FOREIGN KEY (city_id) REFERENCES city (id) NOT DEFERRABLE INITIALLY IMMEDIATE');
        $this->addSql('CREATE TABLE category (id SERIAL NOT NULL, parent_id INT DEFAULT NULL, slug VARCHAR(80) NOT NULL, name_i18n JSON NOT NULL, active BOOLEAN DEFAULT TRUE NOT NULL, sort_order INT DEFAULT 0 NOT NULL, PRIMARY KEY(id))');
        $this->addSql('CREATE UNIQUE INDEX UNIQ_CATEGORY_SLUG ON category (slug)');
        $this->addSql('CREATE INDEX IDX_CATEGORY_PARENT ON category (parent_id)');
        $this->addSql('ALTER TABLE category ADD CONSTRAINT FK_CATEGORY_PARENT FOREIGN KEY (parent_id) REFERENCES category (id) ON DELETE CASCADE NOT DEFERRABLE INITIALLY IMMEDIATE');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('DROP TABLE category');
        $this->addSql('DROP TABLE district');
        $this->addSql('DROP TABLE city');
        $this->addSql('DROP TABLE country');
        $this->addSql('DROP TABLE app_user');
    }
}
