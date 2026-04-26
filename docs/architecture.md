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

Requires `Authorization: Bearer <token>` and returns the selected peer plus ordered direct messages between the authenticated user and that peer.

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

1. Chat screen loads available peers through `ChatUsecase`.
2. User selects a peer and Chat BLoC fetches that conversation.
3. User sends a message from the composer.
4. Chat BLoC calls `ChatUsecase` with `recipient_user_id` and `client_message_id`.
5. Backend validates bearer token, applies idempotency, stores the message, and returns it.
6. Chat BLoC appends the returned message and refresh can reload the remote conversation.
