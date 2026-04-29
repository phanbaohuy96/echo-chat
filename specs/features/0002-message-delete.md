# Feature: Message delete

## Status

Verified

## Goal

Allow a signed-in user to delete their own direct chat messages while preserving EchoChat's local-first behavior and keeping remote sync deterministic.

## User stories

- As a sender, I want to delete a message I sent, so that it no longer appears as active content in the conversation.
- As a chat participant, I want deleted messages to sync consistently across refreshes, so local cache and backend state do not diverge.

## Scope

### In

- Let users delete only messages they sent.
- Represent deleted messages with `deleted_at` instead of physically removing server-confirmed messages.
- Remove or hide deleted message content from the conversation UI.
- Sync deleted state from backend to local SQLite.
- Keep local-first rendering: the UI reads final state from SQLite.
- Cover delete behavior in backend tests and relevant Flutter/domain tests.

### Out

- Editing messages.
- Deleting another user's messages.
- Hard-deleting server-confirmed messages from backend storage.
- Bulk delete or clear conversation.
- Push notifications or real-time remote delete events.
- Undo after delete.

## UX behavior

- Screens/routes: reuse the existing chat conversation screen under `apps/main/lib/presentation/modules/chat/conversation`.
- Entry point: expose delete on an outgoing message, such as a long-press/context action on the message bubble.
- Confirmation: ask for confirmation before deleting a sent message.
- Pending messages: deleting a pending local-only message should remove it locally and prevent future sending if it has not reached the backend.
- Failed messages: deleting a failed message should remove it locally and stop retrying it.
- Sent messages: deleting a sent message should call the backend, cache the deleted message response, then keep the SQLite-backed UI in sync.
- Incoming messages: no delete action is shown for messages sent by the peer.
- Deleted messages: show a neutral deleted-message placeholder and do not show the original message text after deletion.
- Empty/loading/error states: preserve the current chat loading, syncing, sending, and retry error behavior.
- Navigation: no route changes.
- Responsive behavior: delete action must work on mobile and desktop/web pointer interactions.

## API contract

- Backend route(s): add delete behavior for `DELETE /api/chat/messages/<message_id>` and document it in `docs/backend-api.md`.
- Request JSON: no request body is required because the message id is in the route path.
- Response JSON: return the deleted message using the existing chat message shape with `deleted_at` populated and `version` incremented.
- Error cases:
  - `400` invalid or missing message id.
  - `401` missing or invalid token.
  - `403` authenticated user is not the message sender.
  - `404` message not found.

## Data and local-first behavior

- Local storage reads/writes:
  - Preserve existing `chatMessage.deleted_at` support.
  - Add DAO/repository operations to delete local-only messages and cache remote deleted messages.
  - For pending or failed local-only messages, local hard-delete is acceptable because no server-confirmed row exists.
- Sync behavior:
  - Conversation refresh must upsert remote deleted messages into SQLite.
  - The final UI state must still come from SQLite, not directly from the delete API response.
- Conflict/idempotency rules:
  - Deleting an already deleted server message should be idempotent and return the deleted message state.
  - Only the sender can delete their own message.
  - A pending message deleted locally must not be sent later by outbox sync.
  - `remote_id` remains the server identity for sent messages.
  - `client_message_id` continues to deduplicate send retries, not delete requests.

## Architecture mapping

- Flutter presentation:
  - Update chat message widgets/actions in `apps/main/lib/presentation/modules/chat/conversation/views`.
  - Add BLoC event/state handling in `apps/main/lib/presentation/modules/chat/conversation/bloc`.
- Flutter domain use cases:
  - Add delete behavior to the focused chat use case that owns outbox/message mutation, or create a narrow delete use case if keeping responsibilities clearer.
  - Update local repository/DAO calls under `apps/main/lib/data`.
- Shared DTOs:
  - Add request/response DTOs in `modules/data_source` only if the chosen API response cannot reuse existing `ChatMessage` parsing.
- Core API service/Retrofit:
  - Add the Retrofit endpoint in `core/lib/data/data_source/remote/repository/rest_api_repository/rest_api_repository.dart`.
  - Add an `AppApiService` wrapper in `core/lib/data/data_source/remote/app_api_service.dart`.
- Backend routes/services:
  - Add Dart Frog route handling under `apps/backend/routes/api/chat`.
  - Keep route validation thin and put delete rules in `apps/backend/lib/src/services/chat_service.dart`.
  - Update in-memory storage behavior in `apps/backend/lib/src/store/demo_store.dart` if needed.
- Tests/docs/codegen:
  - Add backend tests for successful delete, idempotent delete, deleting another user's message, missing/invalid token, and missing message.
  - Add Flutter/domain tests for pending, failed, and sent delete behavior.
  - Update `docs/backend-api.md` with request/response/error examples.
  - Run generated-code commands if DTO, Retrofit, Injectable, or Freezed inputs change.

## Acceptance criteria

- [x] Outgoing sent messages expose a delete action.
- [x] Incoming messages do not expose a delete action.
- [x] Users confirm before deleting a sent message.
- [x] Deleting a pending message removes it locally and prevents later outbox send.
- [x] Deleting a failed message removes it locally and prevents retry.
- [x] Deleting a sent message calls the backend, caches the deleted message response, and renders a neutral placeholder from the refreshed local SQLite state.
- [x] Backend rejects deletion by non-senders.
- [x] Backend delete is idempotent for already deleted messages.
- [x] Conversation refresh preserves deleted state in local SQLite.
- [x] API docs describe the delete endpoint and errors.

## Verification

- [x] Run `make gen_data_source` if shared DTOs or generated exports changed.
- [x] Run `make gen_core` if Retrofit/core generated inputs changed.
- [x] Run `make gen_main` if BLoC, Freezed, Injectable, routes, or generated app inputs changed.
- [x] Run `make test_backend` after backend route/service changes.
- [x] Run the narrowest relevant Flutter analyzer/test command.
- [x] Manually smoke-test signup, signin, navigation to chat, send message, delete own sent message, verify peer cannot delete it, and refresh/restart behavior against the local backend.
