<?php

declare(strict_types=1);

namespace App\Tests\Api;

use App\Entity\ProfessionalProfile;
use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Lexik\Bundle\JWTAuthenticationBundle\Services\JWTTokenManagerInterface;
use Symfony\Bundle\FrameworkBundle\KernelBrowser;
use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;
use Symfony\Component\HttpFoundation\Response;

final class ProfessionalAuthorizationApiTest extends WebTestCase
{
    private KernelBrowser $client;
    private EntityManagerInterface $entityManager;
    private JWTTokenManagerInterface $jwt;

    protected function setUp(): void
    {
        self::ensureKernelShutdown();

        $this->client = static::createClient();

        $this->entityManager = static::getContainer()
            ->get(EntityManagerInterface::class);

        $this->jwt = static::getContainer()
            ->get(JWTTokenManagerInterface::class);

        $this->entityManager
            ->getConnection()
            ->executeStatement(
                'TRUNCATE TABLE review, booking, working_hours, availability_exception, professional_client_note, professional_service, professional_profile, refresh_token, notification, admin_audit_log, app_user, category RESTART IDENTITY CASCADE'
            );
    }

    public function testCustomerCanAccessProfessionalProfileOnboarding(): void
    {
        $customer = new User('+99361002001');

        $this->entityManager->persist($customer);
        $this->entityManager->flush();

        $token = $this->jwt->create($customer);

        $this->client->request(
            'GET',
            '/api/v1/pro/profile',
            server: [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $token,
            ],
        );

        self::assertResponseIsSuccessful();

        $data = json_decode(
            $this->client->getResponse()->getContent() ?: '',
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        self::assertNull($data['data']['profile'] ?? null);
    }

    public function testOrdinaryCustomerCannotAccessProfessionalOperationalRoutes(): void
    {
        $customer = new User('+99361002002');

        $this->entityManager->persist($customer);
        $this->entityManager->flush();

        $token = $this->jwt->create($customer);

        $this->client->request(
            'GET',
            '/api/v1/pro/bookings',
            server: [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $token,
            ],
        );

        self::assertResponseStatusCodeSame(403);
    }

    public function testProfessionalCanAccessProfessionalOperationalRoutes(): void
    {
        $professionalUser = new User('+99361002003');
        $professionalUser->setRoles([
            'ROLE_CUSTOMER',
            'ROLE_PROFESSIONAL',
        ]);

        $profile = new ProfessionalProfile(
            $professionalUser,
            'Authorization Test Professional',
        );

        $this->entityManager->persist($professionalUser);
        $this->entityManager->persist($profile);
        $this->entityManager->flush();

        $token = $this->jwt->create($professionalUser);

        $this->client->request(
            'GET',
            '/api/v1/pro/bookings',
            server: [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $token,
            ],
        );

        self::assertResponseIsSuccessful();

        $data = json_decode(
            $this->client->getResponse()->getContent() ?: '',
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        self::assertSame(
            [],
            $data['data']['bookings'] ?? null,
        );
    }

    public function testAnonymousUserCannotAccessProfessionalProfile(): void
    {
        $this->client->request(
            'GET',
            '/api/v1/pro/profile',
        );

        self::assertResponseStatusCodeSame(401);
    }

    public function testCreatingProfessionalProfileSignalsTokenRefresh(): void
    {
        $customer = new User('+99361002004');

        $this->entityManager->persist($customer);
        $this->entityManager->flush();

        $token = $this->jwt->create($customer);

        $this->client->jsonRequest(
            'PUT',
            '/api/v1/pro/profile',
            [
                'displayName' => 'New Professional',
                'bio' => 'Test professional profile',
                'experienceYears' => 3,
                'languages' => ['tk', 'ru'],
            ],
            [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $token,
            ],
        );

        self::assertResponseStatusCodeSame(
            Response::HTTP_CREATED
        );

        $data = json_decode(
            $this->client->getResponse()->getContent() ?: '',
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        self::assertTrue(
            $data['data']['auth']['tokenRefreshRequired'] ?? false
        );

        $this->entityManager->clear();

        $updatedUser = $this->entityManager
            ->getRepository(User::class)
            ->findOneBy([
                'phoneNumber' => '+99361002004',
            ]);

        self::assertInstanceOf(User::class, $updatedUser);

        self::assertContains(
            'ROLE_PROFESSIONAL',
            $updatedUser->getRoles(),
        );
    }
}
