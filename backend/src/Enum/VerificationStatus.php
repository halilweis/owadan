<?php

declare(strict_types=1);

namespace App\Enum;

enum VerificationStatus: string
{
    case DRAFT = 'DRAFT';
    case PENDING = 'PENDING';
    case VERIFIED = 'VERIFIED';
    case REJECTED = 'REJECTED';
}
