FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
EXPOSE 7000
RUN go build -o /kafka-producer

FROM alpine:3.22
WORKDIR /app
COPY --from=builder /kafka-producer /app/kafka-producer
CMD ["/app/kafka-producer"]
