# API conventions v0.1

Base path: `/api/v1`

Successful collection:
```json
{"data": [], "meta": {"count": 0}}
```

Successful object:
```json
{"data": {}}
```

Error:
```json
{"error": {"code": "VALIDATION_ERROR", "message": "..."}}
```

Dates/times: ISO-8601. Platform events are stored timezone-aware; booking local-time rules will be formalized in Sprint 3.

Localization: API returns localized-name maps initially (`tk`, `ru`, optional `en`) so clients can render without hard-coded category labels.
