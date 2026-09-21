<?php
namespace App\Service\Auth;

final class DevelopmentOtpService
{
    private const CODE = '123456';

    public function request(string $phoneNumber): string
    {
        // Sprint 1 only. Replace with SMS provider and server-side OTP storage/expiry.
        return self::CODE;
    }

    public function verify(string $phoneNumber, string $code): bool
    {
        return hash_equals(self::CODE, $code);
    }
}
