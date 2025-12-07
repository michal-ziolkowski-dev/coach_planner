# Coach Planner

![Flutter badge](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart badge](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Supabase badge](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase&logoColor=white)
![Status badge](https://img.shields.io/badge/status-MVP%20planning-blue)

## Table of Contents
- [Project Name](#project-name)
- [Project Description](#project-description)
- [Tech Stack](#tech-stack)
- [Getting Started Locally](#getting-started-locally)
- [Available Scripts](#available-scripts)
- [Project Scope](#project-scope)
- [Project Status](#project-status)
- [License](#license)

## Project Name

Coach Planner

## Project Description

Coach Planner is a role-based scheduling platform designed to streamline how trainers and athletes coordinate individual or small-group sessions. The goal is to replace ad hoc messaging and spreadsheet coordination with a self-service experience that exposes up-to-date availability, prevents double booking, and preserves a reliable history of slot changes.

The MVP focuses on a responsive web app that supports self-registration for both trainers and trainees, weekly availability management, real-time slot reservations, and transparent status tracking. For the complete product requirements, review the [Product Requirements Document](./.ai/prd.md).

## Tech Stack

- **Frontend:** Flutter 3.x (Dart 3) targeting web, with planned use of Riverpod or Bloc for state management, `go_router` for navigation, `flutter_form_builder` for robust forms, and `table_calendar` or custom views for weekly availability.
- **Backend:** Supabase (PostgreSQL, authentication, Row Level Security, functions) to handle account roles, reservation data, and audit logging.
- **Integration:** Supabase Dart SDK or REST interfaces for secure data access, with automatic status transitions handled via database triggers or scheduled functions.
- **CI/CD & Hosting:** GitHub Actions pipelines with containerized deployments to DigitalOcean (or equivalent static hosting for the Flutter Web bundle).

## Getting Started Locally

1. Install the Flutter SDK (3.10.0-290.4.beta as specified in `src/pubspec.yaml`) and ensure `flutter --version` reports a compatible Dart 3 toolchain.
2. Clone the repository and navigate to the Flutter workspace:
   ```bash
   git clone <repository-url>
   cd Coach_planner/src
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Launch the web app (Chrome by default):
   ```bash
   flutter run -d chrome
   ```
5. Run the automated checks when contributing:
   ```bash
   dart analyze
   flutter test
   ```
6. Configure Supabase environment variables and service keys before integrating real backend calls (environment templates will be added alongside the initial data layer).

## Available Scripts

- `flutter pub get` – Install or update Dart and Flutter dependencies.
- `flutter run -d chrome` – Serve the web application locally with hot reload.
- `flutter test` – Execute the widget and unit test suite.
- `dart analyze` – Run static analysis using the configured lint rules.
- `flutter build web` – Produce an optimized web build for deployment.

> Run the commands above from the `src` directory.

## Supabase Type Generation

We scaffold typed Supabase models with [Supadart](https://github.com/mmvergara/supadart?tab=readme-ov-file). Workflow:

1. Install the CLI once:
   ```bash
   dart pub global activate supadart
   ```
2. Initialize a config (creates `supadart.yaml` if missing):
   ```bash
   supadart --init
   ```
3. Fill in `SUPABASE_URL`, `SUPABASE_API_KEY`, enums, and custom types inside `supadart.yaml`.
4. Generate/update models (run from `src/` so the output lands in `lib/models`):
   ```bash
   supadart --config supadart.yaml
   ```

Regenerate classes whenever the database schema changes and commit the updated `lib/models/generated_classes.dart`.

## Project Scope

- Role-based authentication with self-service registration, login, logout, password changes, and account deletion.
- Alphabetized coach directory with profile details and a weekly, 24-hour availability calendar.
- Trainer tools to create, edit, and delete availability slots (including overlapping slots and configurable capacity).
- Trainee experience for reserving and cancelling slots, with automatic capacity management and guardrails (e.g., cancellation cutoff 60 minutes before start).
- Automated status updates (created, cancelled, attended) applied when slots pass, preserving full change history.
- Dedicated change-log table capturing who performed each operation, previous/current states, and timestamps for auditing.

## Project Status

The project is in the MVP stage and under active development.

## License

This project is licensed undet the MIT License.