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

All chat endpoints require:

```text
Authorization: Bearer <token>
```

### `GET /api/chat/users`

Returns users the current account can message. The authenticated user is excluded.

Response `200`:

```json
{
  "users": [
    {
      "id": "user_2",
      "name": "Bob Doe",
      "username": "bob"
    }
  ]
}
```

Errors:

- `401` missing or invalid token

### `GET /api/chat/messages?peer_user_id=<id>`

Returns the remote-first direct-message conversation with a peer.

Response `200`:

```json
{
  "peer": {
    "id": "user_2",
    "name": "Bob Doe",
    "username": "bob"
  },
  "messages": [
    {
      "id": "msg_1",
      "sender_user_id": "user_1",
      "recipient_user_id": "user_2",
      "client_message_id": "client_1",
      "message": "Hello",
      "created_at": "2026-04-25T10:30:00.000Z"
    }
  ]
}
```

Errors:

- `400` missing peer id or self-chat
- `401` missing or invalid token
- `404` peer not found

### `POST /api/chat/messages`

Sends a direct message. The Flutter client queues messages locally before calling this endpoint, then marks each local row `sent` or `failed` from the response. Reusing the same `client_message_id` for the same sender returns the original message without creating a duplicate, which allows failed local messages to retry safely.

Request:

```json
{
  "recipient_user_id": "user_2",
  "client_message_id": "client_1",
  "message": "Hello"
}
```

Response `200`:

```json
{
  "message": {
    "id": "msg_1",
    "sender_user_id": "user_1",
    "recipient_user_id": "user_2",
    "client_message_id": "client_1",
    "message": "Hello",
    "created_at": "2026-04-25T10:30:00.000Z"
  }
}
```

Errors:

- `400` invalid message, missing client message id, or self-chat
- `401` missing or invalid token
- `404` recipient not found
