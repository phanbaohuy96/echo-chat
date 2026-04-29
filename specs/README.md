# EchoChat Specs

Specs are the source of truth for planned feature behavior before implementation. Keep them short, implementation-facing, and linked to the existing architecture docs instead of duplicating long explanations.

## Workflow

1. Copy `template.md` into `features/NNNN-feature-name.md`.
2. Set the status to `Draft` and fill only sections that matter for the feature.
3. Review the spec before coding and change the status to `Approved`.
4. Implement against the architecture mapping in the spec.
5. Check off acceptance criteria and verification steps as work is completed.
6. Mark the spec `Verified` only after the relevant automated checks and manual smoke test pass.

## Status values

- `Draft` — still being shaped; do not implement yet unless explicitly agreed.
- `Approved` — ready for implementation.
- `Implementing` — implementation is in progress.
- `Verified` — implemented and verified.
- `Deferred` — intentionally paused.

## EchoChat spec boundaries

Map feature behavior to the repository boundaries already used by EchoChat:

- Flutter presentation: `apps/main/lib/presentation/modules/<feature>`
- Domain use cases: `apps/main/lib/domain/usecases`
- Local data and SQLite: `apps/main/lib/data`
- Shared DTOs: `modules/data_source`
- Retrofit API declarations: `core/lib/data/data_source/remote/repository/rest_api_repository/rest_api_repository.dart`
- API wrappers: `core/lib/data/data_source/remote/app_api_service.dart`
- Dart Frog routes: `apps/backend/routes/api`
- Backend services: `apps/backend/lib/src/services`
- API documentation: `docs/backend-api.md`

Specs should call out generated-code impacts and verification commands when these boundaries change.
