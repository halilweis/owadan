<?php
namespace App\Tests\Controller;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class HealthControllerTest extends WebTestCase
{
    public function testHealth(): void
    {
        $client = static::createClient();
        $client->request('GET', '/health');
        self::assertResponseIsSuccessful();
        self::assertJsonStringEqualsJsonString('{"status":"ok","service":"owadan-api"}', $client->getResponse()->getContent());
    }
}
