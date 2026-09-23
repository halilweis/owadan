<?php

declare(strict_types=1);

namespace App\Enum;

enum BookingStatus: string
{
    case PENDING = 'PENDING';
    case CONFIRMED = 'CONFIRMED';
    case DECLINED = 'DECLINED';
    case CANCELLED_BY_CUSTOMER = 'CANCELLED_BY_CUSTOMER';
    case CANCELLED_BY_PROFESSIONAL = 'CANCELLED_BY_PROFESSIONAL';
    case COMPLETED = 'COMPLETED';
    case NO_SHOW = 'NO_SHOW';
}