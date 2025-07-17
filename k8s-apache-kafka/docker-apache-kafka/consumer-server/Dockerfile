FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o /kafka-consumer

FROM alpine:3.22
WORKDIR /app
COPY --from=builder /kafka-consumer /app/kafka-consumer
CMD ["/app/kafka-consumer"]
