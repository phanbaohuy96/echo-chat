# EchoChat TODOs

## Phase 1 — Project setup

- [x] Copy `mobile-flutter-core` template into `EchoChat` without template git history.
- [x] Initialize fresh git repository.
- [x] Add project docs and `CLAUDE.md`.
- [x] Add separate FE/BE env examples.

## Phase 2 — Dart Frog backend

- [x] Create `apps/backend` Dart Frog project.
- [x] Add `GET /health`.
- [x] Add `POST /api/auth/signup`.
- [x] Add `POST /api/auth/signin`.
- [x] Add `GET /api/auth/me`.
- [x] Add `POST /api/chat/messages`.
- [x] Add in-memory user/token/message store.
- [x] Add backend tests for health, auth, and chat.

## Phase 3 — Shared client DTOs

- [x] Add `username` to `UserModel`.
- [x] Add signin request DTO.
- [x] Add signup request DTO.
- [x] Add auth result DTO.
- [x] Add me response DTO.
- [x] Add send message request/response DTOs.
- [x] Regenerate data source exports and JSON files.

## Phase 4 — Flutter API and domain

- [x] Add Retrofit auth/chat endpoints.
- [x] Add `AppApiService` wrapper methods.
- [x] Refactor `AuthUsecase` to call backend signin/signup.
- [x] Update token bootstrap through `/api/auth/me`.
- [x] Add focused chat use cases.
- [x] Regenerate Retrofit and Injectable files.

## Phase 5 — Flutter auth UI

- [x] Replace demo account-selection signin with username/password signin.
- [x] Add signup screen with name/username/password.
- [x] Add signup BLoC.
- [x] Add signup route and coordinator method.
- [x] Navigate to chat after successful signin/signup.

## Phase 6 — Flutter chatbot UI foundation

- [x] Add chat route and coordinator.
- [x] Add chat BLoC.
- [x] Add chat screen with message list and composer.
- [x] Send messages to backend and render demo bot replies.
- [x] Show loading and error states.

## Phase 7 — Migrate to user-to-user chat

- [x] Replace backend chatbot message storage with 1:1 user message storage.
- [x] Add backend `BackendChatMessage` model.
- [x] Add peer listing through `GET /api/chat/users`.
- [x] Change `GET /api/chat/messages?peer_user_id=<id>` to fetch a conversation.
- [x] Change `POST /api/chat/messages` to send to `recipient_user_id` using `client_message_id` idempotency.
- [x] Add backend tests for peer listing, send, idempotent retry, conversation fetch, and invalid recipients.
- [x] Replace chatbot DTOs with user-to-user chat DTOs in `modules/data_source`.
- [x] Add `chatUsers` API contract and client API wrappers.
- [x] Refactor chat use cases around peers, conversations, and user-to-user sends.
- [x] Add chat domain message entity.
- [x] Update `ChatBloc` state/events for peers, selected peer, refresh, send, and error state.
- [x] Update chat UI with peer selector, refresh action, incoming/outgoing message rendering, and no-bot empty states.
- [x] Update `docs/backend-api.md` and `docs/architecture.md` for remote-first user-to-user chat.

## Phase 8 — Apply local-first best practice

- [x] Add `chatPeer` and `chatMessage` SQLite table names.
- [x] Increase SQLite DB version and add upgrade table creation for chat tables.
- [x] Add `ChatPeerDao` with peer upsert/list/get operations.
- [x] Add `ChatMessageDao` with pending insert, remote upsert, mark sent/failed, conversation query, and outbox query operations.
- [x] Add `ChatLocalRepository` to map SQLite rows to domain chat entities.
- [x] Add `ChatMessageStatus` values: `pending`, `sent`, `failed`.
- [x] Extend chat domain messages with status, error, and local/remote IDs.
- [x] Refactor chat use cases to load cached peers/messages first and sync remote second.
- [x] Queue outgoing messages locally before remote send.
- [x] Update sent/failed status after backend sync.
- [x] Add retry support using the same `client_message_id`.
- [x] Update chat BLoC with retry/sync state.
- [x] Update chat UI with pending/sent/failed indicators and failed-message retry.
- [x] Verify cached messages render after app restart before remote refresh.
- [x] Update docs with the final local-first flow.

## Phase 9 — Scale local-first sync

- [x] Add backend cursor parameters for newer-message delta sync and older-history pagination.
- [x] Add sync metadata to chat conversation responses.
- [x] Add future-safe message fields: `updated_at`, `deleted_at`, and `version`.
- [x] Add `chatConversationSync` SQLite metadata table.
- [x] Batch remote message upserts into SQLite.
- [x] Use existing cursor listing helper style for older-history loading.
- [x] Update README and API docs for delta sync and pagination.

## Phase 10 — Tooling and verification

- [x] Add backend make targets.
- [x] Update clean tooling for pure Dart backend packages if needed.
- [x] Run backend tests.
- [x] Run Flutter code generation.
- [x] Run Flutter analyzer/tests.
- [ ] Manually verify signup, signin, and chat against local backend.
