<?php
namespace App\Controller\Api\V1;

use App\Entity\User;
use App\Repository\UserRepository;
use App\Service\Auth\DevelopmentOtpService;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

final class AuthController extends AbstractController
{
    #[Route('/api/v1/auth/request-otp', methods:['POST'])]
    public function requestOtp(Request $request, DevelopmentOtpService $otp, #[Autowire('%kernel.environment%')] string $environment): JsonResponse
    {
        $payload = $request->toArray();
        $phone = trim((string)($payload['phoneNumber'] ?? ''));
        if ($phone === '') {
            return $this->json(['error' => ['code' => 'VALIDATION_ERROR', 'message' => 'phoneNumber is required']], 422);
        }
        $code = $otp->request($phone);
        $data = ['requested' => true];
        if ($environment === 'dev') { $data['developmentCode'] = $code; }
        return $this->json(['data' => $data]);
    }

    #[Route('/api/v1/auth/verify-otp', methods:['POST'])]
    public function verifyOtp(Request $request, DevelopmentOtpService $otp, UserRepository $users, EntityManagerInterface $em): JsonResponse
    {
        $payload = $request->toArray();
        $phone = trim((string)($payload['phoneNumber'] ?? ''));
        $code = trim((string)($payload['code'] ?? ''));
        if ($phone === '' || $code === '') {
            return $this->json(['error' => ['code' => 'VALIDATION_ERROR', 'message' => 'phoneNumber and code are required']], 422);
        }
        if (!$otp->verify($phone, $code)) {
            return $this->json(['error' => ['code' => 'OTP_INVALID', 'message' => 'Invalid OTP code']], 401);
        }
        $user = $users->findOneBy(['phoneNumber' => $phone]);
        if (!$user) {
            $user = new User($phone);
            $em->persist($user);
            $em->flush();
        }
        // JWT issuance is the next auth hardening task; this confirms identity skeleton only.
        return $this->json(['data' => [
            'user' => ['id' => $user->getId()->toRfc4122(), 'phoneNumber' => $user->getPhoneNumber(), 'roles' => $user->getRoles()],
            'authStage' => 'otp_verified'
        ]]);
    }
}
