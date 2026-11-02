# Funeral Spaces API (development)

This NestJS API is the server-side bridge between the Flutter app and PostgreSQL. Flutter sends HTTPS requests in production; only this API receives database credentials. The local development slice implements account registration, contact verification, password login, opaque sessions, public Space discovery, active Space memberships, and a member-scoped Society dashboard with role-checked membership and funeral-case approvals. It does not implement password recovery, a real email/SMS provider, production deployment, or production-ready rate limiting.

## Local setup

Requirements: Node.js 20+, npm, and the PostgreSQL database with migrations `001_auth_registration.sql` through `005_user_profile_avatar.sql` applied.

1. From this folder, install dependencies: `npm install`.
2. Copy `.env.example` to `.env` and set `OTP_PEPPER` to a random secret of at least 32 characters. Keep `.env` private; it is ignored by Git.
3. Start the API with `npm run start:dev`.
4. Check `http://localhost:3000/api/health`; it should return `{"status":"ok","database":"connected"}`.
5. From `mobile/`, run the Flutter web app with `flutter run -d chrome --web-port 5322`. The workspace also has a VS Code launch profile named `EverBond Web (port 5322)`. For an Android emulator, use `--dart-define=API_BASE_URL=http://10.0.2.2:3000/api`; for web and iOS simulator, the default is `http://localhost:3000/api`.

The local API binds to all network interfaces to support an Android emulator. Use only on a trusted development network and stop it when finished. Local testing uses HTTP; production must use HTTPS and a managed secrets store. Android/iOS debug networking may require platform-specific local-network/cleartext configuration before testing on simulators/devices.

The fixed Flutter web port is `5322`, and the default/example CORS origins match it. If you have an existing `backend/.env` or start command that sets `CORS_ORIGINS`, update it to `http://localhost:5322,http://127.0.0.1:5322`; an environment override takes precedence over the backend default. Do not use a wildcard origin with credentials or expose the development API publicly.

## Endpoints

- `GET /api/health` — checks API and PostgreSQL connectivity.
- `POST /api/registrations` — validates the selected form version, hashes the password with Argon2id, and atomically creates the pending account/profile/address/contacts/username/credential/answers/challenge records.
- `POST /api/registrations/verify` — validates the time-limited, one-use code and activates the account in a transaction.
- `POST /api/sessions` — accepts `identity` (username or verified email) and `password`; returns a 12-hour opaque `sessionToken` for an active account. Password failures are generic, recorded, and lock the credential after five failures for 15 minutes.
- `POST /api/sessions/logout` — accepts `sessionToken` and revokes its session. Logout is safe to retry.
- `GET /api/users/me/profile` — requires an active bearer session and returns only the signed-in user's profile, including preferred name and avatar.
- `POST /api/users/me/profile` — requires an active bearer session; updates the preferred name and optionally uploads/removes a PNG, JPEG, or WebP avatar of at most 512 KiB. Avatar data is stored in PostgreSQL, and the JSON request limit is 1 MiB.
- `GET /api/spaces/types` — lists enabled categories (`Society`, `Parlour`, `Family`, and `Supplier`) for the signed-in landing screen. These are categories, not real organization Spaces.
- `GET /api/spaces/discoverable` — lists active Society Spaces explicitly marked discoverable, with only their ID, display name, category code, and public description. It does not return membership, covered-life, fee, or office data and does not grant access. The Flutter landing currently labels these as public profiles; membership requests are not implemented.
- `GET /api/spaces/mine` — requires `Authorization: Bearer <sessionToken>` and returns only active Society Spaces whose membership, account, Space, Society, and session are all active. Expired, revoked, missing, or invalid sessions are rejected. The response contains Space/profile and role codes only, not member rosters, covered lives, fees, or office records.
- `GET /api/spaces/:spaceId/dashboard` — requires an active Society Space membership. All active members receive society contribution totals, member names/status/arrears, and funeral-case statuses. Contribution history is limited to the signed-in member; pending membership applications are included only for the Chairperson. Approval permissions are returned for display, but every decision is also enforced by the API.
- `POST /api/spaces/:spaceId/join-requests` — requires an authenticated account and a society member number. Submission does not grant access; the request remains pending until approved.
- `POST /api/spaces/:spaceId/membership-requests/:requestId/approve` — Chairperson only. Approval creates the active Society Space membership transactionally.
- `POST /api/spaces/:spaceId/funeral-cases/:caseId/approve` — assigned Funeral Approver only. Other roles can view case status but cannot approve a case.

The request body for registration contains `username`, `givenName`, `surname`, `preferredName`, `location`, `address`, `email`, `phone`, `password`, `spaceCode` (`society`, `parlour`, `family`, or `supplier`), `verificationChannel` (`email` or `sms`), and an `answers` object keyed by the question keys from the selected database form. Example keys for Society Space: `society_reference`, `society_role`.

The development OTP sink is **not** an email/SMS integration. It is enabled only when `DEV_RETURN_OTP=true` and `NODE_ENV` is not `production`; the code is returned in the response as `otpForDevelopment` for local testing. The server stores only a keyed HMAC of the code. A 10-minute expiry, five-attempt limit, one-use check, and API request throttle are enabled. The in-memory request throttle is per process and is not sufficient for production or multiple API instances.

## Important security boundary

This is a development milestone, not a production auth service. The raw session token is returned once and held only in Flutter memory; PostgreSQL stores its SHA-256 hash in `auth_session`. Restarting the app signs the user out. The current opaque session token is valid for 12 hours; there is no refresh/rotation endpoint. Do not treat category selection or public discovery as membership or authorization. The local `testperson` membership and Stronger Together operations data are synthetic development fixtures. Society-wide roster, arrears, contribution totals, and case status are visible to active members; individual contribution history is member-only. Chairperson membership approval and Funeral Approver case approval are enforced server-side. Before real users or deployment: add verified member-account linking, production-ready invitation and role management; add a real, monitored email/SMS provider and delivery-failure handling; production secrets management and HTTPS; distributed rate limiting/abuse controls; secure persistent token storage and session rotation; account recovery; operational logging/monitoring; migrations and backup/restore; and privacy/security review. Do not use real personal data or expose the development OTP sink publicly.
