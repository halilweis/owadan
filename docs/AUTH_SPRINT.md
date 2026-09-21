# Owadan Authentication Increment

This increment adds:

- persisted OTP challenges with expiry and attempt limits;
- development OTP adapter (`123456` in `dev` only);
- JWT access tokens;
- rotating opaque refresh tokens stored as SHA-256 hashes;
- authenticated `GET /api/v1/me`;
- refresh and logout endpoints.

## Security notes

- Never commit `backend/config/jwt/*.pem`.
- The development OTP code is intentionally fixed and must be replaced by a real SMS provider before production.
- Refresh tokens are only stored hashed in PostgreSQL.
- Refresh tokens are rotated on every refresh.
- Access tokens default to 15 minutes; refresh tokens default to 30 days.
