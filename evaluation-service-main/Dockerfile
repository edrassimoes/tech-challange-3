FROM golang:1.27-alpine AS builder

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /evaluation-service .

FROM alpine:3.24

WORKDIR /app

COPY --from=builder /evaluation-service ./evaluation-service

EXPOSE 8004
CMD ["./evaluation-service"]
