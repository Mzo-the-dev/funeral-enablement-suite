# My Funeral Spaces App

EverBond, is a funeral administrative tool that aims to enhance the user experience when handling the
Administration of arranging for a funeral.

# Table of Contents

-[Introduction](#everbond--simplifying-funeral-administration-through-connection)

-[API registration](#local-api-and-registration-testing)

-[Testing](#run-the-flutter-web-app)

# Everbond – Simplifying Funeral Administration Through Connection

Everbond is a digital funeral administration and coordination platform designed to simplify and modernise the way funeral-related services are managed in South Africa.
When a member of a community passes away, several support mechanisms come into play, including traditional funeral policies, funeral parlour insurance plans, and community-based funeral savings groups, commonly known as funeral societies. While these mechanisms serve an important purpose in providing financial and practical support to grieving families, their administrative processes often remain fragmented, manual, and disconnected.

Everbond aims to bridge this gap by providing a centralised digital platform that connects individuals, funeral societies, and funeral service providers through a streamlined and accessible ecosystem.

The platform seeks to reduce administrative complexity, improve information management, and introduce greater transparency, accuracy, and efficiency throughout the funeral planning and claims process.

## Purpose & Value Proposition

At its core, Everbond serves two primary purposes:

**1. Funeral Society Administration**

Everbond provides funeral societies with a centralised digital management solution, effectively acting as an electronic logbook for their day-to-day operations. This includes:

- Member registration and management.
- Registration and tracking of individuals covered under each membership.
- Attendance registers and member participation records.
- Monthly contribution logging and financial tracking.
- Funeral registration and notifications to relevant stakeholders.
- Management and approval of fund withdrawals and payouts.
- Consolidated financial records and annual society reporting.

By digitising these processes, Everbond aims to improve accountability, reduce administrative overhead, and provide society members and administrators with better visibility into the financial and operational standing of their groups.

**2. Funeral Service Provider & Client Integration**

Everbond also acts as a bridge between clients and funeral parlours, creating a connected environment where funeral-related services can be accessed and managed more efficiently.

Through this integration, the platform aims to facilitate:

- Digital policy management, including policy changes and claims initiation.
- Communication of funeral notifications and relevant instructions to funeral parlours.
- A streamlined channel for clients to engage with funeral service providers.
- A digital marketplace where funeral parlours can showcase and advertise their products and service offerings.
- Improved coordination between clients, societies, and funeral service providers when a funeral needs to be arranged.

## The Bigger Vision

Everbond is built around the idea that arranging a funeral should not be made more difficult by fragmented administration, disconnected service providers, or inefficient manual processes.

By bringing the various participants in the funeral services ecosystem onto one platform, Everbond aims to create a more connected, transparent, and efficient experience — one that supports communities, empowers funeral societies, and creates new opportunities for funeral service providers.

**Everbond: Connecting communities, simplifying administration, and bringing the funeral services ecosystem together.**

## Local API and registration testing

The NestJS development API and setup steps are documented in [backend/README.md](backend/README.md). It connects the Flutter app to local PostgreSQL; the development OTP is a test code only and does not send email or SMS.

## Run the Flutter web app

In VS Code, choose **EverBond Web (port 5322)** from Run and Debug. The port stays fixed at `5322` across launches and refreshes. From a terminal, run `flutter run -d chrome --web-port 5322` inside `mobile/`. The backend CORS origin must match `http://localhost:5322`.
