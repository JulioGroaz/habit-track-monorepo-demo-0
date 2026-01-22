# FocusFlow Backend

FocusFlow is a Spring Boot backend that powers goals, routines, check-ins, and job applications with offline-first sync.

## Architecture

This service follows a layered architecture to keep responsibilities clean and explicit:

- controller: HTTP endpoints, validation, and request/response shaping.
- service: business rules, ownership enforcement, and sync timestamps.
- repository: persistence access and query composition.
- entity: domain models and shared audit/sync fields.
- dto / mapper: API contracts and translation between transport and persistence models.
- config / security: infrastructure wiring, JWT auth, and OpenAPI metadata.

Each class includes Javadoc that explains its role in the architecture and why it exists.

## Offline Sync Strategy

FocusFlow uses client-generated UUIDs and two timestamps to support offline-first workflows:

- client_updated_at: when the client last edited the record.
- server_updated_at: when the server last accepted a change.

Sync push compares client_updated_at against server_updated_at. If the client is newer (or equal), the server applies the change and updates server_updated_at. If the server is newer, the server returns a conflict payload containing both versions so the client can merge safely. Soft-deleted records are retained with deleted_at and included in sync pulls.

## Security

- JWT tokens include userId claims.
- userId is never trusted from request payloads; the security context is the source of truth.
- Endpoints are scoped to the authenticated user and enforce ownership in services.

## Error Format

Errors follow a consistent envelope:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "field": "message"
    }
  }
}
```

## Running Locally

1) Configure environment variables (see `.env.example`).
2) Start PostgreSQL locally.
3) Run the app:

```bash
mvn spring-boot:run
```

Swagger UI is available at `http://localhost:8080/swagger-ui`.

## API Surface

Base path: `/api/v1`

- `/auth/register` and `/auth/login` for JWT authentication.
- `/goals`, `/routines`, `/checkins`, `/applications` for CRUD with pagination and filtering.
- `/sync/push` and `/sync/pull` for offline synchronization.

## Docker

Build and run with Docker Compose:

```bash
docker compose up --build
```

## Tests

Run unit and integration tests:

```bash
mvn test
```

Testcontainers will launch PostgreSQL automatically for integration tests.
