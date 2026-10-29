# Mobile App Learning Journal

A running learning record for planning and building the Funeral Spaces mobile application. Explanations and entries will be added as we make decisions or take implementation steps.

## Learning and collaboration preferences

- Explain each planned action in clear, beginner-friendly language **before** making code changes or implementing it.
- Keep Android and iOS support in scope from the beginning; avoid treating iOS as a later port.
- Explain unfamiliar technologies and why they fit the Funeral Spaces project.
- Record important decisions, concepts learned, and implementation milestones in this journal.

## 19 October 2026 — Initial technology direction

### Product context

Funeral Spaces is a South African platform planned to begin with the Society Space and expand later to parlours, families, and suppliers. The first release is expected to cover society setup, members and covered lives, contributions, reconciliation, approvals, and funeral-claim tracking.

### Current stack recommendation

- **Flutter and Dart** for one mobile app codebase supporting Android and iOS.
- **NestJS and TypeScript** for a modular backend API, when backend implementation begins.
- **PostgreSQL** for structured records and transactional workflows.
- **SQLite** on the device for offline-friendly data capture and later synchronization, if validated as an MVP need.

These are initial recommendations, not irreversible decisions. Validate them against the pilot workflows, team capacity, costs, and operational requirements before committing to a full build.

### Concepts to learn

- **Flutter:** a framework for building apps for multiple platforms from a shared codebase.
- **Dart:** the programming language used by Flutter.
- **Cross-platform does not mean identical everywhere:** shared app logic can reduce duplicated work, while layouts, accessibility, permissions, notifications, file handling, and testing still need attention on both Android and iOS.
- **Offline-first design:** allow essential work to continue with limited connectivity, then synchronize safely when a connection returns. This requires explicit decisions about conflicts and data protection.
- **Modular monolith:** one backend application organized into clear functional modules; usually simpler to operate initially than several independent services.

### Important platform requirement

Android and iOS are both target platforms from the start. Design, implementation, and testing decisions should preserve that requirement. iOS builds and device testing require access to macOS and Apple development tools.

### Next learning step

Before implementation, agree on the first Society Space workflows and identify which must work without a reliable internet connection. Then explain the proposed app structure and development setup before making any code changes.

## 19 October 2026 — Society Space product and design proposal

### Design planning artifact

Created `Research and planning/Funeral Spaces - Society Space Product Requirements and Design.md` as a visual-first proposal, not an approved specification. It contains workflow maps, text wireframes, screen requirements, a proposed palette, controls and gesture behavior, role/permission concepts, and a plan for adding other Spaces without merging their access boundaries.

### Concepts learned

- **Information architecture:** how the app groups destinations and tasks so users can find the next action.
- **Wireframe:** a low-detail layout used to discuss screen structure and workflow before visual polish or code.
- **Role-based access:** users see and perform only the tasks their assigned role permits; hiding a button alone is not security.
- **Audit trail:** a durable history of important changes and decisions, including who acted and when; corrections should not erase history.
- **Bottom sheet vs. dialog:** a sheet suits short contextual choices; a modal dialog should be reserved for decisions that need focused confirmation.
- **Cross-platform UX:** shared product patterns should work on Android and iOS while respecting platform navigation, accessibility, and device behavior.
- **Proposed vs. validated:** colors, sign-in method, society roles, offline support, and local workflows remain open for user/pilot validation before they become build requirements.

### Current design status

No code has been implemented. The Society Space design remains a proposal for review. The next step is to confirm or revise its open decisions before turning the flows into a clickable prototype or implementation plan.

## 26 October 2026 — Login mockup review

### Design source

Reviewed `Screen designs/Screen mock up-exported.pdf`. The login screen shows EverBond branding, a warm light background, “Welcome back” heading, email/username and password fields, password visibility control, forgot-password link, dark green Log in button, Google and Facebook buttons, society-administrator contact text, and a privacy note.

### Implementation boundary

The first implementation will reproduce the visible login UI in Flutter for Android and iOS. Login submission, password recovery, Google sign-in, and Facebook sign-in remain presentation-only until the authentication provider, account recovery policy, privacy approach, and backend are selected. The product/platform relationship between the EverBond wordmark and Funeral Spaces should be confirmed before final branding or store release.

### Concepts learned

- **Flutter SDK:** development tools needed to create, analyze, and run a Flutter project; the code can target both Android and iOS.
- **Scaffold:** the initial project structure and platform folders generated by Flutter before building the product UI.
- **UI versus authentication:** a form can look complete while still not securely signing users in; real authentication requires a backend/provider and secure session handling.
- **Design fidelity:** match the exported layout, colors, hierarchy, labels, and spacing while making the screen responsive and accessible on different devices.

### Implementation completed

- Installed Flutter and generated the Android/iOS project scaffold in `mobile/`.
- Replaced the generated counter screen with the mockup-based EverBond login screen in `mobile/lib/main.dart`.
- Added required-field validation, password visibility toggle, responsive scrolling, semantic control labels, and explicit messages that authentication actions are not connected yet.
- Added widget tests in `mobile/test/widget_test.dart` for visible content, password visibility, field validation, and the unconnected sign-in state.
- Verification on 26 October 2026: `flutter analyze` reported no issues and `flutter test` passed all tests.
- Enabled Flutter web support and built a static browser preview. The local preview is served at `http://127.0.0.1:5321` while its server process remains running; the screen was reviewed at a 440 × 956 phone-sized viewport. Web preview is for visual review and does not replace native Android/iOS testing.

### Additional concepts learned

- **Widget test:** runs the Flutter UI in a test environment and checks real visible behavior/interactions without a physical phone.
- **Static analysis:** checks Dart source for likely errors and style issues before runtime.
- **Scaffold vs. product UI:** Flutter generated platform folders and starter files; the starter counter was replaced by the product login UI while keeping Android/iOS targets.
- **Authentication boundary:** form validation checks input completeness only; secure authentication requires an agreed provider/backend, session handling, recovery rules, and security review.
- **Browser preview vs. mobile app:** Flutter shares most screen code, so web helps review layout quickly, but native permissions, system navigation, and device behavior still require Android/iOS testing.

### Open decisions

- The PDF uses the EverBond brand, while the platform concept is Funeral Spaces. Confirm whether EverBond is the product brand, a society label, or placeholder branding.
- Select authentication and password recovery approaches before connecting the login form. Google/Facebook buttons are currently visual placeholders and do not sign in.
- The screen has been tested with Flutter analyzer and widget tests; review on actual Android/iOS device sizes and against the PDF before calling visual matching complete.

## 26 October 2026 — Registration and Spaces landing decisions

### Decisions confirmed by the user

- People may register with or without a Space invitation. Creating an account does **not** automatically make someone a member of a society or reveal private Space information.
- SMS phone OTP and email OTP are the supported account-verification options.
- Every successfully signed-in or registered user lands on the Spaces screen. That screen separates active memberships, invitations, pending join requests, and discoverable Spaces.
- A pending invitation is visibly called out and must be reviewed before the user accepts or declines it.
- A person without an invitation can inspect a discoverable Space and provide its required information to request access.
- Phase 1 keeps Home → Members → Contributions → Funeral cases → More navigation and the green palette. Revisit navigation/palette in enhancement phases.
- English is the first-pilot language.

### Concepts learned

- **Account versus membership:** an account proves who is signing in; a separate Space membership grants access. An account can exist without any membership.
- **Join request versus invitation:** a join request is started by the person seeking access; an invitation is initiated by an authorized Space representative. Both require distinct status and audit history.
- **Pending approval as a safe default:** until role and approval rules are defined, submitting a join request should not grant access. An authorized approval can create membership; automatic admission is a separate policy choice.
- **Spaces landing screen:** this is the first authenticated destination, not a direct jump into one society. It helps a person handle invitations, view joined Spaces, and request a new Space.
- **Provider boundary:** the app can design for email/SMS codes now, but actual delivery and verification depend on a selected identity/OTP provider. A demo code must never be presented as real authentication.

### Planning document update and next build boundary

Updated the Society Space requirements to replace the previous invite-only recommendation with the confirmed self-registration + optional invitation + Space join-request flow. Added a pending join-request entity to the proposed database design. This is documentation, not a live API/database implementation.

Before real account verification can be connected, choose the identity/OTP provider, OTP-channel selection rules, account recovery/session policy, and privileged-role verification. Join-form fields and approval permissions also need pilot decisions. A safe development implementation can still build the registration and Spaces UI plus provider-neutral API contracts/schema, with membership denied until approval and delivery adapter explicitly unconfigured.

## 26 October 2026 — Phase 1 registration and database planning

### Requirements update

Expanded `Research and planning/Funeral Spaces - Society Space Product Requirements and Design.md` with proposed invitation-based registration, sign-in/session/recovery requirements, authentication acceptance checks, a PostgreSQL relationship diagram, Phase 1 entity descriptions, data integrity/privacy rules, and a migration workflow. These are planning requirements, not an implemented authentication service or database.

### Concepts learned

- **Authentication vs. authorization:** authentication establishes which account is signed in; authorization checks which Space and actions that account may access.
- **Account vs. society member:** an app login is not the same as a society’s membership record. Some members may not have accounts, and some officers may not be members.
- **Invitation-based onboarding:** an authorized person invites an account into a specific Space with a specific role; this is proposed for the pilot to avoid public access to private society records.
- **Relational database:** PostgreSQL tables use primary/foreign keys and constraints to keep linked records consistent.
- **Schema migration:** a version-controlled, repeatable change to database structure, applied across environments rather than editing production manually.
- **Tenant/Space isolation:** each backend read/write must verify the active Space and user permissions; UI hiding alone is not security.
- **Idempotency and audit:** retrying a financial request must not duplicate it; corrections preserve prior actions through reversal/amendment history.

### Open decisions

- Self-registration and password-based login are now confirmed; the remaining question is which account/contact verification and password-auth provider to use.
- **User confirmed 26 October 2026:** verification options should include SMS one-time code to a phone number or email one-time code. Whether users choose the channel or the society configures it remains open.
- Password recovery/fallback, MFA for privileged roles, session/device policy, notification channel, and final Space-specific registration questions remain unresolved.
- PostgreSQL remains the provisional server database direction. A first local schema migration now exists; deployment, backup/restore, data retention, and production migration tooling still need confirmation.

## 26 October 2026 — Password login and registration verification flow

### Decisions confirmed by the user

- Restore the original username/email + password login. The login screen has a **Sign up** link; existing users do not receive an OTP during ordinary sign-in because their contact channel was verified at registration.
- The registration form asks for name, surname, location, selected Space, Space-specific questions, email, cell phone, address, preferred name, password, and password confirmation.
- After successful account registration, send an OTP to either the email address or cell phone to verify that chosen contact. Do not send that code before account registration succeeds.

### Implementation and learning notes

- The login form and registration form are separate screens connected by a navigation link. Conditional form fields change when a user selects a Space type; current Space-specific questions are examples and require product confirmation.
- The OTP screen is only a UI preview. Form validation does not create an account, and no code is sent or verified because there is no identity backend/provider yet.
- Password login requires secure backend authentication, password hashing by a vetted service, account recovery, rate limiting, and protected session storage before it can be production-ready.

## 27 October 2026 — Normalized account and registration database

### Implemented database foundation

- Added `database/migrations/001_auth_registration.sql` for PostgreSQL. Account status, profile, address, email/phone contact, username, password credential, Space-specific form version/questions, registration submission/answers, verification challenge, sessions, and authentication events are separate tables.
- Login identifiers are separate from password credentials. The credential table stores only an encoded password hash and security counters; email sign-in resolves using the verified email contact. No plaintext password, OTP, or refresh token is stored.
- A registration selects an exact version of a Space-type form, and each answer points to a question from that form version. This is normalization: repeated form/question data is stored once and linked by keys, while answer records do not copy the question wording.
- OTP challenge metadata models a queued/sent/failed delivery and can only be used for registration-contact verification or password reset. The API must commit a pending registration before asking a delivery provider to send a code. The schema itself does not send or validate a code.
- Applied the migration to a fresh local PostgreSQL 14 development database and ran a synthetic registration insert through related tables in a transaction that was rolled back. The migration and relation inserts succeeded.

### Still not implemented

- No HTTP API, password hashing/verification implementation, rate limiting, email/SMS delivery provider, OTP verification service, or token issuance exists yet.
- The database does not grant Space membership from registration. Space directory, membership, invitations, join requests, and Society Space business tables remain future migrations.
- SQL constraints help maintain data integrity but do not replace server-side authorization or security controls. Use synthetic data locally and have password/OTP/session handling reviewed before production.
