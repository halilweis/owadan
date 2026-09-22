<?php

declare(strict_types=1);

namespace App\Enum;

enum PriceType: string
{
    case FIXED = 'FIXED';
    case FROM = 'FROM';
    case ON_REQUEST = 'ON_REQUEST';
}
