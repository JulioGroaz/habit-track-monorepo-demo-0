# Java + Flutter Monorepo Template

Reusable template for a Spring Boot backend + Flutter mobile app, designed for VS Code and fast setup.

## Quick start (1-2-3)
1) Copy the example env files
   - Windows (PowerShell):
     - backend: `Copy-Item backend\.env.example backend\.env`
     - mobile: `Copy-Item mobile\.env.example mobile\.env`
   - macOS/Linux:
     - backend: `cp backend/.env.example backend/.env`
     - mobile: `cp mobile/.env.example mobile/.env`
2) Start Postgres
   - `docker compose up -d`
3) Run backend and app
   - backend: `cd backend && mvn spring-boot:run`
   - mobile: `cd mobile && flutter run`

Swagger UI: http://localhost:8080/swagger-ui

## Without Docker (local DB)
If you want to use a locally installed Postgres (no `docker compose`):
1) Install Postgres and create user + database
   - SQL (psql or pgAdmin):
     ```sql
     CREATE USER template_user WITH PASSWORD 'template_pass';
     CREATE DATABASE template_db OWNER template_user;
     GRANT ALL PRIVILEGES ON DATABASE template_db TO template_user;
     ```
2) Copy and edit backend envs
   - Windows (PowerShell): `Copy-Item backend\.env.example backend\.env`
   - macOS/Linux: `cp backend/.env.example backend/.env`
   - Update `DB_URL`, `DB_USER`, `DB_PASSWORD` if you use different credentials
3) Run backend and mobile
   - backend: `cd backend && mvn spring-boot:run`
   - mobile: `cd mobile && flutter run`

## Project structure
- `/backend`: Spring Boot REST API
- `/mobile`: Flutter app (feature-first)
- `/scripts`: dev helpers
- `docker-compose.yml`: Postgres for dev
- `.vscode`: tasks and settings

## Backend
Stack: Spring Boot, Spring Security, JWT, JPA, Flyway, PostgreSQL (dev), H2 (test)

### Minimal endpoints
- `GET /api/health`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/me`
- `GET /api/notes`
- `POST /api/notes`
- `PUT /api/notes/{id}`
- `DELETE /api/notes/{id}`

### Commands
- Run: `cd backend && mvn spring-boot:run`
- Test: `cd backend && mvn test`
- Format: `cd backend && mvn spotless:apply`
- Lint: `cd backend && mvn checkstyle:check`

### Config (.env)
- `DB_URL`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`
- `JWT_SECRET` (min 32 chars)
- `JWT_EXPIRATION_MINUTES`

## Mobile
Stack: Flutter, Riverpod, Dio, go_router, secure storage, dotenv

### Commands
- Run: `cd mobile && flutter run`
- Lint: `cd mobile && flutter analyze`
- Format: `cd mobile && dart format .`

### API_BASE_URL note
- Android emulator: `http://10.0.2.2:8080`
- iOS simulator: `http://localhost:8080`
- Physical device: your machine IP (e.g. `http://192.168.1.10:8080`)

## VS Code
Open the repo root. Available tasks:
- `docker: up`
- `backend: run`
- `backend: test`
- `mobile: run`

## One-command dev
- Windows: `powershell -ExecutionPolicy Bypass -File scripts/dev.ps1 -WithMobile`
- macOS/Linux: `WITH_MOBILE=1 ./scripts/dev.sh`

## How to create the projects from scratch
### Backend (Spring Initializr)
PowerShell:
```powershell
curl.exe https://start.spring.io/starter.zip -o backend.zip -d "type=maven-project" -d "language=java" -d "bootVersion=3.3.2" -d "baseDir=backend" -d "groupId=com.template" -d "artifactId=template-backend" -d "name=template-backend" -d "packageName=com.template.backend" -d "javaVersion=21" -d "dependencies=web,security,data-jpa,validation,postgresql,flyway"
```

macOS/Linux:
```bash
curl https://start.spring.io/starter.zip -o backend.zip \
  -d "type=maven-project" \
  -d "language=java" \
  -d "bootVersion=3.3.2" \
  -d "baseDir=backend" \
  -d "groupId=com.template" \
  -d "artifactId=template-backend" \
  -d "name=template-backend" \
  -d "packageName=com.template.backend" \
  -d "javaVersion=21" \
  -d "dependencies=web,security,data-jpa,validation,postgresql,flyway"
unzip backend.zip
```

### Mobile (Flutter)
```bash
flutter create --org com.template --project-name template_mobile mobile
```

## Rename guide
### Backend
1) Change `groupId`, `artifactId`, `name` in `backend/pom.xml`.
2) Rename the Java package (folder + `package` statements).
3) Update `spring.application.name` in `backend/src/main/resources/application.yml`.

### Mobile
1) Change `name:` in `mobile/pubspec.yaml`.
2) Update `applicationId` in `mobile/android/app/build.gradle`.
3) Update `PRODUCT_BUNDLE_IDENTIFIER` in `mobile/ios/Runner.xcodeproj`.
4) If you use `flutter create`, set `--org` to the new bundle ID.

## Versions and upgrades
- Java: LTS 21 for new APIs and long support. For Java 17, change `java.version` in `backend/pom.xml`.
- Spring Boot: 3.3.x is stable. When Spring Boot 4 is stable, update the parent in `backend/pom.xml` and rerun tests.
- Flutter: use stable channel (`flutter channel stable`). Check with `flutter --version`.

## Template checklist (10 minutes)
- [ ] Rename backend and mobile (see Rename guide)
- [ ] Copy `.env` from `.env.example`
- [ ] `docker compose up -d`
- [ ] `cd backend && mvn spring-boot:run`
- [ ] `cd mobile && flutter run`
- [ ] Open Swagger UI and verify `/api/health`