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

final class AuthController extends AbstractController
{
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
