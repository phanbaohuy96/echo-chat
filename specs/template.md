# Feature: <name>

## Status

Draft

## Goal

Describe the user or project outcome this feature enables.

## User stories

- As a <user>, I want <behavior>, so that <reason>.

## Scope

### In

- 

### Out

- 

## UX behavior

- Screens/routes:
- Empty/loading/error states:
- Navigation:
- Responsive behavior:

## API contract

- Backend route(s):
- Request JSON:
- Response JSON:
- Error cases:

## Data and local-first behavior

- Local storage reads/writes:
- Sync behavior:
- Conflict/idempotency rules:

## Architecture mapping

- Flutter presentation:
- Flutter domain use cases:
- Shared DTOs:
- Core API service/Retrofit:
- Backend routes/services:
- Tests/docs/codegen:

## Acceptance criteria

- [ ] 

## Verification

- [ ] Run `make gen_data_source` if shared DTOs or generated exports changed.
- [ ] Run `make gen_core` if Retrofit/core generated inputs changed.
- [ ] Run `make gen_main` if BLoC, Freezed, Injectable, routes, or generated app inputs changed.
- [ ] Run `make test_backend` if backend routes or services changed.
- [ ] Run the narrowest relevant Flutter analyzer/test command.
- [ ] Manually smoke-test signup, signin, navigation to chat, and sending a chat message against the local backend when frontend behavior changes.
