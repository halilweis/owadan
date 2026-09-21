# Owadan

Owadan is a Turkmenistan-first beauty discovery and booking platform. The MVP starts in Ashgabat and uses:

- Backend/API + web foundations: Symfony (PHP 8.4)
- Database: PostgreSQL
- Mobile: Flutter
- Architecture: modular monolith

This repository is Sprint 1 foundation work. Booking is intentionally not implemented yet.

## Sprint 1 implemented in this starter

- Docker Compose for PostgreSQL
- Symfony backend skeleton and environment configuration
- Doctrine entities for users, locations and catalog
- Initial Doctrine migration
- Seed fixtures for Turkmenistan, Ashgabat and six MVP categories
- Health/readiness endpoints
- `GET /api/v1/categories`
- Development OTP auth skeleton (`request-otp`, `verify-otp`)
- Role model
- Consistent JSON API envelope and exception handling
- PHPUnit/WebTestCase examples
- CI workflow template
- Flutter workspace placeholder (full shell comes after API conventions stabilize)

## Start locally

1. Install Docker Desktop (or Docker Engine + Compose), Git, PHP 8.4, Composer 2, and Flutter.
2. Copy environment file:
   ```bash
   cp backend/.env.example backend/.env.local
   ```
3. Start PostgreSQL:
   ```bash
   docker compose up -d db
   ```
4. Install backend dependencies:
   ```bash
   cd backend
   composer install
   ```
5. Create database schema:
   ```bash
   php bin/console doctrine:migrations:migrate --no-interaction
   php bin/console doctrine:fixtures:load --no-interaction
   ```
6. Run Symfony locally:
   ```bash
   symfony server:start
   ```
   If Symfony CLI is not installed, use:
   ```bash
   php -S 127.0.0.1:8000 -t public
   ```
7. Check:
   - `GET http://127.0.0.1:8000/health`
   - `GET http://127.0.0.1:8000/ready`
   - `GET http://127.0.0.1:8000/api/v1/categories`

## Development OTP

For Sprint 1, OTP is a development adapter. Calling `POST /api/v1/auth/request-otp` returns a development code only when `APP_ENV=dev`. Replace it with the production SMS/OTP provider before pilot launch.

## Next development slice

Complete Sprint 1 hardening, then proceed to professional profiles, services, portfolio and admin verification before availability/booking.
