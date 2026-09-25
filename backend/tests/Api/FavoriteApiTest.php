<?php

declare(strict_types=1);

namespace App\Tests\Api;

use App\Entity\Favorite;
use App\Tests\Support\DatabaseResetTrait;
use App\Tests\Support\FixtureFactory;
use Doctrine\ORM\EntityManagerInterface;
use Lexik\Bundle\JWTAuthenticationBundle\Services\JWTTokenManagerInterface;
use Symfony\Bundle\FrameworkBundle\KernelBrowser;
use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class FavoriteApiTest extends WebTestCase
{
    use DatabaseResetTrait;

    private KernelBrowser $client;
    private EntityManagerInterface $entityManager;
    private JWTTokenManagerInterface $jwt;
    private FixtureFactory $fixtures;

    protected function setUp(): void
    {
        self::ensureKernelShutdown();

        $this->client = static::createClient();
        $this->entityManager = static::getContainer()->get(EntityManagerInterface::class);
        $this->jwt = static::getContainer()->get(JWTTokenManagerInterface::class);

        $this->resetDatabase($this->entityManager);
        $this->fixtures = new FixtureFactory($this->entityManager);
    }

    public function testAddListIdempotentAddAndRemoveFavorite(): void
    {
        $customer = $this->fixtures->createCustomer('+99361003101');

        $professional = $this->fixtures->createProfessionalServiceFixture(
            phoneNumber: '+99361003102',
            displayName: 'Favorite Professional',
            categorySlug: 'favorite-test',
            serviceName: 'Favorite Test Service',
        );

        $token = $this->jwt->create($customer);
        $professionalId = (string) $professional['profile']->getId();

        $this->client->request(
            'POST',
            '/api/v1/me/favorites/' . $professionalId,
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertResponseStatusCodeSame(201);
        $firstFavoriteId = $this->responseJson()['data']['favorite']['id'];

        $this->client->request(
            'POST',
            '/api/v1/me/favorites/' . $professionalId,
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertResponseIsSuccessful();
        self::assertSame(
            $firstFavoriteId,
            $this->responseJson()['data']['favorite']['id'],
        );

        self::assertSame(
            1,
            $this->entityManager->getRepository(Favorite::class)->count([]),
        );

        $this->client->request(
            'GET',
            '/api/v1/me/favorites',
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertResponseIsSuccessful();

        $favorites = $this->responseJson()['data']['favorites'];
        self::assertCount(1, $favorites);
        self::assertSame($professionalId, $favorites[0]['professionalId']);

        $this->client->request(
            'DELETE',
            '/api/v1/me/favorites/' . $professionalId,
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertResponseIsSuccessful();
        self::assertTrue($this->responseJson()['data']['removed']);

        self::assertSame(
            0,
            $this->entityManager->getRepository(Favorite::class)->count([]),
        );
    }

    public function testAddingUnknownProfessionalReturnsNotFound(): void
    {
        $customer = $this->fixtures->createCustomer('+99361003103');
        $token = $this->jwt->create($customer);

        $this->client->request(
            'POST',
            '/api/v1/me/favorites/00000000-0000-0000-0000-000000000001',
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertResponseStatusCodeSame(404);
    }

    /**
     * @return array<string, mixed>
     */
    private function responseJson(): array
    {
        return json_decode(
            $this->client->getResponse()->getContent() ?: '',
            true,
            512,
            JSON_THROW_ON_ERROR,
        );
    }
}
