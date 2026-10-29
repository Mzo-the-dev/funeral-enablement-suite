# Funeral Spaces — Project Context & Handoff

**Last updated:** 29 October 2026  
**Purpose:** Portable context for continuing this project in another VS Code workspace or chat. Read this before planning, research, design, or implementation.

## Project assistant name

**Name:** Funeral Spaces Build Partner

When the user starts a new session with “Funeral Spaces Build Partner,” treat it as a request to continue this project using this handoff and the project guidelines. This phrase is a continuity cue, not a technical guarantee that chat history or memory will automatically load in every workspace/account.

## Product summary

Funeral Spaces is a proposed connected digital platform for South African funeral societies, parlours, families, and eventually suppliers. It uses secure, role-specific workspaces called **Spaces**, which may connect through a shared funeral case when needed. A connected journey must not merge distinct records or permissions.

The current concept and roadmap are recorded in:

- [Research and planning/FUNERAL SPACES.md](Research%20and%20planning/FUNERAL%20SPACES.md) — project concept and strategy in Markdown.
- [Research and planning/Funeral_Spaces_Platform_Concept_and_Strategy.docx](Research%20and%20planning/Funeral_Spaces_Platform_Concept_and_Strategy.docx) — source concept document.
- [Research and planning/Funeral Spaces - Society Space Product Requirements and Design.md](Research%20and%20planning/Funeral%20Spaces%20-%20Society%20Space%20Product%20Requirements%20and%20Design.md) — current visual-first Society Space requirements/design proposal; read the latest version before changing it.
- [Research and planning/Learning/Mobile App Learning Journal.md](Research%20and%20planning/Learning/Mobile%20App%20Learning%20Journal.md) — learning concepts and project decisions for the user.
- [database/ERD.md](database/ERD.md) — plain-language ERD for the implemented account/registration PostgreSQL tables.
- [database/README.md](database/README.md) — database setup, migration, and auth-flow notes.
- [database/migrations/001_auth_registration.sql](database/migrations/001_auth_registration.sql) — initial account/registration schema migration.
- [mobile/lib/main.dart](mobile/lib/main.dart) — initial Flutter login screen implementation.
- [mobile/test/widget_test.dart](mobile/test/widget_test.dart) — widget tests for login screen structure and interactions.
- [mobile/web/index.html](mobile/web/index.html) — Flutter web entry point added for visual browser previews.
- The Society Space requirements document includes proposed Phase 1 registration/authentication flows and the broader future PostgreSQL business schema. Only the account/registration tables in the initial migration have been implemented; no backend authentication service exists yet.

## Current plan and decisions

- Initial product focus: **Phase 1 Society Space**, for self-managed funeral societies.
- Initial workflow focus: society profile/rules, members and covered lives, contributions and receipts, statement import/reconciliation, roles/approvals, funeral notification/checklists/status, reports, and audit history.
- Later roadmap: **Phase 2 Parlour Space**, **Phase 3 Family Space and cross-Space workflow**, **Phase 4 supplier marketplace and advanced automation**.
- Android and iOS are both first-class target platforms from the start. Do not plan iOS as a later port.
- Current provisional mobile recommendation: Flutter/Dart. Provisional backend direction: NestJS/TypeScript modular monolith and PostgreSQL. SQLite is a possible on-device option only if offline needs are validated. These are recommendations, not final commitments.
- Strong mobile UX is essential: clear workflows, low friction, accessible controls, visible next steps, calm language, and trust/traceability.
- The Society Space design is evolving with user decisions. Confirmed for Phase 1: keep the green palette and Home → Members → Contributions → Funeral cases → More navigation; English is the first-pilot language. Roles/approval rules, offline behavior, member-visible records, and local workflows still need validation.
- A Flutter mobile app scaffold now exists in `mobile/` with Android and iOS targets. Its initial home screen reproduces the login screen from `Screen designs/Screen mock up-exported.pdf`, including EverBond branding, fields, password visibility, social buttons, administrator contact and privacy note. `flutter analyze` and `flutter test` passed on 26 October 2026.
- Flutter web support has also been enabled to preview the same shared UI in a browser. A static web build succeeded; preview server is available at `http://127.0.0.1:5321` while its terminal process is running. This is a visual preview only and does not replace testing on Android/iOS devices.
- Login UI validation is local only. Real account sign-in, password recovery, Google/Facebook authentication, and administrator contact are not connected to a backend/provider and must not be represented as production authentication.
- The mockup brands the screen “EverBond” while the platform concept is “Funeral Spaces”; confirm their intended relationship before final brand decisions or release.
- Registration/authentication decision (26 October 2026; latest): existing users sign in with username/email + password; do not send OTP during ordinary login. Screen 1 retains the password-based layout and exposes a **Sign up** link. Registration collects name, surname, location, selected Space and Space-specific questions, email, cell phone, address, preferred name, password, and confirmation. Only after successful account creation is an OTP sent to the chosen email or cell phone. The Flutter registration/OTP screens are preview-only; no account, password authentication, API, or OTP delivery is connected. Existing account-versus-Space-membership separation and the post-authentication Spaces landing/invitation/join-request decisions remain in effect. Actual Space-specific prompts, identity/OTP provider, recovery, and secure session policy remain open.
- Other user-confirmed Phase 1 decisions (26 October 2026): retain the green palette and Home → Members → Contributions → Funeral cases → More navigation; English is the first-pilot language. Society roles/approval boundaries, offline behavior, and member visibility of own contributions/covered lives remain unresolved.
- Authentication is not wired up. Select an identity/password authentication provider, post-registration OTP delivery provider and channel behavior, account recovery, session/device policy, and privileged-user verification. Never store plaintext passwords or send real OTPs until provider configuration and security review are complete.
- Database foundation: [database/migrations/001_auth_registration.sql](database/migrations/001_auth_registration.sql) implements normalized PostgreSQL 14-compatible tables for account status, profile, addresses, contact verification, usernames, password-hash credentials, versioned Space registration forms/questions, registration submissions/answers, OTP challenge metadata, revocable hashed refresh-token sessions, and limited auth events. It was applied and smoke-tested in local disposable database `funeral_spaces_dev`; schema docs are in [database/README.md](database/README.md). No API, password hashing/verification, OTP delivery, or session issuing is implemented; all auth actions remain backend work. The wider society/membership/contributions/cases schema is still proposal/planning.
- The user is new to the suggested stack and wants to learn. Before any code change or implementation, explain what will be done, why, and relevant unfamiliar concepts in beginner-friendly terms. Update the learning journal with meaningful milestones.
- The user expects thorough South African-context research, no unsupported assumptions, clear fact/assumption distinctions, and explicit uncertainty. When unsure, state that alternative approaches are being considered/requested and present options with trade-offs.
- The user earlier requested approval before research points are added to the research document. Present findings and ask whether they are worth noting; do not silently treat new findings as approved.

## Product and safety boundaries

- Treat POPIA/privacy, access control, consent, retention, incident response, and sensitive family/member information as foundational. This is product planning, not legal advice; refer legal/regulatory questions to qualified South African professionals.
- Initially keep society funds in their existing society bank accounts; do not imply the platform will hold/pool funds or initiate transfers.
- Do not arrange insurance or make binding benefit/claim decisions without legal/regulatory review. A software eligibility flag is informational and must show its rule basis; exceptions go to authorized people.
- Do not silently auto-confirm uncertain payment matches. Preserve audit history for changes, approvals, reversals, and corrections.
- Each Space must follow least-privilege access. Shared funeral-case data must be explicitly scoped to person, purpose, and duration; a family or supplier must not get society committee/financial records by default.

## Work completed so far

1. User provided the full **Funeral Spaces: Concept, Product Strategy & Validation Plan** context, with South African setting and a phased Spaces roadmap.
2. Discussed cross-platform support. User confirmed Android and iOS are both intended; future design and build should preserve both.
3. Created the Mobile App Learning Journal and established that explanations should precede implementation.
4. Created persistent project guidelines for research, learning, UX, platform parity, and privacy boundaries.
5. Drafted the Society Space product requirements and design proposal with workflows, screen sketches, proposed color direction, sign-in considerations, navigation, buttons, gesture/sheet/dialog patterns, requirements, and cross-Space architecture. It remains a proposal for review.
6. User moved/created the current workspace at `~/Developer/Funeral Enablement Suite/`. The former Documents path no longer resolved on 26 October 2026. Continue from the current workspace and never overwrite the older location without checking.
7. Reviewed the exported login screen at `Screen designs/Screen mock up-exported.pdf` and created a Flutter Android/iOS scaffold in `mobile/`. The first Flutter screen approximates the export; required-field validation and password visibility work. Authentication entry points are explicit placeholders. `flutter analyze` and `flutter test` passed.
8. Added Flutter web support for quick visual preview. Static build passed and was served at `http://127.0.0.1:5321`; screenshot reviewed at a 440 × 956 viewport. The preview server is a temporary local process and can stop when its terminal closes.
9. Added Phase 1 login/registration requirements and a provisional PostgreSQL schema/migration design to the Society Space requirements. These require user approval and workflow/security validation; no auth provider or database service is wired up.
10. This handoff was created to preserve portable project context; the ChatGPT/Copilot chat transcript itself is managed by VS Code, not embedded here.
11. Recorded the user's 26 October registration decisions: self-registration with or without invitation, no automatic Space membership, Spaces landing after login, invitation notification/review, Space join requests, SMS/email OTP support, English pilot language, and existing navigation/green palette retained. Updated requirements and journal; no API or database code has yet been implemented.
12. On 27 October 2026, created and validated the initial PostgreSQL account/registration migration. It separates account, profile, contact, address, login identifier, and password-hash credential data; stores per-version Space questions and answers; supports delayed email/SMS verification challenge metadata and revocable hashed sessions. Applied successfully to a fresh local PostgreSQL 14 database and smoke-tested the registration relational inserts in a rolled-back transaction. Backend/auth provider and actual delivery remain unimplemented.

## Immediate next step

Next, review the first auth database migration and confirm the Space-specific registration questions plus provider/backend choices. The Flutter flow remains a preview, with no account creation or OTP delivery. Implement the API integration only after agreeing backend framework, password-hashing/auth design, OTP/email/SMS provider, password recovery, and session policy. Then extend migrations for actual Space directory/memberships, invitations, join requests, and Society Space business data. Preserve membership safeguards, explain implementation actions, and update the learning journal. Confirm EverBond vs. Funeral Spaces brand relationship before final branding.

## How to continue in another workspace/chat

1. Open `~/Developer/Funeral Enablement Suite/` as the VS Code workspace.
2. Start a new Copilot Chat and say: **“Funeral Spaces Build Partner — read PROJECT_CONTEXT_AND_HANDOFF.md and the project guidelines, then continue from the current open decisions.”**
3. If project/repository memory is available, also ask to use the Funeral Enablement Suite guidelines. Keep this handoff file in the project so the context remains portable even if memory is unavailable.
4. To find earlier chat sessions, open the VS Code Chat view and use its history/sessions list (often shown with a clock/history control or in the Chat view menu). Select the prior session to resume if it is still retained. UI labels can differ by VS Code version/settings. VS Code persists chat sessions according to its chat-history/workspace-storage behavior; this Markdown file is a practical project summary, not a full transcript export.
