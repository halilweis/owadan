<?php

declare(strict_types=1);

namespace App\Tests\Api;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class AuthApiTest extends WebTestCase
{
    public function testInvalidPhoneNumberIsRejected(): void
    {
        $client = static::createClient();

        $client->jsonRequest(
            'POST',
            '/api/v1/auth/request-otp',
            [
                'phoneNumber' => '123',
            ],
        );

        self::assertResponseStatusCodeSame(422);

        $data = json_decode(
            $client->getResponse()->getContent() ?: '',
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        self::assertSame(
            'VALIDATION_ERROR',
            $data['error']['code'] ?? null,
        );
    }

    public function testRefreshWithoutTokenIsRejected(): void
    {
        $client = static::createClient();

        $client->jsonRequest(
            'POST',
            '/api/v1/auth/refresh',
            [],
        );

        self::assertResponseStatusCodeSame(422);

        $data = json_decode(
            $client->getResponse()->getContent() ?: '',
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        self::assertSame(
            'VALIDATION_ERROR',
            $data['error']['code'] ?? null,
        );
    }

    public function testInvalidRefreshTokenIsRejected(): void
    {
        $client = static::createClient();

        $client->jsonRequest(
            'POST',
            '/api/v1/auth/refresh',
            [
                'refreshToken' => 'invalid-refresh-token',
            ],
        );

        self::assertResponseStatusCodeSame(401);

        $data = json_decode(
            $client->getResponse()->getContent() ?: '',
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        self::assertSame(
            'REFRESH_TOKEN_INVALID',
            $data['error']['code'] ?? null,
        );
    }
}