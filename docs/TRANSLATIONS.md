# Translating Repertoire

Repertoire uses Flutter's ARB-based localization system. Localization is
configured by the root-level `l10n.yaml` because the shared UI is used by both
the F-Droid and Play Store flavors.

English is the source locale:

```text
lib/l10n/app_en.arb
```

Generated Dart localization files are stored in `lib/l10n/` and are committed
to the repository.

## Add a Language

1. Copy the English template using the locale identifier in the filename. For
   example, use `app_es.arb` for Spanish or `app_pt_BR.arb` for Brazilian
   Portuguese.
2. Change `@@locale` in the new file to the same locale identifier.
3. Translate `languageName` into the language itself. This value is displayed
   in the in-app language selector, such as `Español` or `Português (Brasil)`.
4. Translate every user-facing message value.
5. Keep message keys, `@` metadata entries, ICU syntax, and placeholders such
   as `{count}` unchanged.
6. Generate the localization classes:

   ```sh
   flutter gen-l10n
   ```

7. Verify that the language appears automatically under **Settings →
   Personalization → App Language**. No Dart registration change should be
   necessary.
8. Run the project checks:

   ```sh
   flutter analyze
   flutter test
   ```

9. Commit the new ARB file and the regenerated files in `lib/l10n/`.

## Placeholders and Plurals

Do not rename or remove placeholders. For example:

```json
"durationMinutes": "{count, plural, =1{1 minute} other{{count} minutes}}"
```

The translated message must retain the `count` placeholder and valid ICU plural
syntax. Running `flutter gen-l10n` will catch many placeholder or syntax errors.

## Add or Change a User-Facing Message

- Add the source message to `lib/l10n/app_en.arb` first.
- Add the same key to every other ARB file.
- Use `context.l10n.<messageName>` in widgets and other code instead of a
  hard-coded string.
- Do not translate persisted identifiers, enum values, database values, file
  format fields, or other internal strings. Only localize text presented to the
  user.
- Regenerate the Dart localization files and run the checks above.

## Translation Pull Request Checklist

- The ARB filename and `@@locale` match.
- `languageName` uses the language's native name.
- All message keys and placeholders match the English template.
- Generated localization files are included.
- The language appears in the in-app selector and survives an app restart.
- `flutter analyze` and `flutter test` pass.
