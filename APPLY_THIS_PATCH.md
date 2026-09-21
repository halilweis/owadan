# Apply this patch to Owadan

Copy the patch contents into the root of your existing `D:\owadan` project, preserving folders. Allow replacement of existing files.

Then run from `D:\owadan`:

```powershell
docker compose exec php composer require lexik/jwt-authentication-bundle:^3.2 --with-all-dependencies

docker compose up -d --build

docker compose exec php php bin/console lexik:jwt:generate-keypair --skip-if-exists

docker compose exec php php bin/console doctrine:migrations:migrate --no-interaction

docker compose exec php php bin/console cache:clear
```

## Quick auth test (PowerShell)

Request OTP:

```powershell
$otp = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/api/v1/auth/request-otp" -ContentType "application/json" -Body '{"phoneNumber":"+99361234567"}'
$otp
```

In development, the response includes `developmentCode: 123456`.

Verify OTP and receive tokens:

```powershell
$login = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/api/v1/auth/verify-otp" -ContentType "application/json" -Body '{"phoneNumber":"+99361234567","code":"123456"}'
$login
$access = $login.data.tokens.accessToken
$refresh = $login.data.tokens.refreshToken
```

Call authenticated endpoint:

```powershell
Invoke-RestMethod -Method Get -Uri "http://127.0.0.1:8000/api/v1/me" -Headers @{ Authorization = "Bearer $access" }
```

Rotate refresh token:

```powershell
$refreshBody = @{ refreshToken = $refresh } | ConvertTo-Json
$newTokens = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/api/v1/auth/refresh" -ContentType "application/json" -Body $refreshBody
$newTokens
```

## Commit after successful test

```powershell
git add .
git commit -m "feat: add OTP and JWT authentication flow"
git push
```
