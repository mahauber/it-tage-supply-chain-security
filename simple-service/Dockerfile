# Build stage
FROM golang:1.25.5-alpine3.23@sha256:26111811bc967321e7b6f852e914d14bede324cd1accb7f81811929a6a57fea9 AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod ./

# Download dependencies
RUN go mod download

# Copy source code
COPY main.go ./

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o simple-service main.go

# Runtime stage
FROM alpine:3.23.0@sha256:51183f2cfa6320055da30872f211093f9ff1d3cf06f39a0bdb212314c5dc7375

WORKDIR /root/

# Copy the binary from builder
COPY --from=builder /app/simple-service .

# Expose port
EXPOSE 8080

# Run the application
CMD ["./simple-service"]
