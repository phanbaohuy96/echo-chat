# EchoChat Architecture

## Overview

EchoChat is a demo chat monorepo built from a Flutter core template.

- `apps/main` — Flutter client.
- `apps/backend` — Dart Frog backend.
- `core` — shared Flutter/client infrastructure such as routing, API clients, local storage, theme, and base widgets.
- `modules/data_source` — shared client-side models and DTOs.
- `plugins` — reusable Flutter packages from the template.

## Client/backend boundary

The backend owns business logic:

- account registration
- signin credential checks
- bearer token issuance
- current-user lookup
- chat reply generation

The Flutter client owns presentation logic:

- auth forms
- local token/user persistence
- navigation
- BLoC state
- chat rendering

## Environment policy

Use separate env files:

- `apps/main/.env` for Flutter client config.
- `apps/backend/.env` for backend server config.

Do not use one shared `.env`. Flutter env values may be compiled into the app and must not contain backend secrets. Backend env can contain server-only values.

Safe examples belong in:

- `apps/main/.env.example`
- `apps/backend/.env.example`

## API contract summary

### Signup

`POST /api/auth/signup`

Request:

```json
{ "name": "Jane Doe", "username": "jane", "password": "secret123" }
```

Response:

```json
{
  "token": { "access_token": "opaque-token", "token_type": "Bearer" },
  "user": { "id": "user_1", "name": "Jane Doe", "username": "jane" }
}
```

### Signin

`POST /api/auth/signin`

Request:

```json
{ "username": "jane", "password": "secret123" }
```

Response uses the same shape as signup.

### Current user

`GET /api/auth/me`

Requires `Authorization: Bearer <token>`.

### List chat peers

`GET /api/chat/users`

Requires `Authorization: Bearer <token>` and returns public users except the authenticated account.

### Fetch chat conversation

`GET /api/chat/messages?peer_user_id=<id>`

Requires `Authorization: Bearer <token>` and returns the selected peer, an ordered message page, and sync metadata.

Optional cursors:

- `after_created_at` for newer-message delta refresh.
- `before_created_at` plus `limit` for older-history pagination.

### Send chat message

`POST /api/chat/messages`

Requires `Authorization: Bearer <token>`.

Request:

```json
{
  "recipient_user_id": "user_2",
  "client_message_id": "client_1",
  "message": "Hello"
}
```

Response:

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

## Data flow

Signin/signup flow:

1. User submits form in Flutter.
2. Auth BLoC calls `AuthUsecase`.
3. `AuthUsecase` calls `AppApiService`.
4. `AppApiService` calls Retrofit repository.
5. Backend returns token and user.
6. Client stores token/user through `LocalDataManager`.
7. Auth screen navigates to chat.

Chat flow:

1. Chat screen asks `ChatPeersUsecase` and `ChatConversationUsecase` for cached peers and cached conversation messages from SQLite.
2. Chat BLoC renders cached data immediately, then syncs peers and the selected conversation from the backend.
3. Synced peers/messages are upserted into local `chatPeer` and `chatMessage` tables before the UI is refreshed from the local cache.
4. User sends a message from the composer.
5. Chat BLoC uses `ChatOutboxUsecase` to queue the outgoing message locally with `pending` status and a stable `client_message_id`.
6. `ChatOutboxUsecase` posts the queued message to the backend; success marks it `sent` with the remote id/timestamp, while failure marks it `failed` with an error message.
7. Failed messages can be retried with the original `client_message_id`, relying on backend idempotency to avoid duplicate remote messages.
8. Manual refresh drains pending outbox rows, calls the backend with `after_created_at`, batch upserts newer messages, updates `chatConversationSync`, and re-reads SQLite.
9. Scrolling near the top calls the backend with `before_created_at` and a page limit, batch upserts older history, and re-reads SQLite without duplicates.
