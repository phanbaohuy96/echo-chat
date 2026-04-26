# EchoChat Claude Instructions

## Project identity

EchoChat is a demo chat monorepo created from the Flutter core template. The template is only the starting point; do not make changes outside this repository for EchoChat work.

## Repository rules

- Work from `/Users/huy.phan/personal/projects/Flutter/EchoChat`.
- Do not edit the template project unless the user explicitly asks.
- Do not commit changes unless the user explicitly asks for a commit.
- Never commit `.env`, credentials, tokens, keystores, or generated secrets.
- Use separate env files for FE and BE:
  - Flutter client: `apps/main/.env`
  - Dart Frog backend: `apps/backend/.env`
- Keep `.env.example` files safe and non-secret.

## Architecture rules

- `apps/main` is the Flutter client.
- `apps/backend` is the Dart Frog backend.
- `core` contains reusable Flutter/client infrastructure.
- `modules/data_source` contains shared client-side data models and DTOs.
- `plugins/*` contains reusable Flutter packages from the template.

## Flutter rules

- Follow feature folders under `apps/main/lib/presentation/modules/<feature>`.
- Use BLoC/Freezed for non-trivial screen state.
- Register app routes through `IRoute` classes and `RouteGenerator`.
- Use coordinator extensions on `BuildContext` for feature navigation.
- Keep domain orchestration in `apps/main/lib/domain/usecases`.
- Use `LocalDataManager` for token/user persistence.
- Put shared API DTOs in `modules/data_source`.
- Put Retrofit endpoint declarations in `core/lib/data/data_source/remote/repository/rest_api_repository/rest_api_repository.dart`.
- Add AppApiService wrappers in `core/lib/data/data_source/remote/app_api_service.dart`.
- Reuse theme helpers such as `context.theme`, `themeColor`, and template widgets before hardcoding styles.
- Use localization for stable user-facing copy when a feature moves beyond demo-only text.

## Backend rules

- Keep Dart Frog business logic in services under `apps/backend/lib/src/services`.
- Keep route handlers thin; validate input, call services, return responses.
- Use in-memory storage for v1 demo only.
- Keep token/auth checks centralized in backend auth helpers/services.
- Do not expose backend secrets to the Flutter client.

## Code generation

Run code generation after editing Freezed, Injectable, JsonSerializable, or Retrofit files:

- `make gen_data_source`
- `make gen_core`
- `make gen_main`

If backend code later uses codegen, add a backend-specific target instead of silently folding it into Flutter generation.

## Verification expectations

For frontend changes, run the app and manually exercise the feature before reporting completion. For EchoChat, verify signup, signin, navigation to chat, and sending a chat message against the local backend.
