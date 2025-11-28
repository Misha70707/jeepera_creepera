# Architecture Overview

This document provides a high-level overview of the CodeForge AI system architecture.

## Table of Contents
1. [System Architecture](#system-architecture)
2. [Mobile App Architecture](#mobile-app-architecture)
3. [Backend Architecture](#backend-architecture)
4. [Data Flow](#data-flow)
5. [Security Architecture](#security-architecture)
6. [Deployment Architecture](#deployment-architecture)

## System Architecture

CodeForge AI follows a **client-server architecture** with optional offline capabilities.

```
┌─────────────────────────────────────────────────────────────────┐
│                         Mobile Clients                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Android    │  │     iOS      │  │    PWA       │         │
│  │   (Kotlin)   │  │   (Swift)    │  │  (React)     │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                    HTTPS/WSS (TLS 1.3)
                            │
┌───────────────────────────▼─────────────────────────────────────┐
│                      API Gateway / CDN                          │
│              (Cloud CDN, DDoS Protection)                       │
└───────────────────────────┬─────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼────────┐ ┌────────▼────────┐ ┌───────▼──────────┐
│   REST API     │ │  WebSocket API  │ │  Auth Service    │
│   Service      │ │    (Streaming)  │ │  (OAuth, JWT)    │
└───────┬────────┘ └────────┬────────┘ └───────┬──────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼────────┐ ┌────────▼────────┐ ┌───────▼──────────┐
│   AI/ML        │ │   Database      │ │  File Storage    │
│   Service      │ │   (PostgreSQL)  │ │  (GCS/S3)        │
│   (LLM API)    │ │   Redis Cache   │ │                  │
└────────────────┘ └─────────────────┘ └──────────────────┘
```

## Mobile App Architecture

### Clean Architecture + MVVM Pattern

We follow **Clean Architecture** principles with **MVVM** presentation pattern:

```
┌────────────────────────────────────────────────────────────────┐
│                     Presentation Layer                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │     Views    │◄─│  ViewModels  │◄─│    Events    │        │
│  │  (UI/Compose)│  │   (State)    │  │  (User Input)│        │
│  └──────────────┘  └──────┬───────┘  └──────────────┘        │
└─────────────────────────────┼──────────────────────────────────┘
                              │
┌─────────────────────────────▼──────────────────────────────────┐
│                      Domain Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │  Use Cases   │  │   Entities   │  │ Repositories │        │
│  │  (Business   │  │   (Models)   │  │ (Interfaces) │        │
│  │   Logic)     │  │              │  │              │        │
│  └──────────────┘  └──────────────┘  └──────┬───────┘        │
└─────────────────────────────────────────────┼──────────────────┘
                                              │
┌─────────────────────────────────────────────▼──────────────────┐
│                       Data Layer                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │ Repository   │  │  Local DB    │  │  Remote API  │        │
│  │ Impls        │  │  (Room/Core  │  │  (Retrofit/  │        │
│  │              │  │   Data)      │  │  URLSession) │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
└────────────────────────────────────────────────────────────────┘
```

### Key Components

#### Android (Kotlin + Jetpack Compose)

**Presentation Layer**
- `@Composable` functions (UI)
- `ViewModel` (state management)
- `StateFlow` / `LiveData` (reactive state)

**Domain Layer**
- Use Cases (e.g., `SendMessageUseCase`, `GenerateCodeUseCase`)
- Domain Models (pure Kotlin classes, no Android dependencies)
- Repository Interfaces (contracts)

**Data Layer**
- Repository Implementations
- Room Database (local persistence)
- Retrofit + OkHttp (network calls)
- Data Mappers (DTO ↔ Domain Model)

**Dependency Injection**: Hilt (Dagger wrapper)

#### iOS (Swift + SwiftUI)

**Presentation Layer**
- SwiftUI Views
- `@StateObject` ViewModels
- `@Published` properties (Combine)

**Domain Layer**
- Use Cases (protocols + implementations)
- Domain Models (structs/classes)
- Repository Protocols

**Data Layer**
- Repository Implementations
- Core Data (local persistence)
- URLSession + Combine (network)
- Codable (JSON mapping)

**Dependency Injection**: Manual DI or Swinject

### Module Structure

```
mobile/android/app/src/main/kotlin/com/codeforgeai/app/
├── presentation/
│   ├── chat/
│   │   ├── ChatScreen.kt
│   │   ├── ChatViewModel.kt
│   │   └── components/
│   ├── projects/
│   │   ├── ProjectListScreen.kt
│   │   └── ProjectViewModel.kt
│   └── settings/
│       └── SettingsScreen.kt
├── domain/
│   ├── usecases/
│   │   ├── SendMessageUseCase.kt
│   │   ├── GenerateCodeUseCase.kt
│   │   └── CreateProjectUseCase.kt
│   ├── models/
│   │   ├── Message.kt
│   │   ├── Project.kt
│   │   └── User.kt
│   └── repositories/
│       ├── ChatRepository.kt
│       └── ProjectRepository.kt
├── data/
│   ├── repositories/
│   │   ├── ChatRepositoryImpl.kt
│   │   └── ProjectRepositoryImpl.kt
│   ├── local/
│   │   ├── dao/
│   │   │   ├── MessageDao.kt
│   │   │   └── ProjectDao.kt
│   │   └── entities/
│   │       ├── MessageEntity.kt
│   │       └── ProjectEntity.kt
│   ├── remote/
│   │   ├── api/
│   │   │   └── CodeForgeApi.kt
│   │   └── dto/
│   │       ├── MessageDto.kt
│   │       └── ProjectDto.kt
│   └── mappers/
│       ├── MessageMapper.kt
│       └── ProjectMapper.kt
└── di/
    ├── AppModule.kt
    ├── NetworkModule.kt
    └── DatabaseModule.kt
```

## Backend Architecture

### Microservices Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      Load Balancer                           │
└───────────────────────────┬──────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼────────┐ ┌────────▼────────┐ ┌───────▼──────────┐
│  API Gateway   │ │   Auth Service  │ │  User Service    │
│  (Node.js)     │ │   (Node.js)     │ │  (Node.js)       │
│  - Routing     │ │   - JWT         │ │  - Profile       │
│  - Rate Limit  │ │   - OAuth       │ │  - Usage Stats   │
└───────┬────────┘ └────────┬────────┘ └───────┬──────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼────────┐ ┌────────▼────────┐ ┌───────▼──────────┐
│  Chat Service  │ │ Project Service │ │  AI Service      │
│  (Node.js)     │ │   (Node.js)     │ │  (Python)        │
│  - Messages    │ │   - CRUD        │ │  - LLM API       │
│  - Streaming   │ │   - Files       │ │  - Inference     │
└───────┬────────┘ └────────┬────────┘ └───────┬──────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼────────┐ ┌────────▼────────┐ ┌───────▼──────────┐
│  PostgreSQL    │ │     Redis       │ │   File Storage   │
│  (User Data)   │ │    (Cache)      │ │   (GCS/S3)       │
└────────────────┘ └─────────────────┘ └──────────────────┘
```

### Service Responsibilities

**API Gateway**
- Request routing
- Rate limiting
- Authentication verification
- Request/response logging

**Auth Service**
- OAuth 2.0 flows (Google, Apple)
- JWT token generation/validation
- Refresh token rotation
- Session management

**User Service**
- User profile CRUD
- Usage statistics
- Subscription management
- Preferences

**Chat Service**
- Message CRUD
- Conversation history
- WebSocket connections (streaming)
- Message search

**Project Service**
- Project CRUD
- File management
- Cloud sync
- Export functionality

**AI Service**
- LLM API integration (OpenAI, Anthropic)
- Prompt engineering
- Response streaming
- Context management
- Code generation, debugging, security scanning

### Technology Stack (Backend)

**Language**: Node.js 20+ (TypeScript) or Python 3.11+ (FastAPI)

**Frameworks**:
- **Node.js**: Express or Fastify
- **Python**: FastAPI or Django

**Database**:
- **PostgreSQL 15+**: Primary database
- **Redis 7+**: Caching, session storage

**Message Queue** (optional for async tasks):
- **RabbitMQ** or **Google Pub/Sub**

**Monitoring**:
- **Datadog** or **New Relic**: APM
- **Sentry**: Error tracking
- **Prometheus + Grafana**: Metrics (alternative)

**Logging**:
- **Winston** (Node.js) or **Loguru** (Python)
- **Google Cloud Logging** or **AWS CloudWatch**

## Data Flow

### Chat Message Flow

```
1. User types message in mobile app
2. App sends POST /v1/chat/completion
   └─> Includes: message, conversation_id, user_id, context
3. API Gateway validates JWT token
4. Chat Service:
   └─> Saves message to PostgreSQL
   └─> Calls AI Service via REST/gRPC
5. AI Service:
   └─> Retrieves conversation history (context)
   └─> Calls LLM API (OpenAI/Anthropic) with streaming
   └─> Streams response back via Server-Sent Events (SSE)
6. Mobile app receives streaming response
   └─> Updates UI in real-time (word by word)
7. Chat Service saves AI response to database
8. [Optional] Cache common queries in Redis
```

### Project Sync Flow

```
1. User creates/modifies project offline
2. Changes stored in local SQLite/Core Data
3. When online, app initiates sync:
   └─> POST /v1/projects/:id/sync
   └─> Payload: { files: [...], lastSyncTimestamp: "..." }
4. Project Service:
   └─> Checks for conflicts (last-write-wins strategy)
   └─> Saves files to GCS/S3
   └─> Updates metadata in PostgreSQL
   └─> Returns: { syncedFiles: [...], conflicts: [...] }
5. Mobile app updates local database
6. [Optional] Real-time sync via WebSocket for collaborative editing
```

## Security Architecture

### Authentication Flow (OAuth 2.0 + JWT)

```
1. User taps "Sign in with Google/Apple"
2. Mobile app initiates OAuth 2.0 PKCE flow
3. User authenticates with Google/Apple
4. OAuth provider returns authorization code
5. App sends code to Auth Service
6. Auth Service:
   └─> Validates code with OAuth provider
   └─> Creates/updates user in database
   └─> Generates JWT access token (15 min expiry)
   └─> Generates refresh token (30 day expiry)
   └─> Returns: { accessToken, refreshToken, user }
7. Mobile app stores tokens securely:
   └─> iOS: Keychain
   └─> Android: EncryptedSharedPreferences
8. Subsequent API calls include: Authorization: Bearer <accessToken>
9. When access token expires:
   └─> App sends refresh token to /v1/auth/refresh
   └─> Receives new access token (seamless for user)
```

### Data Security

**In Transit**:
- TLS 1.3 for all API calls
- Certificate pinning (mobile apps)
- WSS (WebSocket Secure) for streaming

**At Rest**:
- AES-256 encryption for sensitive data
- PostgreSQL: Transparent Data Encryption (TDE)
- File storage: Server-side encryption (SSE)
- Mobile: Keychain (iOS), Android Keystore

**Code Privacy**:
- User code **NOT** sent to AI by default (offline mode)
- Explicit consent required for cloud AI features
- Code anonymized before LLM processing (strip PII)
- No code retention by AI provider (contractual agreement)

## Deployment Architecture

### Cloud Infrastructure (GCP Example)

```
┌─────────────────────────────────────────────────────────────┐
│                       Cloud CDN                             │
│              (Static assets, global caching)                │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                  Cloud Load Balancer                        │
│            (HTTPS, DDoS protection, SSL)                    │
└─────────────────────────┬───────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────▼────────┐ ┌──────▼──────┐ ┌───────▼────────┐
│   Cloud Run    │ │  Cloud Run  │ │   Cloud Run    │
│  (API Gateway) │ │ (Auth Svc)  │ │  (Chat Svc)    │
│   us-central1  │ │ us-central1 │ │  us-central1   │
└───────┬────────┘ └──────┬──────┘ └───────┬────────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────▼────────┐ ┌──────▼──────┐ ┌───────▼────────┐
│   Cloud SQL    │ │Cloud Memor. │ │  Cloud Storage │
│  (PostgreSQL)  │ │  (Redis)    │ │   (Files)      │
│   Multi-region │ │ us-central1 │ │  Multi-region  │
└────────────────┘ └─────────────┘ └────────────────┘
```

### Kubernetes (Alternative)

For more control, deploy on GKE/EKS with:
- **Ingress Controller**: NGINX or Traefik
- **Service Mesh**: Istio or Linkerd (optional)
- **Auto-scaling**: Horizontal Pod Autoscaler (HPA)
- **Secrets**: Kubernetes Secrets + Sealed Secrets

### CI/CD Pipeline

```
1. Developer pushes code to GitHub (feature branch)
2. GitHub Actions triggers:
   ├─> Run linters (eslint, swiftlint, ktlint)
   ├─> Run unit tests
   ├─> Run integration tests
   └─> Build Docker image (backend)
3. If tests pass:
   └─> Merge to `main` branch
4. Main branch triggers:
   ├─> Build production Docker image
   ├─> Push to Container Registry (GCR/ECR)
   ├─> Deploy to Cloud Run (backend)
   ├─> Upload to TestFlight (iOS beta)
   └─> Upload to Google Play Internal Testing (Android)
5. Manual promotion to production:
   └─> After QA approval, promote to public release
```

## Scalability Considerations

### Horizontal Scaling
- Stateless services (Cloud Run/ECS auto-scales)
- Database read replicas for high read traffic
- Redis cluster for distributed caching

### Caching Strategy
- **Level 1**: In-memory cache (service-level)
- **Level 2**: Redis (shared cache, 5-minute TTL)
- **Level 3**: CDN (static assets, 24-hour TTL)

### Rate Limiting
- **Free tier**: 100 requests/day, 10/min burst
- **Pro tier**: Unlimited, 100/min burst
- Implemented via Redis (sliding window algorithm)

### Database Optimization
- Connection pooling (PgBouncer)
- Query optimization (EXPLAIN ANALYZE)
- Partitioning (by date for messages table)
- Archiving (move old data to cold storage)

## Monitoring & Observability

### Key Metrics

**Mobile App**:
- Crash-free rate (target: >99.9%)
- Cold/hot start time
- API latency (p50, p95, p99)
- Screen render time

**Backend**:
- Request rate (requests/sec)
- Error rate (4xx, 5xx)
- Response time (p50, p95, p99)
- Database query time
- AI API latency

### Alerting

**Critical Alerts** (PagerDuty):
- API error rate >1% for 5 minutes
- API p95 latency >1s for 5 minutes
- Database connection pool exhausted
- Mobile crash rate >0.5%

**Warning Alerts** (Email/Slack):
- API p95 latency >500ms
- Database CPU >80%
- Redis memory >80%

## Disaster Recovery

**Backup Strategy**:
- Database: Continuous replication + daily snapshots (30-day retention)
- Files: S3 versioning + cross-region replication

**Recovery Objectives**:
- RPO (Recovery Point Objective): 5 minutes
- RTO (Recovery Time Objective): 1 hour

**Runbook**:
- Document incident response procedures
- Automate failover to backup region
- Regular disaster recovery drills (quarterly)

## Next Steps

- [API Documentation](../api/README.md)
- [Development Setup](../guides/DEVELOPMENT_SETUP.md)
- [Security Best Practices](SECURITY.md)

---

For questions, email architecture@codeforgeai.app
