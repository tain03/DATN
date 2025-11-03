# AI Service - IELTS Platform

AI-powered evaluation service for Writing and Speaking tasks using OpenAI GPT-4 and Whisper.

## Features

- **Writing Evaluation**: AI evaluation of IELTS Writing Task 1 and Task 2 using GPT-4
- **Speaking Evaluation**: Audio transcription (Whisper) + AI evaluation (GPT-4)
- **Prompts Management**: Manage writing and speaking prompts (admin only)
- **Evaluation History**: Track all submissions and evaluations
- **Input Validation**: File size, duration, format, and word count validation
- **Rate Limiting**: Global and per-user rate limits
- **Service Integration**: Automatic updates to User Service and Notification Service

## Architecture

```
User → API Gateway → AI Service → OpenAI API (GPT-4/Whisper)
                              ↓
                         Database (ai_db)
                              ↓
                         User Service (skill stats)
                         Notification Service (notifications)
```

## Setup

### Prerequisites

- Go 1.23+
- PostgreSQL 15+
- Docker & Docker Compose
- OpenAI API Key

### Environment Variables

```bash
# Server
SERVER_PORT=8085

# Database
DB_HOST=postgres
DB_PORT=5432
DB_USER=ielts_admin
DB_PASSWORD=ielts_password_2025
DB_NAME=ai_db

# Auth Service Integration
AUTH_SERVICE_URL=http://auth-service:8081
JWT_SECRET=your_jwt_secret_key_minimum_32_characters_long

# Internal API Authentication
INTERNAL_API_KEY=internal_secret_key_ielts_2025_change_in_production

# OpenAI API (Required)
OPENAI_API_KEY=sk-your-api-key-here

# Service URLs
USER_SERVICE_URL=http://user-service:8082
EXERCISE_SERVICE_URL=http://exercise-service:8083
NOTIFICATION_SERVICE_URL=http://notification-service:8086
```

### Run with Docker

```bash
# Build and start
docker-compose up -d --build ai-service

# Check logs
docker-compose logs -f ai-service

# Stop
docker-compose stop ai-service
```

### Run Locally

```bash
# Set environment variables
export OPENAI_API_KEY=sk-your-api-key
export DB_HOST=localhost
# ... other env vars

# Run
go run cmd/main.go
```

Service runs on port 8085 by default.

## API Endpoints

### User Endpoints (Authentication Required)

#### Writing

- `POST /api/v1/ai/writing/submit` - Submit writing for evaluation
  - Body: `WritingSubmissionRequest`
  - Returns: `WritingSubmissionResponse` with evaluation

- `GET /api/v1/ai/writing/submissions` - List user's writing submissions
  - Query params: `limit` (default: 10), `offset` (default: 0)

- `GET /api/v1/ai/writing/submissions/:id` - Get writing submission detail

- `GET /api/v1/ai/writing/prompts` - List writing prompts
  - Query params: `task_type` (task1/task2), `difficulty` (easy/medium/hard), `is_published` (true/false), `limit`, `offset`

- `GET /api/v1/ai/writing/prompts/:id` - Get writing prompt detail

#### Speaking

- `POST /api/v1/ai/speaking/submit` - Submit speaking (audio file or URL)
  - Content-Type: `multipart/form-data` (with audio file) or `application/json` (with audio_url)
  - Returns: `SpeakingSubmissionResponse` with evaluation

- `GET /api/v1/ai/speaking/submissions` - List user's speaking submissions
  - Query params: `limit`, `offset`

- `GET /api/v1/ai/speaking/submissions/:id` - Get speaking submission detail

- `GET /api/v1/ai/speaking/prompts` - List speaking prompts
  - Query params: `part_number` (1/2/3), `difficulty`, `is_published`, `limit`, `offset`

- `GET /api/v1/ai/speaking/prompts/:id` - Get speaking prompt detail

#### Health

- `GET /health` - Health check (no auth required)

### Admin Endpoints (Admin Role Required)

#### Writing Prompts Management

- `POST /api/v1/admin/ai/writing/prompts` - Create writing prompt
- `PUT /api/v1/admin/ai/writing/prompts/:id` - Update writing prompt
- `DELETE /api/v1/admin/ai/writing/prompts/:id` - Delete writing prompt

#### Speaking Prompts Management

- `POST /api/v1/admin/ai/speaking/prompts` - Create speaking prompt
- `PUT /api/v1/admin/ai/speaking/prompts/:id` - Update speaking prompt
- `DELETE /api/v1/admin/ai/speaking/prompts/:id` - Delete speaking prompt

## Request/Response Examples

### Submit Writing

```bash
curl -X POST http://localhost:8080/api/v1/ai/writing/submit \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "task_type": "task2",
    "task_prompt_text": "Some people think that technology has made our lives more complicated. Discuss both views and give your opinion.",
    "essay_text": "Technology has undoubtedly transformed our daily lives..."
  }'
```

**Response:**
```json
{
  "submission": {
    "id": "uuid",
    "user_id": "uuid",
    "task_type": "task2",
    "status": "completed",
    "word_count": 285,
    "submitted_at": "2025-11-03T..."
  },
  "evaluation": {
    "id": "uuid",
    "overall_band_score": 7.5,
    "task_achievement": 7.0,
    "coherence_cohesion": 7.5,
    "lexical_resource": 8.0,
    "grammatical_range": 7.0,
    "detailed_feedback": "..."
  }
}
```

### Submit Speaking (Multipart)

```bash
curl -X POST http://localhost:8080/api/v1/ai/speaking/submit \
  -H "Authorization: Bearer $TOKEN" \
  -F "audio=@speaking.mp3" \
  -F "part_number=2" \
  -F "task_prompt_text=Describe a memorable journey" \
  -F "audio_duration_seconds=120"
```

### Get Prompts

```bash
curl -X GET "http://localhost:8080/api/v1/ai/writing/prompts?task_type=task2&is_published=true&limit=10" \
  -H "Authorization: Bearer $TOKEN"
```

## Validation Rules

### Writing Validation

- **Task 1**: Minimum 150 words, Maximum 10,000 words
- **Task 2**: Minimum 250 words, Maximum 10,000 words
- **Essay length**: Maximum 50,000 characters

### Audio Validation

- **File size**: Maximum 50 MB
- **Duration**: Maximum 5 minutes (300 seconds)
- **Allowed formats**: mp3, wav, m4a, ogg
- **MIME type**: Validated against whitelist

## Rate Limiting

### Global Rate Limit

- **100 requests per minute** for all API endpoints
- Applied to entire `/api/v1` group
- Returns `429 Too Many Requests` when exceeded

### Submission Rate Limits (Per User)

- **Hourly**: 10 submissions per hour
- **Daily**: 50 submissions per day
- Applied to:
  - `POST /api/v1/ai/writing/submit`
  - `POST /api/v1/ai/speaking/submit`

**Rate Limit Headers:**
- `X-RateLimit-Limit`: Maximum requests allowed
- `X-RateLimit-Remaining`: Remaining requests
- `X-RateLimit-Reset`: Unix timestamp when limit resets

## Service Integration

After successful evaluation, the service automatically:

1. **Updates User Service**:
   - Updates skill statistics (writing/speaking)
   - Updates user progress
   - Records practice time

2. **Sends Notifications**:
   - Sends notification when evaluation completes
   - Includes band score and feedback summary

**Integration Features:**
- Async processing (non-blocking)
- Retry mechanism (3 attempts with exponential backoff)
- Graceful degradation (service continues if integration fails)

## Database Schema

The service uses `ai_db` database with the following main tables:

- `writing_submissions` - Writing submissions
- `writing_evaluations` - Writing evaluation results
- `speaking_submissions` - Speaking submissions with transcripts
- `speaking_evaluations` - Speaking evaluation results
- `writing_prompts` - Writing prompt bank
- `speaking_prompts` - Speaking prompt bank
- `ai_processing_queue` - Processing queue (future use)

See `database/schemas/05_ai_service.sql` for full schema.

## OpenAI API

### Models Used

- **GPT-4** (`gpt-4o`): For writing and speaking evaluation
- **Whisper** (`whisper-1`): For audio transcription

### API Key Setup

1. Get API key from: https://platform.openai.com/api-keys
2. Add billing payment method
3. Set in environment variable: `OPENAI_API_KEY`
4. Verify quota: https://platform.openai.com/account/billing

**Important**: Keep API key secure. Never commit to Git.

## Error Handling

### Validation Errors (400 Bad Request)

```json
{
  "error": "essay word count (100) is below minimum required for task2 (250 words)"
}
```

### Rate Limit Errors (429 Too Many Requests)

```json
{
  "error": "submission rate limit exceeded",
  "message": "You have exceeded the maximum number of submissions per hour (10). Please try again later.",
  "retry_after": 1800.0
}
```

### OpenAI API Errors

- `401 Unauthorized`: Invalid API key
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: OpenAI service error

All errors are logged and returned with appropriate HTTP status codes.

## Development

### Project Structure

```
services/ai-service/
├── cmd/
│   └── main.go              # Entry point
├── internal/
│   ├── config/              # Configuration
│   ├── database/            # Database connection
│   ├── handlers/            # HTTP handlers
│   ├── middleware/          # Auth, rate limiting
│   ├── models/              # Data models & DTOs
│   ├── repository/          # Database operations
│   ├── routes/              # Route definitions
│   ├── service/             # Business logic
│   ├── validation/          # Input validation
│   └── integration_handler/ # Service integration
├── Dockerfile
├── go.mod
└── README.md
```

### Building

```bash
# Build binary
go build -o ai-service ./cmd

# Run tests (if available)
go test ./...

# Code quality
go vet ./...
gofmt -l .
```

### Dependencies

Main dependencies:
- `github.com/gin-gonic/gin` - Web framework
- `github.com/lib/pq` - PostgreSQL driver
- `github.com/ulule/limiter/v3` - Rate limiting
- `github.com/google/uuid` - UUID generation
- `github.com/golang-jwt/jwt/v5` - JWT handling

## Testing

### Manual Testing

1. **Health Check**:
   ```bash
   curl http://localhost:8085/health
   ```

2. **Get Auth Token**:
   ```bash
   TOKEN=$(curl -X POST http://localhost:8080/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"user@example.com","password":"password"}' \
     | jq -r '.data.access_token')
   ```

3. **Submit Writing**:
   ```bash
   curl -X POST http://localhost:8080/api/v1/ai/writing/submit \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d @writing-submission.json
   ```

### Postman Collection

See `postman/IELTS_Platform_API.postman_collection.json` for complete API collection.

## Deployment

### Docker Compose

The service is included in `docker-compose.yml`:

```yaml
ai-service:
  build: ./services/ai-service
  ports:
    - "8085:8085"
  environment:
    - OPENAI_API_KEY=${OPENAI_API_KEY}
    # ... other env vars
  depends_on:
    - postgres
```

### Production Considerations

1. **Environment Variables**: Use secrets management
2. **Rate Limiting**: Consider Redis for distributed rate limiting
3. **Monitoring**: Add metrics and logging
4. **Scaling**: Service is stateless, can scale horizontally
5. **Database**: Use connection pooling for high load

## Troubleshooting

### Service won't start

- Check database connection
- Verify OpenAI API key is set
- Check logs: `docker-compose logs ai-service`

### Validation errors

- Ensure essay meets word count requirements
- Check audio file size and format
- Verify all required fields are provided

### Rate limit issues

- Check rate limit headers in responses
- Wait for reset time or use different endpoint
- Contact admin for limit adjustments (if needed)

### OpenAI API errors

- Verify API key is valid
- Check billing/quota: https://platform.openai.com/account/billing
- Review error message for specific issue

## License

Part of IELTS Learning Platform project.
