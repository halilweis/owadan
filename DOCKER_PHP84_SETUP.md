# Owadan — PHP 8.4 in Docker

Keep your Windows PHP 8.2 unchanged. Owadan runs PHP 8.4 inside Docker.

From the project root (`D:\\owadan`):

```cmd
docker compose down
docker compose up -d --build
docker compose ps
docker compose exec php php -v
docker compose exec php composer install
docker compose exec php php bin/console doctrine:migrations:migrate --no-interaction
docker compose exec php php bin/console doctrine:fixtures:load --no-interaction
```

Then open:

- http://127.0.0.1:8000/health
- http://127.0.0.1:8000/ready
- http://127.0.0.1:8000/api/v1/categories

Useful commands:

```cmd
docker compose logs -f php
docker compose exec php php bin/console about
docker compose exec php composer test
docker compose down
```

Important: commands for Owadan PHP/Symfony should now be prefixed with `docker compose exec php` rather than running your Windows `php` or `composer` directly.
