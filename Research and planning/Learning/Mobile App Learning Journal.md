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
