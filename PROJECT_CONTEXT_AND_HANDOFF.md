# Funeral Spaces — Project Context & Handoff

**Last updated:** 26 October 2026  
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

## Current plan and decisions

- Initial product focus: **Phase 1 Society Space**, for self-managed funeral societies.
- Initial workflow focus: society profile/rules, members and covered lives, contributions and receipts, statement import/reconciliation, roles/approvals, funeral notification/checklists/status, reports, and audit history.
- Later roadmap: **Phase 2 Parlour Space**, **Phase 3 Family Space and cross-Space workflow**, **Phase 4 supplier marketplace and advanced automation**.
- Android and iOS are both first-class target platforms from the start. Do not plan iOS as a later port.
- Current provisional mobile recommendation: Flutter/Dart. Provisional backend direction: NestJS/TypeScript modular monolith and PostgreSQL. SQLite is a possible on-device option only if offline needs are validated. These are recommendations, not final commitments.
- Strong mobile UX is essential: clear workflows, low friction, accessible controls, visible next steps, calm language, and trust/traceability.
- The design proposal is not yet approved. It includes proposed green/ivory/amber colors and screens/wireframes, but sign-in, user roles, offline behavior, language needs, permissions, and local society workflow need review and validation.
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
5. Drafted the Society Space product requirements and design proposal with workflows, screen sketches, proposed color direction, sign-in considerations, navigation, buttons, gesture/sheet/dialog patterns, requirements, and cross-Space architecture. It remains a proposal for review; no code has been implemented as part of this design work.
6. User moved/created the current workspace at `~/Developer/Funeral Enablement Suite/`. The former Documents path no longer resolved on 26 October 2026. Continue from the current workspace and never overwrite the older location without checking.
7. This handoff was created to preserve portable project context; the ChatGPT/Copilot chat transcript itself is managed by VS Code, not embedded here.

## Immediate next step

Review the open decisions in Section 13 of the Society Space design proposal, starting with navigation and visual direction. Then decide whether to revise the written requirements or create a clickable low-fidelity prototype. Before any prototype or code implementation, explain the plan and update the learning journal.

## How to continue in another workspace/chat

1. Open `~/Developer/Funeral Enablement Suite/` as the VS Code workspace.
2. Start a new Copilot Chat and say: **“Funeral Spaces Build Partner — read PROJECT_CONTEXT_AND_HANDOFF.md and the project guidelines, then continue from the current open decisions.”**
3. If project/repository memory is available, also ask to use the Funeral Enablement Suite guidelines. Keep this handoff file in the project so the context remains portable even if memory is unavailable.
4. To find earlier chat sessions, open the VS Code Chat view and use its history/sessions list (often shown with a clock/history control or in the Chat view menu). Select the prior session to resume if it is still retained. UI labels can differ by VS Code version/settings. VS Code persists chat sessions according to its chat-history/workspace-storage behavior; this Markdown file is a practical project summary, not a full transcript export.
