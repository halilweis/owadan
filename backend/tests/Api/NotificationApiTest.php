<?php

declare(strict_types=1);

namespace App\Tests\Api;

use App\Entity\Notification;
use App\Entity\User;
use App\Tests\Support\DatabaseResetTrait;
use App\Tests\Support\FixtureFactory;
use Doctrine\ORM\EntityManagerInterface;
use Lexik\Bundle\JWTAuthenticationBundle\Services\JWTTokenManagerInterface;
use Symfony\Bundle\FrameworkBundle\KernelBrowser;
use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class NotificationApiTest extends WebTestCase
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

    public function testListUnreadCountMarkReadAndReadAll(): void
    {
        $user = $this->fixtures->createCustomer('+99361003001');

        $first = new Notification(
            $user,
            'TEST_ONE',
            'First notification',
            'First message',
            ['source' => 'test'],
        );

        $second = new Notification(
            $user,
            'TEST_TWO',
            'Second notification',
        );

        $this->entityManager->persist($first);
        $this->entityManager->persist($second);
        $this->entityManager->flush();

        $token = $this->jwt->create($user);

        $this->client->request(
            'GET',
            '/api/v1/me/notifications',
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertResponseIsSuccessful();

        $payload = $this->responseJson();
        self::assertCount(2, $payload['data']['notifications']);

        $this->client->request(
            'GET',
            '/api/v1/me/notifications/unread-count',
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertResponseIsSuccessful();
        self::assertSame(2, $this->responseJson()['data']['unreadCount']);

        $this->client->request(
            'POST',
            '/api/v1/me/notifications/' . $first->getId() . '/read',
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertResponseIsSuccessful();

        $this->client->request(
            'GET',
            '/api/v1/me/notifications/unread-count',
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertSame(1, $this->responseJson()['data']['unreadCount']);

        $this->client->request(
            'POST',
            '/api/v1/me/notifications/read-all',
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertResponseIsSuccessful();
        self::assertSame(1, $this->responseJson()['data']['updated']);

        $this->client->request(
            'GET',
            '/api/v1/me/notifications/unread-count',
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertSame(0, $this->responseJson()['data']['unreadCount']);
    }

    public function testUserCannotMarkAnotherUsersNotificationRead(): void
    {
        $owner = $this->fixtures->createCustomer('+99361003002');
        $other = $this->fixtures->createCustomer('+99361003003');

        $notification = new Notification(
            $owner,
            'PRIVATE',
            'Private notification',
        );

        $this->entityManager->persist($notification);
        $this->entityManager->flush();

        $token = $this->jwt->create($other);

        $this->client->request(
            'POST',
            '/api/v1/me/notifications/' . $notification->getId() . '/read',
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertResponseStatusCodeSame(403);

        $this->entityManager->refresh($notification);
        self::assertFalse($notification->isRead());
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
