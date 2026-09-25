<?php

declare(strict_types=1);

namespace App\Tests\Api;

use App\Entity\Review;
use App\Entity\User;
use App\Service\Auth\TokenIssuer;
use App\Tests\Support\DatabaseResetTrait;
use App\Tests\Support\FixtureFactory;
use Doctrine\ORM\EntityManagerInterface;
use Lexik\Bundle\JWTAuthenticationBundle\Services\JWTTokenManagerInterface;
use Symfony\Bundle\FrameworkBundle\KernelBrowser;
use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class HighRiskApiTest extends WebTestCase
{
    use DatabaseResetTrait;

    private EntityManagerInterface $entityManager;
    private KernelBrowser $client;
    private FixtureFactory $fixtures;

    protected function setUp(): void
    {
        self::ensureKernelShutdown();

        $this->client = static::createClient();

        $this->entityManager = static::getContainer()
            ->get(EntityManagerInterface::class);

        $this->resetDatabase($this->entityManager);

        $this->fixtures = new FixtureFactory(
            $this->entityManager,
        );
    }

    public function testRefreshTokenRotationInvalidatesOldToken(): void
    {
        $user = $this->fixtures->createCustomer('+99361000001');

        /** @var TokenIssuer $issuer */
        $issuer = static::getContainer()->get(TokenIssuer::class);

        $first = $issuer->issue($user);

        $this->client->jsonRequest(
            'POST',
            '/api/v1/auth/refresh',
            [
                'refreshToken' => $first['refreshToken'],
            ],
        );

        self::assertResponseIsSuccessful();

        $response = json_decode(
            $this->client->getResponse()->getContent() ?: '',
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        $newRefreshToken = $response['data']['tokens']['refreshToken'];

        self::assertNotSame(
            $first['refreshToken'],
            $newRefreshToken,
        );

        $this->client->jsonRequest(
            'POST',
            '/api/v1/auth/refresh',
            [
                'refreshToken' => $first['refreshToken'],
            ],
        );

        self::assertResponseStatusCodeSame(401);

        $response = json_decode(
            $this->client->getResponse()->getContent() ?: '',
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        self::assertSame(
            'REFRESH_TOKEN_INVALID',
            $response['error']['code'] ?? null,
        );
    }

    public function testLogoutAllRevokesEveryRefreshToken(): void
    {
        $user = $this->fixtures->createCustomer('+99361000002');

        /** @var TokenIssuer $issuer */
        $issuer = static::getContainer()->get(TokenIssuer::class);

        /** @var JWTTokenManagerInterface $jwt */
        $jwt = static::getContainer()->get(
            JWTTokenManagerInterface::class
        );

        $sessionOne = $issuer->issue($user);
        $sessionTwo = $issuer->issue($user);

        $accessToken = $jwt->create($user);

        $this->client->request(
            'POST',
            '/api/v1/auth/logout-all',
            server: [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $accessToken,
            ],
        );

        self::assertResponseIsSuccessful();

        $this->client->jsonRequest(
            'POST',
            '/api/v1/auth/refresh',
            [
                'refreshToken' => $sessionOne['refreshToken'],
            ],
        );

        self::assertResponseStatusCodeSame(401);

        $this->client->jsonRequest(
            'POST',
            '/api/v1/auth/refresh',
            [
                'refreshToken' => $sessionTwo['refreshToken'],
            ],
        );

        self::assertResponseStatusCodeSame(401);
    }

    public function testCustomerCannotReviewAnotherCustomersBooking(): void
    {
        $fixture = $this->fixtures->createCompletedBookingFixture();

        /** @var JWTTokenManagerInterface $jwt */
        $jwt = static::getContainer()->get(
            JWTTokenManagerInterface::class
        );

        $token = $jwt->create(
            $fixture['otherCustomer']
        );

        $this->client->jsonRequest(
            'POST',
            '/api/v1/bookings/' . $fixture['booking']->getId() . '/review',
            [
                'rating' => 5,
                'comment' => 'Should not be allowed',
            ],
            [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $token,
            ],
        );

        self::assertResponseStatusCodeSame(403);

        self::assertNull(
            $this->entityManager
                ->getRepository(Review::class)
                ->findOneBy([
                    'booking' => $fixture['booking'],
                ])
        );
    }

    public function testDuplicateReviewIsRejected(): void
    {
        $fixture = $this->fixtures->createCompletedBookingFixture();

        /** @var JWTTokenManagerInterface $jwt */
        $jwt = static::getContainer()->get(
            JWTTokenManagerInterface::class
        );

        $token = $jwt->create(
            $fixture['customer']
        );

        $this->client->jsonRequest(
            'POST',
            '/api/v1/bookings/' . $fixture['booking']->getId() . '/review',
            [
                'rating' => 5,
                'comment' => 'Excellent',
            ],
            [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $token,
            ],
        );

        self::assertResponseStatusCodeSame(201);

        $this->client->jsonRequest(
            'POST',
            '/api/v1/bookings/' . $fixture['booking']->getId() . '/review',
            [
                'rating' => 4,
                'comment' => 'Duplicate',
            ],
            [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $token,
            ],
        );

        self::assertResponseStatusCodeSame(409);

        $response = json_decode(
            $this->client->getResponse()->getContent() ?: '',
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        self::assertSame(
            'REVIEW_ALREADY_EXISTS',
            $response['error']['code'] ?? null,
        );

        self::assertSame(
            1,
            $this->entityManager
                ->getRepository(Review::class)
                ->count([
                    'booking' => $fixture['booking'],
                ])
        );
    }
}
