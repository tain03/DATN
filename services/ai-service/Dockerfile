# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /build

# Install dependencies
RUN apk add --no-cache git

# Copy go mod files
COPY services/ai-service/go.mod services/ai-service/go.sum ./services/ai-service/

# Change to service directory and download dependencies
WORKDIR /build/services/ai-service
RUN go mod download

# Copy source code
COPY services/ai-service/ ./

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates postgresql-client curl

WORKDIR /root/

# Copy the binary from builder
COPY --from=builder /build/services/ai-service/main .

# Expose port
EXPOSE 8085

# Run the application
CMD ["./main"]

