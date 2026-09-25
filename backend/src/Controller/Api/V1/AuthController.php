<?php

declare(strict_types=1);

namespace App\Controller\Api\V1;

use App\Entity\User;
use App\Repository\UserRepository;
use App\Service\Auth\OtpManager;
use App\Service\Auth\TokenIssuer;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;
use OpenApi\Attributes as OA;

final class AuthController extends AbstractController
{

    #[OA\Post(
        path: '/api/v1/auth/request-otp',
        summary: 'Request an OTP',
        tags: ['Authentication'],
        security: [],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['phoneNumber'],
                properties: [
                    new OA\Property(
                        property: 'phoneNumber',
                        type: 'string',
                        example: '+99361123456'
                    ),
                ],
            ),
        ),
        responses: [
            new OA\Response(response: 202, description: 'OTP requested'),
            new OA\Response(response: 422, description: 'Invalid phone number'),
        ],
    )]

    #[Route('/api/v1/auth/request-otp', methods: ['POST'])]
    public function requestOtp(
        Request $request,
        OtpManager $otp,
        #[Autowire('%kernel.environment%')] string $environment,
    ): JsonResponse {
        $payload = $request->toArray();
        $phone = $this->normalizePhone((string) ($payload['phoneNumber'] ?? ''));

        if ($phone === null) {
            return $this->validationError('phoneNumber must use international format, for example +9936XXXXXXX');
        }

        $code = $otp->request($phone);
        $data = ['requested' => true, 'expiresIn' => 300];

        if ($environment === 'dev') {
            $data['developmentCode'] = $code;
        }

        return $this->json(['data' => $data], 202);
    }

    #[OA\Post(
        path: '/api/v1/auth/verify-otp',
        summary: 'Verify OTP and sign in',
        tags: ['Authentication'],
        security: [],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['phoneNumber', 'code'],
                properties: [
                    new OA\Property(
                        property: 'phoneNumber',
                        type: 'string',
                        example: '+99361123456'
                    ),
                    new OA\Property(
                        property: 'code',
                        type: 'string',
                        example: '123456'
                    ),
                ],
            ),
        ),
        responses: [
            new OA\Response(response: 200, description: 'Authenticated'),
            new OA\Response(response: 401, description: 'OTP invalid or expired'),
            new OA\Response(response: 403, description: 'User disabled'),
            new OA\Response(response: 422, description: 'Validation error'),
        ],
    )]

    #[Route('/api/v1/auth/verify-otp', methods: ['POST'])]
    public function verifyOtp(
        Request $request,
        OtpManager $otp,
        UserRepository $users,
        EntityManagerInterface $entityManager,
        TokenIssuer $tokens,
    ): JsonResponse {
        $payload = $request->toArray();
        $phone = $this->normalizePhone((string) ($payload['phoneNumber'] ?? ''));
        $code = trim((string) ($payload['code'] ?? ''));

        if ($phone === null || $code === '') {
            return $this->validationError('phoneNumber and code are required');
        }

        if (!$otp->verify($phone, $code)) {
            return $this->json(['error' => [
                'code' => 'OTP_INVALID',
                'message' => 'OTP is invalid, expired, consumed, or has too many attempts.',
            ]], 401);
        }

        $user = $users->findOneBy(['phoneNumber' => $phone]);
        if (!$user instanceof User) {
            $user = new User($phone);
            $entityManager->persist($user);
            $entityManager->flush();
        }

        if (!$user->isActive()) {
            return $this->json(['error' => ['code' => 'USER_DISABLED', 'message' => 'This account is disabled.']], 403);
        }

        return $this->json(['data' => [
            'user' => $this->userPayload($user),
            'tokens' => $tokens->issue($user),
        ]]);
    }

    #[OA\Post(
        path: '/api/v1/auth/refresh',
        summary: 'Rotate refresh token',
        tags: ['Authentication'],
        security: [],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['refreshToken'],
                properties: [
                    new OA\Property(
                        property: 'refreshToken',
                        type: 'string'
                    ),
                ],
            ),
        ),
        responses: [
            new OA\Response(response: 200, description: 'New token pair issued'),
            new OA\Response(response: 401, description: 'Refresh token invalid or expired'),
            new OA\Response(response: 422, description: 'Refresh token missing'),
        ],
    )]

    #[Route('/api/v1/auth/refresh', methods: ['POST'])]
    public function refresh(Request $request, TokenIssuer $tokens): JsonResponse
    {
        $payload = $request->toArray();
        $refreshToken = trim((string) ($payload['refreshToken'] ?? ''));

        if ($refreshToken === '') {
            return $this->validationError('refreshToken is required');
        }

        $issued = $tokens->rotate($refreshToken);
        if ($issued === null) {
            return $this->json(['error' => ['code' => 'REFRESH_TOKEN_INVALID', 'message' => 'Refresh token is invalid or expired.']], 401);
        }

        return $this->json(['data' => ['tokens' => $issued]]);
    }

    #[OA\Post(
        path: '/api/v1/auth/logout',
        summary: 'Logout current refresh-token session',
        tags: ['Authentication'],
        security: [],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['refreshToken'],
                properties: [
                    new OA\Property(
                        property: 'refreshToken',
                        type: 'string'
                    ),
                ],
            ),
        ),
        responses: [
            new OA\Response(response: 200, description: 'Logged out'),
            new OA\Response(response: 422, description: 'Refresh token missing'),
        ],
    )]

    #[Route('/api/v1/auth/logout', methods: ['POST'])]
    public function logout(Request $request, TokenIssuer $tokens): JsonResponse
    {
        $payload = $request->toArray();
        $refreshToken = trim((string) ($payload['refreshToken'] ?? ''));

        if ($refreshToken === '') {
            return $this->validationError('refreshToken is required');
        }

        $tokens->revoke($refreshToken);

        return $this->json(['data' => ['loggedOut' => true]]);
    }

    #[Route('/api/v1/me', methods: ['GET'])]
    public function me(): JsonResponse
    {
        $user = $this->getUser();
        if (!$user instanceof User) {
            return $this->json(['error' => ['code' => 'UNAUTHENTICATED', 'message' => 'Authentication required.']], 401);
        }

        return $this->json(['data' => ['user' => $this->userPayload($user)]]);
    }

    private function normalizePhone(string $phone): ?string
    {
        $phone = preg_replace('/[\s()-]+/', '', trim($phone)) ?? '';

        return preg_match('/^\+[1-9]\d{7,14}$/', $phone) === 1 ? $phone : null;
    }

    private function validationError(string $message): JsonResponse
    {
        return $this->json(['error' => ['code' => 'VALIDATION_ERROR', 'message' => $message]], 422);
    }

    /** @return array{id:string,phoneNumber:string,roles:array<int,string>} */
    private function userPayload(User $user): array
    {
        return [
            'id' => $user->getId()->toRfc4122(),
            'phoneNumber' => $user->getPhoneNumber(),
            'roles' => $user->getRoles(),
        ];
    }

    #[OA\Post(
        path: '/api/v1/auth/logout-all',
        summary: 'Logout from all devices',
        tags: ['Authentication'],
        security: [['Bearer' => []]],
        responses: [
            new OA\Response(response: 200, description: 'All refresh-token sessions revoked'),
            new OA\Response(response: 401, description: 'Authentication required'),
        ],
    )]

    #[Route('/api/v1/auth/logout-all', methods: ['POST'])]
    public function logoutAll(TokenIssuer $tokens): JsonResponse
    {
        $user = $this->getUser();

        if (!$user instanceof User) {
            return $this->json([
                'error' => [
                    'code' => 'UNAUTHENTICATED',
                    'message' => 'Authentication required.',
                ],
            ], 401);
        }

        $revoked = $tokens->revokeAll($user);

        return $this->json([
            'data' => [
                'loggedOutAll' => true,
                'revokedSessions' => $revoked,
            ],
        ]);
    }
}
