<?php

declare(strict_types=1);

namespace App\Tests\Api;

use App\Entity\AdminAuditLog;
use App\Entity\ProfessionalProfile;
use App\Entity\User;
use App\Enum\VerificationStatus;
use App\Tests\Support\DatabaseResetTrait;
use Doctrine\ORM\EntityManagerInterface;
use Lexik\Bundle\JWTAuthenticationBundle\Services\JWTTokenManagerInterface;
use Symfony\Bundle\FrameworkBundle\KernelBrowser;
use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class AdminProfessionalApiTest extends WebTestCase
{
    use DatabaseResetTrait;

    private KernelBrowser $client;
    private EntityManagerInterface $entityManager;
    private JWTTokenManagerInterface $jwt;

    protected function setUp(): void
    {
        self::ensureKernelShutdown();

        $this->client = static::createClient();
        $this->entityManager = static::getContainer()->get(EntityManagerInterface::class);
        $this->jwt = static::getContainer()->get(JWTTokenManagerInterface::class);

        $this->resetDatabase($this->entityManager);
    }

    public function testAdminCanListPendingApproveRejectAndReadAuditLogs(): void
    {
        $admin = new User('+99361003201');
        $admin->setRoles(['ROLE_CUSTOMER', 'ROLE_ADMIN']);

        $firstUser = new User('+99361003202');
        $firstProfile = new ProfessionalProfile($firstUser, 'Approve Me');
        $firstProfile->submitForVerification();

        $secondUser = new User('+99361003203');
        $secondProfile = new ProfessionalProfile($secondUser, 'Reject Me');
        $secondProfile->submitForVerification();

        foreach ([
            $admin,
            $firstUser,
            $firstProfile,
            $secondUser,
            $secondProfile,
        ] as $entity) {
            $this->entityManager->persist($entity);
        }

        $this->entityManager->flush();

        $token = $this->jwt->create($admin);

        $this->client->request(
            'GET',
            '/api/v1/admin/professionals/pending',
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertResponseIsSuccessful();
        self::assertCount(
            2,
            $this->responseJson()['data']['professionals'],
        );

        $this->client->request(
            'POST',
            '/api/v1/admin/professionals/' . $firstProfile->getId() . '/approve',
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertResponseIsSuccessful();
        self::assertSame(
            VerificationStatus::APPROVED->value,
            $this->responseJson()['data']['profile']['verificationStatus'],
        );

        $this->client->request(
            'POST',
            '/api/v1/admin/professionals/' . $secondProfile->getId() . '/reject',
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertResponseIsSuccessful();
        self::assertSame(
            VerificationStatus::REJECTED->value,
            $this->responseJson()['data']['profile']['verificationStatus'],
        );

        self::assertSame(
            2,
            $this->entityManager->getRepository(AdminAuditLog::class)->count([]),
        );

        $this->client->request(
            'GET',
            '/api/v1/admin/audit-logs',
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertResponseIsSuccessful();

        $logs = $this->responseJson()['data']['auditLogs'];
        self::assertCount(2, $logs);

        $actions = array_column($logs, 'action');

        self::assertContains('PROFESSIONAL_APPROVED', $actions);
        self::assertContains('PROFESSIONAL_REJECTED', $actions);
    }

    public function testNonAdminCannotAccessAdminRoutes(): void
    {
        $user = new User('+99361003204');

        $this->entityManager->persist($user);
        $this->entityManager->flush();

        $token = $this->jwt->create($user);

        $this->client->request(
            'GET',
            '/api/v1/admin/professionals/pending',
            server: ['HTTP_AUTHORIZATION' => 'Bearer ' . $token],
        );

        self::assertResponseStatusCodeSame(403);
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
