# Stage 1: Build Go binary
FROM golang:1.24.5-alpine3.22 AS builder

WORKDIR /build

COPY go.mod .
# COPY go.sum .
RUN go mod download

COPY . .

ENV CGO_ENABLED=0 GOARCH=amd64 GOOS=linux
RUN go build -o users-service .

# Stage 2: Create a lightweight image (using alpine)
FROM alpine:3.22

WORKDIR /app
COPY --from=builder /build/users-service .

EXPOSE 8000
ENTRYPOINT ["./users-service"]
