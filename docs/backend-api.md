# EchoChat Backend API

Base URL is configured by environment. Local Dart Frog default is expected to be `http://localhost:8080`.

## Health

### `GET /health`

Response `200`:

```json
{ "status": "ok" }
```

## Auth

### `POST /api/auth/signup`

Creates a demo user and returns a bearer token.

Request:

```json
{
  "name": "Jane Doe",
  "username": "jane",
  "password": "secret123"
}
```

Response `200`:

```json
{
  "token": {
    "access_token": "opaque-token",
    "token_type": "Bearer"
  },
  "user": {
    "id": "user_1",
    "name": "Jane Doe",
    "username": "jane"
  }
}
```

Errors:

- `400` invalid or missing fields
- `409` username already exists

### `POST /api/auth/signin`

Authenticates a demo user and returns a bearer token.

Request:

```json
{
  "username": "jane",
  "password": "secret123"
}
```

Response `200` uses the same shape as signup.

Errors:

- `400` invalid or missing fields
- `401` invalid credentials

### `GET /api/auth/me`

Returns the authenticated user.

Headers:

```text
Authorization: Bearer <token>
```

Response `200`:

```json
{
  "user": {
    "id": "user_1",
    "name": "Jane Doe",
    "username": "jane"
  }
}
```

Errors:

- `401` missing or invalid token

## Chat

### `POST /api/chat/messages`

Sends a message and returns a demo assistant reply.

Headers:

```text
Authorization: Bearer <token>
```

Request:

```json
{ "message": "Hello" }
```

Response `200`:

```json
{ "reply": "Demo reply to: Hello" }
```

Errors:

- `400` invalid or empty message
- `401` missing or invalid token
