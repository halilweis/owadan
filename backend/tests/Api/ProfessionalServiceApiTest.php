<?php

declare(strict_types=1);

namespace App\Tests\Api;

use App\Entity\ProfessionalService;
use App\Tests\Support\DatabaseResetTrait;
use App\Tests\Support\FixtureFactory;
use Doctrine\ORM\EntityManagerInterface;
use Lexik\Bundle\JWTAuthenticationBundle\Services\JWTTokenManagerInterface;
use Symfony\Bundle\FrameworkBundle\KernelBrowser;
use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class ProfessionalServiceApiTest extends WebTestCase
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

    public function testProfessionalCanCreateAndUpdateOwnService(): void
    {
        $professional = $this->fixtures->createProfessionalServiceFixture(
            phoneNumber: '+99361003301',
            displayName: 'Service Professional',
            categorySlug: 'service-test',
            serviceName: 'Existing Service',
        );

        $professional['user']->setRoles([
            'ROLE_CUSTOMER',
            'ROLE_PROFESSIONAL',
        ]);
        $this->entityManager->flush();

        $token = $this->jwt->create($professional['user']);

        $this->client->jsonRequest(
            'POST',
            '/api/v1/pro/services',
            [
                'categoryId' => $professional['category']->getId(),
                'name' => 'New Service',
                'description' => 'Created by integration test',
                'durationMinutes' => 45,
                'priceType' => 'FIXED',
                'price' => '150.00',
                'active' => true,
            ],
            [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $token,
            ],
        );

        self::assertResponseStatusCodeSame(201);

        $serviceId = $this->responseJson()['data']['service']['id'];

        $this->client->jsonRequest(
            'PUT',
            '/api/v1/pro/services/' . $serviceId,
            [
                'categoryId' => $professional['category']->getId(),
                'name' => 'Updated Service',
                'description' => 'Updated description',
                'durationMinutes' => 60,
                'priceType' => 'FROM',
                'price' => '175.00',
                'active' => true,
            ],
            [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $token,
            ],
        );

        self::assertResponseIsSuccessful();

        $servicePayload = $this->responseJson()['data']['service'];

        self::assertSame('Updated Service', $servicePayload['name']);
        self::assertSame('FROM', $servicePayload['priceType']);
        self::assertSame('175.00', $servicePayload['price']);

        self::assertSame(
            2,
            $this->entityManager->getRepository(ProfessionalService::class)->count([]),
        );
    }

    public function testServiceValidationRejectsInvalidDuration(): void
    {
        $professional = $this->fixtures->createProfessionalServiceFixture(
            phoneNumber: '+99361003302',
            displayName: 'Validation Professional',
            categorySlug: 'service-validation',
            serviceName: 'Existing Service',
        );

        $professional['user']->setRoles([
            'ROLE_CUSTOMER',
            'ROLE_PROFESSIONAL',
        ]);
        $this->entityManager->flush();

        $token = $this->jwt->create($professional['user']);

        $this->client->jsonRequest(
            'POST',
            '/api/v1/pro/services',
            [
                'categoryId' => $professional['category']->getId(),
                'name' => 'Invalid Duration',
                'durationMinutes' => 1,
                'priceType' => 'FIXED',
                'price' => '100.00',
            ],
            [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $token,
            ],
        );

        self::assertResponseStatusCodeSame(422);
        self::assertSame(
            'VALIDATION_ERROR',
            $this->responseJson()['error']['code'],
        );
    }

    public function testProfessionalCannotUpdateAnotherProfessionalsService(): void
    {
        $owner = $this->fixtures->createProfessionalServiceFixture(
            phoneNumber: '+99361003303',
            displayName: 'Owner Professional',
            categorySlug: 'owner-service',
            serviceName: 'Owner Service',
        );

        $other = $this->fixtures->createProfessionalServiceFixture(
            phoneNumber: '+99361003304',
            displayName: 'Other Professional',
            categorySlug: 'other-service',
            serviceName: 'Other Service',
        );

        $other['user']->setRoles([
            'ROLE_CUSTOMER',
            'ROLE_PROFESSIONAL',
        ]);
        $this->entityManager->flush();

        $token = $this->jwt->create($other['user']);

        $this->client->jsonRequest(
            'PUT',
            '/api/v1/pro/services/' . $owner['service']->getId(),
            [
                'categoryId' => $other['category']->getId(),
                'name' => 'Unauthorized Update',
                'durationMinutes' => 60,
                'priceType' => 'FIXED',
                'price' => '999.00',
                'active' => true,
            ],
            [
                'HTTP_AUTHORIZATION' => 'Bearer ' . $token,
            ],
        );

        self::assertResponseStatusCodeSame(404);
        self::assertSame(
            'SERVICE_NOT_FOUND',
            $this->responseJson()['error']['code'],
        );
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
