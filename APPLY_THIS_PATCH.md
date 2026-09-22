# Owadan — Professional Profile + Services patch

Copy the `backend` folder from this patch into `D:\owadan`, preserving paths and replacing `backend/config/packages/security.yaml`.

## Apply

From `PS D:\owadan>`:

```powershell
docker compose exec php php bin/console doctrine:migrations:migrate --no-interaction
docker compose exec php rm -rf var/cache/dev
docker compose exec php php bin/console doctrine:schema:validate
docker compose exec php php bin/console debug:router
```

Expected new routes:

- `GET /api/v1/professionals`
- `GET /api/v1/professionals/{id}`
- `GET /api/v1/professionals/{id}/services`
- `GET /api/v1/pro/profile`
- `PUT /api/v1/pro/profile`
- `POST /api/v1/pro/profile/submit-verification`
- `POST /api/v1/pro/services`
- `PUT /api/v1/pro/services/{id}`

## Test authenticated professional onboarding

Use the `$access` JWT from the completed OTP login flow.

```powershell
$headers = @{ Authorization = "Bearer $access" }

$profileBody = @{
  displayName = "Ayna Beauty"
  bio = "Hair and bridal beauty professional in Ashgabat"
  experienceYears = 5
  languages = @("tk", "ru")
} | ConvertTo-Json

$profile = Invoke-RestMethod -Method Put -Uri "http://127.0.0.1:8000/api/v1/pro/profile" -Headers $headers -ContentType "application/json" -Body $profileBody
$profile | ConvertTo-Json -Depth 10
```

Get your profile:

```powershell
Invoke-RestMethod -Method Get -Uri "http://127.0.0.1:8000/api/v1/pro/profile" -Headers $headers | ConvertTo-Json -Depth 10
```

Get category IDs:

```powershell
$categories = Invoke-RestMethod -Method Get -Uri "http://127.0.0.1:8000/api/v1/categories"
$categories | ConvertTo-Json -Depth 10
```

Create a service using one category ID:

```powershell
$serviceBody = @{
  categoryId = 1
  name = "Women's haircut"
  description = "Consultation and haircut"
  durationMinutes = 60
  priceType = "FROM"
  price = "150.00"
} | ConvertTo-Json

$service = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/api/v1/pro/services" -Headers $headers -ContentType "application/json" -Body $serviceBody
$service | ConvertTo-Json -Depth 10
```

Submit the profile for verification:

```powershell
Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/api/v1/pro/profile/submit-verification" -Headers $headers | ConvertTo-Json -Depth 10
```

Public listing intentionally shows only `VERIFIED` professionals. Admin approval is the next development block.

## Git

After the tests pass:

```powershell
git add .
git commit -m "feat: add professional profiles and services"
git push
```
