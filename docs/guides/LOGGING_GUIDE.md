# Zerolog Logging Guide

## Overview
The marketplace backend uses **zerolog** for structured JSON logging with detailed request/response tracking.

## Log Format

All logs are in JSON format with the following structure:

```json
{
  "level": "info",
  "service": "marketplace-api",
  "time": 1736563200,
  "api_call_id": "API_CALL_1736563200123456",
  "method": "POST",
  "uri": "/api/admin/products",
  "message": "REQUEST_START"
}
```

## Log Levels

- **INFO**: Normal operations (status 200-399)
- **WARN**: Client errors (status 400-499)
- **ERROR**: Server errors (status 500+)

## Request Lifecycle Logging

### 1. REQUEST_START
Logged when a request is received:

```json
{
  "level": "info",
  "api_call_id": "API_CALL_1736563200123456",
  "method": "POST",
  "uri": "/api/admin/products",
  "remote_ip": "172.18.0.1",
  "headers": {
    "Authorization": "Bearer eyJ...",
    "Content-Type": "application/json"
  },
  "payload": {
    "category_id": "uuid-here",
    "title": "Product Name",
    "price": 100000
  },
  "message": "REQUEST_START"
}
```

### 2. REQUEST_END
Logged when a request completes:

```json
{
  "level": "info",
  "api_call_id": "API_CALL_1736563200123456",
  "method": "POST",
  "uri": "/api/admin/products",
  "status": 201,
  "latency_ms": 45,
  "bytes_in": 256,
  "bytes_out": 512,
  "message": "REQUEST_END"
}
```

### 3. REQUEST_ERROR
Logged when an error occurs:

```json
{
  "level": "error",
  "api_call_id": "API_CALL_1736563200123456",
  "method": "POST",
  "uri": "/api/admin/products",
  "error": "invalid UUID format",
  "message": "REQUEST_ERROR"
}
```

## Viewing Logs

### Real-time Logs
```powershell
docker-compose logs -f backend
```

### Filter by API Call ID
```powershell
docker-compose logs backend | findstr "API_CALL_1736563200123456"
```

### Last 100 Lines
```powershell
docker-compose logs --tail=100 backend
```

### Filter by Level
```powershell
# Errors only
docker-compose logs backend | findstr "\"level\":\"error\""

# Warnings and errors
docker-compose logs backend | findstr "\"level\":\"warn\" \"level\":\"error\""
```

## Debugging with Logs

### 1. Find the API Call ID
When you get an error in the frontend, check the browser console or network tab for the `X-Request-ID` header.

### 2. Search Logs
```powershell
docker-compose logs backend | findstr "API_CALL_XXXXXXX"
```

### 3. Analyze the Flow
You'll see:
- **REQUEST_START**: What was sent (headers, payload)
- **REQUEST_ERROR**: What went wrong (if any)
- **REQUEST_END**: Final status and timing

## Example: Debugging Create Product Error

**1. Frontend shows "Internal Server Error"**

**2. Check browser network tab:**
- Request ID: `API_CALL_1736563200123456`

**3. Search logs:**
```powershell
docker-compose logs backend | findstr "API_CALL_1736563200123456"
```

**4. Output:**
```json
{"level":"info","api_call_id":"API_CALL_1736563200123456","method":"POST","uri":"/api/admin/products","payload":{"category_id":"invalid-uuid"},"message":"REQUEST_START"}
{"level":"error","api_call_id":"API_CALL_1736563200123456","error":"invalid UUID format","message":"REQUEST_ERROR"}
{"level":"error","api_call_id":"API_CALL_1736563200123456","status":500,"message":"REQUEST_END"}
```

**5. Root cause:** Invalid UUID in category_id

## Log Fields Reference

| Field | Description | Example |
|-------|-------------|---------|
| `level` | Log level | `info`, `warn`, `error` |
| `service` | Service name | `marketplace-api` |
| `time` | Unix timestamp | `1736563200` |
| `api_call_id` | Unique request ID | `API_CALL_1736563200123456` |
| `method` | HTTP method | `POST`, `GET`, `PUT`, `DELETE` |
| `uri` | Request URI | `/api/admin/products` |
| `remote_ip` | Client IP | `172.18.0.1` |
| `headers` | Request headers | `{"Authorization": "..."}` |
| `payload` | Request body | `{"title": "..."}` |
| `status` | HTTP status code | `200`, `400`, `500` |
| `latency_ms` | Request duration | `45` (milliseconds) |
| `bytes_in` | Request size | `256` |
| `bytes_out` | Response size | `512` |
| `error` | Error message | `"invalid UUID format"` |
| `message` | Log message | `REQUEST_START`, `REQUEST_END`, `REQUEST_ERROR` |

## Production Tips

1. **Use Log Aggregation**: Send logs to ELK, Datadog, or CloudWatch
2. **Set Log Retention**: Configure log rotation to prevent disk full
3. **Monitor Error Rates**: Alert on high error rates
4. **Trace Requests**: Use `api_call_id` to trace requests across services
5. **Redact Sensitive Data**: Remove passwords, tokens from logs in production

## Configuration

Logging is configured in `cmd/server/main.go`:

```go
zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
logger := zerolog.New(os.Stdout).With().
    Timestamp().
    Str("service", "marketplace-api").
    Logger()
```

To change log format or add global fields, modify this section.
