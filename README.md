# My Funeral Spaces App

## Local API and registration testing

The NestJS development API and setup steps are documented in [backend/README.md](backend/README.md). It connects the Flutter app to local PostgreSQL; the development OTP is a test code only and does not send email or SMS.

## Run the Flutter web app

In VS Code, choose **EverBond Web (port 5322)** from Run and Debug. The port stays fixed at `5322` across launches and refreshes. From a terminal, run `flutter run -d chrome --web-port 5322` inside `mobile/`. The backend CORS origin must match `http://localhost:5322`.
