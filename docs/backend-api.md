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

Returns a page of direct messages with a peer plus sync metadata. Without a cursor, the endpoint returns the latest page.

Optional query parameters:

- `after_created_at` — ISO timestamp or epoch milliseconds; returns messages created after this cursor.
- `after_updated_at` — ISO timestamp or epoch milliseconds; returns messages created or updated after this cursor, including deleted messages.
- `before_created_at` — ISO timestamp or epoch milliseconds; returns the older page before this cursor.
- `limit` — page size, clamped by the backend.

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
      "created_at": "2026-04-25T10:30:00.000Z",
      "updated_at": null,
      "deleted_at": null,
      "version": 1
    }
  ],
  "sync_metadata": {
    "latest_message_created_at": "2026-04-25T10:30:00.000Z",
    "latest_message_updated_at": "2026-04-25T10:30:00.000Z",
    "oldest_message_created_at": "2026-04-25T10:30:00.000Z",
    "has_more_older": false
  }
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
    "created_at": "2026-04-25T10:30:00.000Z",
    "updated_at": null,
    "deleted_at": null,
    "version": 1
  }
}
```

Errors:

- `400` invalid message, missing client message id, or self-chat
- `401` missing or invalid token
- `404` recipient not found

### `DELETE /api/chat/messages/<message_id>`

Deletes a direct message sent by the authenticated user. Deleted messages keep their server id and ordering metadata, but the message body is cleared and `deleted_at` is populated so clients can render a deleted-message placeholder.

Response `200`:

```json
{
  "message": {
    "id": "msg_1",
    "sender_user_id": "user_1",
    "recipient_user_id": "user_2",
    "client_message_id": "client_1",
    "message": "",
    "created_at": "2026-04-25T10:30:00.000Z",
    "updated_at": "2026-04-25T10:35:00.000Z",
    "deleted_at": "2026-04-25T10:35:00.000Z",
    "version": 2
  }
}
```

Errors:

- `400` missing message id
- `401` missing or invalid token
- `403` authenticated user is not the message sender
- `404` message not found
