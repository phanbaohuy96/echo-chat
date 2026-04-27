---
name: localization
description: Adds and updates app strings through the CSV → ARB → generated localizations workflow
license: MIT
compatibility: all
metadata:
  audience: flutter-developers
  framework: flutter
  pattern: localization
---

# Localization Skill

## When to use

- Adding or changing translatable strings.
- Renaming or removing localization keys.
- Updating English or Vietnamese copy.
- Adding a new locale to EchoChat.

## Workflow

The CSV files are the source of truth — **never** hand-edit generated ARB or localization Dart files.

Current supported locales:

- English: `en` — primary/default locale
- Vietnamese: `vi` — secondary locale

Localization sources:

```text
apps/main/lib/l10n/
├── localizations.csv        # app source of truth: key,en,vi
├── intl_en.arb              # generated from CSV
├── intl_vi.arb              # generated from CSV
├── localization_ext.dart    # context/app localization helpers
└── generated/
    ├── app_localizations.dart
    ├── app_localizations_en.dart
    └── app_localizations_vi.dart

core/lib/l10n/
├── localizations.csv        # shared core strings: key,en,vi
├── intl_en.arb
├── intl_vi.arb
├── localization_ext.dart
└── generated/
    ├── core_localizations.dart
    ├── core_localizations_en.dart
    └── core_localizations_vi.dart

plugins/fl_media/lib/src/l10n/
├── localizations.csv        # media plugin strings: key,en,vi
├── intl_en.arb
├── intl_vi.arb
├── localization_ext.dart
└── generated/
    ├── fl_media_localizations.dart
    ├── fl_media_localizations_en.dart
    └── fl_media_localizations_vi.dart
```

Each package has an `l10n.yaml`; the root `make lang` target regenerates all three localization sets:

```bash
make lang
```

That runs the custom CSV → ARB generator and then Flutter `gen-l10n` for `apps/main`, `core`, and `plugins/fl_media`.

## CSV format

The header is currently `key,en,vi`. One row per string.

```csv
key,en,vi
inform,Inform,Thông báo
ok,Ok,Đồng ý
loginRequired,Please login to continue,Vui lòng đăng nhập để tiếp tục
welcomeMessage,"Welcome, {0}!","Xin chào, {0}!"
```

Rules:

- Key names are lowerCamelCase and describe meaning (`loginRequired`, not `auth_msg_2`).
- Keep keys flat across the package. If two screens need different copy, use distinct keys.
- Quote values containing commas or newlines.
- Parameters are **positional** (`{0}`, `{1}`, …); do not use named placeholders.
- Fill every locale column. The custom CSV → ARB step writes cells as-is, so empty cells produce empty translations rather than a reliable fallback.
- Prefer renaming stale brand-specific keys to neutral names when the semantic meaning changed, e.g. `poweredByEchoChat` → `poweredByApp`.

## Choosing the right CSV

- App/module screen copy: `apps/main/lib/l10n/localizations.csv`
- Shared widgets, dialogs, errors, permissions, date range labels: `core/lib/l10n/localizations.csv`
- Media picker/viewer copy: `plugins/fl_media/lib/src/l10n/localizations.csv`

Do not duplicate a shared string into app CSV if it already belongs in `core` or `fl_media`.

## Using strings in the UI

In app screens, use the generated app localizations helper:

```dart
class _FeatureScreenState extends StateBase<FeatureScreen> {
  @override
  Widget build(BuildContext context) {
    return ScreenForm(title: l10n.featureTitle, child: ...);
  }
}
```

For methods with many localized strings, a local variable is fine:

```dart
@override
Widget build(BuildContext context) {
  final l10n = context.l10n;
  return Text(l10n.welcomeMessage('Huy'));
}
```

Older screens may use `translate(context)` from `apps/main/lib/presentation/extentions/localization.dart`; keep that style when making small local edits unless the surrounding file already uses `context.l10n`.

For shared `core` strings, use `context.coreL10n` / `coreL10n` from `core/lib/l10n/`. For `fl_media`, use `context.flMediaL10n` / `flMediaL10n` from `plugins/fl_media/lib/src/l10n/`.

## Locale wiring

Locale infrastructure lives in:

- `core/lib/common/constants/locale/app_locale.dart`
- `apps/main/lib/app_delegate.dart`
- `apps/main/lib/presentation/app.dart`
- `core/lib/common/calendar.dart`
- `core/lib/presentation/extentions/context_extention.dart`

`MaterialApp.supportedLocales` is wired from `AppLocale.supportedLocales`, not directly from generated app localizations. When changing the locale set, update `AppLocale`, app bootstrap locale messages, date/calendar helpers, and all three CSV files.

## Adding a new locale

1. Add the locale column to every relevant CSV, e.g. `key,en,vi,ja`.
2. Fill in every existing row for the new locale.
3. Add the locale to `core/lib/common/constants/locale/app_locale.dart` and `supportedLocales`.
4. Update app bootstrap locale messages in `apps/main/lib/app_delegate.dart` if the locale needs timeago/date messages.
5. Add/update date locale helpers if the app formats dates with package-specific labels.
6. Run `make lang`.
7. Verify generated files include `intl_<locale>.arb` and `*_localizations_<locale>.dart` for each affected package.
8. Search for stale locale references from the removed/replaced locale.

## Translation round-trip

For sending app strings out to translators and folding results back, the template ships:

- `make gen_translation` — emits a CSV with status columns ready for translators.
- `make apply_translation` — folds the completed CSV back into `apps/main/lib/l10n/localizations.csv`.

See:

- `tools/module_generator/bin/generate_translation_csv.dart`
- `tools/module_generator/bin/apply_translation.dart`

## Verification

After localization changes, run:

```bash
make lang
rg -n "Locale\('th'|intl_th|_th\.dart|AppLocale\.th|ThMessages" .
```

Adjust the search terms when removing or replacing a different locale.

For app-facing strings, also run at least:

```bash
cd apps/main
fvm flutter analyze --no-pub
```

If shared/core strings changed, analyze `core`; if media strings changed, analyze `plugins/fl_media`.

## Checklist

- [ ] Correct CSV file updated (`apps/main`, `core`, or `fl_media`).
- [ ] Values provided for `en` and `vi`.
- [ ] No translation entered directly into generated `*.arb` or `*_localizations_*.dart` files.
- [ ] `make lang` run and generated files updated.
- [ ] Use site reads strings via generated localization APIs, not hardcoded user-facing text.
- [ ] Parameters use positional `{0}`, `{1}` placeholders.
- [ ] Stale locale files/imports removed when replacing a locale.

## Common mistakes

- Editing `intl_en.arb` or `intl_vi.arb` directly — the next `make lang` overwrites it.
- Adding only app CSV strings when the UI actually uses `core` or `fl_media` localization.
- Leaving old locale artifacts (`intl_th.arb`, `*_th.dart`) after replacing a locale.
- Using `{name}` placeholders — use positional `{0}`.
- Leaving empty CSV cells and assuming generated localizations will fall back to English.
- Sneaking in raw `Text('Save')` for user-facing text.

## Related

- [`bloc-pattern`](../bloc-pattern/SKILL.md)
- [`module-scaffold`](../module-scaffold/SKILL.md)
- [`theme-usage`](../theme-usage/SKILL.md)
