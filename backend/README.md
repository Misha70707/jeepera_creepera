# CodeForge AI Backend

Backend services for CodeForge AI mobile application.

## Architecture

The backend follows a microservices architecture with the following services:

- **API Gateway**: Request routing, rate limiting, authentication
- **Auth Service**: OAuth 2.0, JWT token management
- **User Service**: User profiles, usage statistics
- **Chat Service**: Message management, streaming responses
- **Project Service**: Project CRUD, file management, cloud sync
- **AI Service**: LLM integration, code generation, debugging

## Tech Stack

### Primary
- **Language**: Node.js 20+ (TypeScript) or Python 3.11+
- **Framework**: Express/Fastify (Node.js) or FastAPI (Python)
- **Database**: PostgreSQL 15+
- **Cache**: Redis 7+
- **Container**: Docker + Docker Compose

### Dependencies
- **Authentication**: Passport.js (Node.js) or python-jose (Python)
- **ORM**: Prisma (Node.js) or SQLAlchemy (Python)
- **Validation**: Zod (Node.js) or Pydantic (Python)
- **Testing**: Jest (Node.js) or pytest (Python)

## Getting Started

### Prerequisites
- Docker 24+ and Docker Compose
- Node.js 20+ (if using Node.js backend)
- Python 3.11+ (if using Python backend)

### 1. Clone Repository
```bash
git clone https://github.com/Misha70707/tweny_fo_seven_tree_sixty_five.git
cd tweny_fo_seven_tree_sixty_five/backend
```

### 2. Configure Environment
```bash
cp .env.example .env
# Edit .env and fill in your API keys
```

**Required API Keys**:
- OpenAI API key (or Anthropic)
- Firebase project credentials
- Google OAuth credentials
- Apple Sign-In credentials (for iOS)

### 3. Start Services
```bash
# Start PostgreSQL and Redis
docker-compose up -d postgres redis

# Wait for services to be healthy (15-30 seconds)
docker-compose ps

# Optional: Start pgAdmin (database UI)
docker-compose up -d pgadmin
# Access at http://localhost:5050
# Email: admin@codeforgeai.app, Password: admin
```

### 4. Install Dependencies

#### Node.js Backend
```bash
cd api
npm install
```

#### Python Backend
```bash
cd ml-service
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 5. Run Database Migrations

#### Node.js (Prisma)
```bash
cd api
npx prisma migrate dev
npx prisma generate
```

#### Python (Alembic)
```bash
cd ml-service
alembic upgrade head
```

### 6. Seed Database (Optional)
```bash
# Node.js
npm run seed

# Python
python scripts/seed.py
```

### 7. Start Development Server

#### Node.js
```bash
cd api
npm run dev
# Server runs on http://localhost:3000
```

#### Python
```bash
cd ml-service
uvicorn main:app --reload --host 0.0.0.0 --port 8000
# Server runs on http://localhost:8000
```

### 8. Verify Installation
```bash
# Health check
curl http://localhost:3000/health
# Expected: {"status":"ok","timestamp":"..."}

# API docs (if using FastAPI)
open http://localhost:8000/docs
```

## Development

### Project Structure

```
backend/
├── api/                      # Main API service
│   ├── src/
│   │   ├── controllers/      # Request handlers
│   │   ├── services/         # Business logic
│   │   ├── models/           # Database models
│   │   ├── middleware/       # Express middleware
│   │   ├── routes/           # API routes
│   │   ├── utils/            # Helper functions
│   │   └── app.ts            # Express app setup
│   ├── prisma/
│   │   ├── schema.prisma     # Database schema
│   │   └── migrations/       # Migration files
│   ├── tests/                # Unit and integration tests
│   ├── package.json
│   └── tsconfig.json
├── ml-service/               # AI/ML service (Python)
│   ├── app/
│   │   ├── main.py           # FastAPI app
│   │   ├── routers/          # API routers
│   │   ├── services/         # LLM integration
│   │   └── models/           # Pydantic models
│   ├── requirements.txt
│   └── alembic/              # Database migrations
├── infrastructure/           # IaC (Terraform/Pulumi)
│   ├── terraform/
│   └── kubernetes/
├── docker-compose.yml        # Local development setup
├── .env.example              # Environment variables template
└── README.md                 # This file
```

### Database Schema (High-Level)

**Users**
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  display_name VARCHAR(255),
  oauth_provider VARCHAR(50) NOT NULL, -- 'google' or 'apple'
  oauth_id VARCHAR(255) NOT NULL,
  tier VARCHAR(20) DEFAULT 'free', -- 'free' or 'pro'
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Messages**
```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL,
  user_id UUID REFERENCES users(id),
  role VARCHAR(20) NOT NULL, -- 'user' or 'assistant'
  content TEXT NOT NULL,
  language VARCHAR(50), -- Programming language
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_user ON messages(user_id);
```

**Projects**
```sql
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  file_count INTEGER DEFAULT 0,
  total_size_bytes BIGINT DEFAULT 0,
  last_synced_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Files**
```sql
CREATE TABLE files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  path VARCHAR(500) NOT NULL,
  content TEXT,
  language VARCHAR(50),
  size_bytes INTEGER,
  storage_url VARCHAR(500), -- GCS/S3 URL
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(project_id, path)
);
```

### API Endpoints

**Authentication**
- `POST /v1/auth/google` - Google OAuth callback
- `POST /v1/auth/apple` - Apple Sign-In callback
- `POST /v1/auth/refresh` - Refresh access token
- `POST /v1/auth/logout` - Logout user

**Chat**
- `POST /v1/chat/completion` - Send message (streaming via SSE)
- `GET /v1/chat/conversations` - List conversations
- `GET /v1/chat/conversations/:id/messages` - Get messages
- `DELETE /v1/chat/conversations/:id` - Delete conversation

**Projects**
- `GET /v1/projects` - List user projects
- `POST /v1/projects` - Create project
- `GET /v1/projects/:id` - Get project details
- `PUT /v1/projects/:id` - Update project
- `DELETE /v1/projects/:id` - Delete project
- `POST /v1/projects/:id/sync` - Sync project files
- `POST /v1/projects/:id/export` - Export project (zip/github)

**User**
- `GET /v1/user/profile` - Get user profile
- `PUT /v1/user/profile` - Update profile
- `GET /v1/user/usage` - Get usage statistics
- `DELETE /v1/user/account` - Delete account (GDPR)

**Health**
- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics (internal only)

### Testing

#### Unit Tests
```bash
# Node.js
npm test

# Python
pytest
```

#### Integration Tests
```bash
# Node.js
npm run test:integration

# Python
pytest tests/integration
```

#### Load Tests
```bash
# Using k6
k6 run tests/load/api-test.js
```

### Code Quality

#### Linting
```bash
# Node.js
npm run lint
npm run lint:fix

# Python
ruff check .
ruff format .
```

#### Type Checking
```bash
# TypeScript
npm run typecheck

# Python
mypy .
```

## Deployment

### Docker Build

```bash
# API service
docker build -t codeforgeai/api:latest -f api/Dockerfile api/

# ML service
docker build -t codeforgeai/ml-service:latest -f ml-service/Dockerfile ml-service/
```

### Cloud Deployment

#### Google Cloud Run
```bash
# Build and push
gcloud builds submit --tag gcr.io/PROJECT_ID/api

# Deploy
gcloud run deploy api \
  --image gcr.io/PROJECT_ID/api \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars DATABASE_URL=... \
  --max-instances 10
```

#### AWS ECS (Fargate)
See `infrastructure/terraform/aws/` for Terraform configuration.

## Monitoring

### Logs
```bash
# View logs (local)
docker-compose logs -f api

# View logs (production - GCP)
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=api" --limit 50
```

### Metrics

Access Prometheus metrics at `http://localhost:3000/metrics` (protected in production).

**Key Metrics**:
- `http_requests_total` - Total HTTP requests
- `http_request_duration_seconds` - Request latency
- `http_requests_errors_total` - Error count
- `db_query_duration_seconds` - Database query time
- `ai_api_calls_total` - LLM API calls
- `ai_api_latency_seconds` - LLM API latency

### Alerts

Configure alerts in your monitoring tool (Datadog, Grafana):
- API error rate >1% for 5 minutes
- API p95 latency >1s
- Database connection pool exhausted
- High memory usage (>80%)

## Troubleshooting

### Database Connection Fails
```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# Check logs
docker-compose logs postgres

# Restart
docker-compose restart postgres
```

### Redis Connection Fails
```bash
# Check if Redis is running
docker-compose ps redis

# Test connection
docker exec -it codeforge_redis redis-cli -a redis_password ping
# Expected: PONG

# Restart
docker-compose restart redis
```

### Migrations Fail
```bash
# Node.js (Prisma)
npx prisma migrate reset  # WARNING: Deletes all data
npx prisma migrate dev

# Python (Alembic)
alembic downgrade -1
alembic upgrade head
```

### API Returns 500 Errors
- Check `.env` file for missing variables
- Verify API keys are valid
- Check logs: `docker-compose logs api`
- Ensure database migrations are applied

## Security

### Best Practices
- Never commit `.env` files (use `.env.example`)
- Rotate secrets regularly (JWT_SECRET, API keys)
- Use HTTPS in production (TLS 1.3)
- Implement rate limiting
- Validate all inputs
- Use parameterized SQL queries
- Keep dependencies updated

### Security Scans
```bash
# Node.js
npm audit
npm audit fix

# Python
pip-audit
```

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

## License

Apache License 2.0 - See [LICENSE](../LICENSE)

## Support

- **Documentation**: [docs/](../docs/)
- **Issues**: [GitHub Issues](https://github.com/Misha70707/tweny_fo_seven_tree_sixty_five/issues)
- **Email**: dev@codeforgeai.app

---

**Happy Coding!** 🚀
