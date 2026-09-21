<?php

namespace App\Enum;

enum UserRole: string
{
    case CUSTOMER = 'ROLE_CUSTOMER';
    case PROFESSIONAL = 'ROLE_PROFESSIONAL';
    case SALON_OWNER = 'ROLE_SALON_OWNER';
    case ADMIN = 'ROLE_ADMIN';
}
