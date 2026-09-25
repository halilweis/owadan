<?php

declare(strict_types=1);

namespace App\Tests\Api;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class HealthApiTest extends WebTestCase
{
    public function testApplicationIsReachable(): void
    {
        $client = static::createClient();

        $client->request('GET', '/api/v1/categories');

        self::assertResponseIsSuccessful();
    }
}