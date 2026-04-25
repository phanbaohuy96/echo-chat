# Flutter Template Skills for EchoChat

## Feature structure

Create app features under:

```text
apps/main/lib/presentation/modules/<feature>/
```

Recommended shape:

```text
<feature>/
  <feature>_route.dart
  <feature>_coordinator.dart
  <screen>/
    bloc/
    views/
```

Mirror the existing auth module style when adding new routed screens.

## BLoC and state

Use BLoC for non-trivial feature state. Use Freezed when the state/events have multiple variants or need copy semantics.

Typical responsibilities:

- screen input submission
- loading state
- success/failure state
- transient result completion when the existing UI pattern needs a completer

Do not put HTTP calls directly in widgets.

## Routing

Register routes through `IRoute` implementations and aggregate them in `RouteGenerator`.

Use coordinator extensions on `BuildContext` for navigation, for example:

```dart
context.openSignIn();
context.openChat();
```

Avoid ad-hoc route strings scattered through widgets.

## Domain/usecases

Put orchestration in:

```text
apps/main/lib/domain/usecases/<feature>/
```

Usecases should call API services and local managers, then return domain-level results for BLoCs.

## API and models

Use these locations:

- shared JSON DTOs: `modules/data_source/lib/src/data/models`
- Retrofit endpoint declarations: `core/lib/data/data_source/remote/repository/rest_api_repository/rest_api_repository.dart`
- API wrapper methods: `core/lib/data/data_source/remote/app_api_service.dart`

Run generation after changing JsonSerializable, Retrofit, Injectable, or Freezed files.

## Localization

The template supports generated localization. For stable product copy, add strings through the localization flow instead of hardcoding.

Demo-only copy can be hardcoded temporarily, but should be migrated before production-style polish.

## Theme and UI

Prefer existing template theme helpers:

- `context.theme`
- `context.themeColor`
- app text theme extensions
- shared UI widgets from `fl_ui`

Avoid introducing a second design system for EchoChat.

## Auth and persistence

Use existing local storage:

- token: `CoreLocalDataManager.setToken`
- current user: app `LocalDataManager.saveUserInfo`

Do not create duplicate token storage.

## Verification

For frontend changes, run the app and manually test the feature. For EchoChat, the minimum manual pass is:

1. Start Dart Frog backend.
2. Launch Flutter app with local backend URL.
3. Signup with name, username, and password.
4. Confirm navigation to chat.
5. Send a chat message and see a backend reply.
6. Sign in again with the created credentials.
