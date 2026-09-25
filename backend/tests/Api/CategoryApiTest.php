<?php

declare(strict_types=1);

namespace App\Tests\Api;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class CategoryApiTest extends WebTestCase
{
    public function testCategoriesEndpointReturnsJson(): void
    {
        $client = static::createClient();

        $client->request('GET', '/api/v1/categories');

        self::assertResponseIsSuccessful();
        self::assertResponseHeaderSame(
            'content-type',
            'application/json'
        );

        $data = json_decode(
            $client->getResponse()->getContent() ?: '',
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        self::assertArrayHasKey('data', $data);
        self::assertIsArray($data['data']);
    }
}