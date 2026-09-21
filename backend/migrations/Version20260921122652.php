<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260921122652 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('DROP SEQUENCE country_id_seq CASCADE');
        $this->addSql('DROP SEQUENCE city_id_seq CASCADE');
        $this->addSql('DROP SEQUENCE district_id_seq CASCADE');
        $this->addSql('DROP SEQUENCE category_id_seq CASCADE');
        $this->addSql('ALTER TABLE category DROP CONSTRAINT fk_category_parent');
        $this->addSql('ALTER TABLE city DROP CONSTRAINT fk_city_country');
        $this->addSql('ALTER TABLE district DROP CONSTRAINT fk_district_city');
        $this->addSql('DROP TABLE category');
        $this->addSql('DROP TABLE city');
        $this->addSql('DROP TABLE country');
        $this->addSql('DROP TABLE district');
        $this->addSql('ALTER INDEX uniq_app_user_phone RENAME TO UNIQ_88BDF3E96B01BC5B');
        $this->addSql('DROP INDEX idx_otp_phone_created');
        $this->addSql('ALTER INDEX uniq_refresh_token_hash RENAME TO UNIQ_C74F2195B3BC57DA');
        $this->addSql('ALTER INDEX idx_refresh_token_user RENAME TO IDX_C74F2195A76ED395');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE SEQUENCE country_id_seq INCREMENT BY 1 MINVALUE 1 START 1');
        $this->addSql('CREATE SEQUENCE city_id_seq INCREMENT BY 1 MINVALUE 1 START 1');
        $this->addSql('CREATE SEQUENCE district_id_seq INCREMENT BY 1 MINVALUE 1 START 1');
        $this->addSql('CREATE SEQUENCE category_id_seq INCREMENT BY 1 MINVALUE 1 START 1');
        $this->addSql('CREATE TABLE category (id INT DEFAULT nextval(\'category_id_seq\'::regclass) NOT NULL, parent_id INT DEFAULT NULL, slug VARCHAR(80) NOT NULL, name_i18n JSON NOT NULL, active BOOLEAN DEFAULT true NOT NULL, sort_order INT DEFAULT 0 NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE INDEX idx_category_parent ON category (parent_id)');
        $this->addSql('CREATE UNIQUE INDEX uniq_category_slug ON category (slug)');
        $this->addSql('CREATE TABLE city (id INT DEFAULT nextval(\'city_id_seq\'::regclass) NOT NULL, country_id INT NOT NULL, name VARCHAR(120) NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE INDEX idx_city_country ON city (country_id)');
        $this->addSql('CREATE TABLE country (id INT DEFAULT nextval(\'country_id_seq\'::regclass) NOT NULL, code VARCHAR(2) NOT NULL, name VARCHAR(120) NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE UNIQUE INDEX uniq_country_code ON country (code)');
        $this->addSql('CREATE TABLE district (id INT DEFAULT nextval(\'district_id_seq\'::regclass) NOT NULL, city_id INT NOT NULL, name VARCHAR(120) NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE INDEX idx_district_city ON district (city_id)');
        $this->addSql('ALTER TABLE category ADD CONSTRAINT fk_category_parent FOREIGN KEY (parent_id) REFERENCES category (id) ON DELETE CASCADE NOT DEFERRABLE INITIALLY IMMEDIATE');
        $this->addSql('ALTER TABLE city ADD CONSTRAINT fk_city_country FOREIGN KEY (country_id) REFERENCES country (id) NOT DEFERRABLE INITIALLY IMMEDIATE');
        $this->addSql('ALTER TABLE district ADD CONSTRAINT fk_district_city FOREIGN KEY (city_id) REFERENCES city (id) NOT DEFERRABLE INITIALLY IMMEDIATE');
        $this->addSql('ALTER INDEX uniq_88bdf3e96b01bc5b RENAME TO uniq_app_user_phone');
        $this->addSql('CREATE INDEX idx_otp_phone_created ON otp_challenge (phone_number, created_at)');
        $this->addSql('ALTER INDEX uniq_c74f2195b3bc57da RENAME TO uniq_refresh_token_hash');
        $this->addSql('ALTER INDEX idx_c74f2195a76ed395 RENAME TO idx_refresh_token_user');
    }
}
