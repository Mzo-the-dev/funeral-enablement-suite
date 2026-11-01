# Funeral Spaces API (development)

This NestJS API is the server-side bridge between the Flutter app and PostgreSQL. Flutter sends HTTPS requests in production; only this API receives database credentials. This initial slice implements local registration and contact verification only. It does not implement login, password recovery, a real email/SMS provider, Space membership, production deployment, or production-ready rate limiting.

## Local setup

Requirements: Node.js 20+, npm, and the PostgreSQL database with `database/migrations/001_auth_registration.sql` already applied.

1. From this folder, install dependencies: `npm install`.
2. Copy `.env.example` to `.env` and set `OTP_PEPPER` to a random secret of at least 32 characters. Keep `.env` private; it is ignored by Git.
3. Start the API with `npm run start:dev`.
4. Check `http://localhost:3000/api/health`; it should return `{"status":"ok","database":"connected"}`.
5. From `mobile/`, run the Flutter app with `--dart-define=API_BASE_URL=http://localhost:3000/api` for web or iOS simulator. For an Android emulator, use `http://10.0.2.2:3000/api` as the API base URL.

The local API binds to all network interfaces to support an Android emulator. Use only on a trusted development network and stop it when finished. Local testing uses HTTP; production must use HTTPS and a managed secrets store. Android/iOS debug networking may require platform-specific local-network/cleartext configuration before testing on simulators/devices.

## Endpoints

- `GET /api/health` — checks API and PostgreSQL connectivity.
- `POST /api/registrations` — validates the selected form version, hashes the password with Argon2id, and atomically creates the pending account/profile/address/contacts/username/credential/answers/challenge records.
- `POST /api/registrations/verify` — validates the time-limited, one-use code and activates the account in a transaction.

The request body for registration contains `username`, `givenName`, `surname`, `preferredName`, `location`, `address`, `email`, `phone`, `password`, `spaceCode` (`society`, `parlour`, `family`, or `supplier`), `verificationChannel` (`email` or `sms`), and an `answers` object keyed by the question keys from the selected database form. Example keys for Society Space: `society_reference`, `society_role`.

The development OTP sink is **not** an email/SMS integration. It is enabled only when `DEV_RETURN_OTP=true` and `NODE_ENV` is not `production`; the code is returned in the response as `otpForDevelopment` for local testing. The server stores only a keyed HMAC of the code. A 10-minute expiry, five-attempt limit, one-use check, and API request throttle are enabled. The in-memory throttle is per process and is not sufficient for production or multiple API instances.

## Important security boundary

This is a development milestone, not a production auth service. Before real users or deployment: add a real, monitored email/SMS provider and delivery-failure handling; production secrets management and HTTPS; distributed rate limiting/abuse controls; login/session issuance and secure client token storage; account recovery; operational logging/monitoring; migrations and backup/restore; and privacy/security review. Do not use real personal data or expose the development OTP sink publicly.
