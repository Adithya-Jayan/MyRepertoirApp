# Lyrics Attachment (via lrclib.net) — Design Spec

**Status:** Approved for planning

## Goal

Let a user attach the plain-text lyrics of a piece to that piece, either by
pasting/typing them manually or by searching lrclib.net and importing a
result, then editing before saving.

## Why this shape

The app already models free-text notes as `MediaType.markdown`: a
`MediaItem` whose `pathOrUrl` field holds the text itself (not a file path).
Lyrics are the same shape of data — inline text attached to a piece — so
they reuse that pattern as a new `MediaType.lyrics` value instead of adding
a parallel storage mechanism. This means:

- No database schema change (media items are serialized as a JSON blob in
  the existing `music_pieces.mediaItems` column).
- No new file-storage code path (`MediaStorageManager` untouched).
- Lyrics get reordering, sharing, and backup/restore for free by following
  the same exemptions already carved out for markdown/mediaLink/
  learningProgress.

The only genuinely new piece is the lrclib.net search integration.

## Components

### 1. `MediaType.lyrics` (enum addition)

`lib/models/media_type.dart` gains one value: `lyrics`.

Because Dart enum switches are exhaustive, adding this value forces a
compile error at every `switch` over `MediaType` until each is updated.
That is the mechanism that guarantees no call site is missed. The affected
switches (found by compiling, not just by grep) are enumerated in the
per-file list below.

### 2. `MediaItem` inline-content exemption

`lib/models/media_item.dart` has two places that special-case types whose
`pathOrUrl` is inline content rather than a file path:

- `toJsonForBackup`: skips path relativization for
  `mediaLink | markdown | learningProgress`.
- `fromJsonForBackup`: skips path absolutization for the same set.

Add `MediaType.lyrics` to both sets.

### 3. `LrcLibService` (new file: `lib/services/lrclib_service.dart`)

Thin wrapper around the lrclib.net public search API. No API key.

```
GET https://lrclib.net/api/search?track_name={trackName}&artist_name={artistName}
```

Response: JSON array of objects. Relevant fields (all defensively parsed —
an entry missing `trackName` or with a non-string field is skipped, not
fatal):

- `trackName` (String)
- `artistName` (String)
- `albumName` (String?)
- `duration` (num?, seconds)
- `plainLyrics` (String?) — what we import; entries with `plainLyrics ==
  null` are still shown (instrumental or synced-only tracks) but disabled
  for selection.

Public interface:

```dart
class LrcLibResult {
  final String trackName;
  final String artistName;
  final String? albumName;
  final int? durationSeconds;
  final String? plainLyrics;
}

class LrcLibService {
  Future<List<LrcLibResult>> search({
    required String trackName,
    required String artistName,
  });
}
```

- HTTP GET via the existing `http` package (already a dependency), 10s
  timeout.
- Sets a descriptive `User-Agent` header (matches the pattern already used
  in `thumbnail_service.dart` for outbound requests).
- On non-200 status or network/timeout error, throws a plain
  `LrcLibException(String message)` that the UI catches to show a
  SnackBar — no retry logic, no caching (YAGNI: this is a manual,
  user-initiated search, not a background sync).
- Empty `trackName` is not sent to the API; the UI prevents the search
  button from firing with an empty title.

### 4. Add-media entry point

`lib/widgets/add_edit_piece/speed_dial_widget.dart`: one new
`SpeedDialChild` — icon `Icons.lyrics`, label `context.l10n.lyrics`,
`onTap: () => onAddMediaItem(MediaType.lyrics)`. Sorted alphabetically with
the rest (existing behavior, no special-casing needed).

`lib/screens/add_edit_piece/add_edit_piece_media_manager.dart`:
- `pickFile`'s switch: `MediaType.lyrics` returns `[]` immediately, same
  branch as `MediaType.mediaLink` (no file picker involved).
- `addMediaItem`'s inline-content check
  (`type == MediaType.mediaLink || type == MediaType.markdown`) grows to
  include `MediaType.lyrics`, so a new empty lyrics `MediaItem` is
  appended the same way a new empty markdown note is.

### 5. Edit UI (`lib/widgets/detail_widgets/media_section.dart`)

This widget already receives `widget.musicPiece` (used elsewhere in the
file), so title/artist are available without new plumbing.

For `widget.item.type == MediaType.lyrics`:

- A multi-line `TextFormField` (same shape as the existing markdown one:
  `maxLines: 5`, `onChanged` writes back via
  `widget.onUpdateMediaItem(widget.item.copyWith(pathOrUrl: value))`),
  labeled `context.l10n.lyricsContent`.
- Above it, an `OutlinedButton.icon` "Search lyrics (lrclib.net)" —
  `context.l10n.searchLyrics` — that opens a new dialog widget:
  `LyricsSearchDialog` (new file:
  `lib/widgets/detail_widgets/lyrics_search_dialog.dart`).

**`LyricsSearchDialog`** (`StatefulWidget`, returns `String?` via
`Navigator.pop`):

- Constructor takes `initialTrackName` and `initialArtistName` (from
  `widget.musicPiece.title` / `.artistComposer`).
- Two prefilled, editable `TextFormField`s (track, artist) + a "Search"
  button.
- On search: calls `LrcLibService.search(...)`, shows a loading spinner,
  then a scrollable list of results (`trackName — artistName — albumName
  (mm:ss)`); rows with `plainLyrics == null` are shown greyed-out and
  non-tappable with a trailing `context.l10n.noLyricsAvailable` label.
- Tapping a selectable row pops the dialog with that result's
  `plainLyrics`.
- Network/parsing errors surface as an inline error message in the dialog
  (not a SnackBar — the dialog owns its own error state), with a "Try
  again" retry of the same query.
- No results: inline empty-state message, no error.

Back in `media_section.dart`, a non-null dialog result replaces the
`TextFormField`'s text and calls `widget.onUpdateMediaItem` with the new
`pathOrUrl`, exactly like a manual edit would. The user can still edit the
text afterward before the piece is saved — nothing here is
auto-committing beyond the normal media-item edit flow that already
exists for every other media type.

### 6. Display UI (`lib/widgets/media_display_widget.dart`)

New `case MediaType.lyrics:` renders `SelectableText(currentMediaItem.pathOrUrl)`
— plain text, not `MarkdownBody` (lyrics are not markdown-formatted and
markdown rendering could mangle lines that happen to start with `#` or
`*`). Selectable so the user can copy a line while practicing.

### 7. Remaining exhaustive-switch call sites

Each of these currently switches on `MediaType` and must add a `lyrics`
branch (verified by `flutter analyze` after the enum change, not just
grep):

- `lib/widgets/detail_widgets/media_display_list.dart` (`_shareMediaItem`):
  treat like `markdown` — share as plain text (`ShareParams(text:
  item.pathOrUrl, ...)`).
- `lib/l10n/l10n.dart` (media-type-to-label switch): `MediaType.lyrics =>
  l10n.lyrics`.
- `lib/services/backup/restore_manager.dart`: add `lyrics` to the "don't
  rewrite this path, it's not a file" exclusion alongside
  `mediaLink`/`markdown`/`learningProgress`.

`lib/utils/dummy_data.dart` and
`lib/services/share_handler_service.dart` are **not** touched — dummy data
doesn't need a lyrics example, and share-handler's file-extension-to-type
mapping has no lyrics-specific extension to map (`.txt` already maps to
`markdown`, which is an acceptable default for shared text files; a user
importing lyrics from another app via share is out of scope for this
feature).

### 8. Localization

New keys in `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`:

- `lyrics` — "Lyrics" — the media-type label (speed dial, list icon
  labels).
- `lyricsContent` — "Lyrics" — the text-field label in the edit view
  (parallel to `markdownContent`).
- `searchLyrics` — "Search lyrics (lrclib.net)"
- `searchLyricsDialogTitle` — "Search lyrics"
- `trackNameLabel` — "Track name"
- `artistNameLabel` — "Artist name"
- `noLyricsAvailable` — "No plain lyrics"
- `noLyricsFound` — "No results found"
- `lyricsSearchError` — "Couldn't reach lrclib.net. {error}" (placeholder
  parameter for the caught exception message)
- `tryAgain` — "Try again"

After editing both `.arb` files, regenerate with `flutter gen-l10n`
(already configured via `l10n.yaml`; committed generated files under
`lib/l10n/app_localizations*.dart` must be regenerated and committed, same
as the semitone-field change did).

## Data flow

1. User taps the speed-dial "Lyrics" entry → empty `MediaItem(type:
   lyrics, pathOrUrl: '')` appended to the piece's `mediaItems` (in-memory,
   `add_edit_piece_screen`'s `_musicPiece`, not yet persisted).
2. `media_section.dart` renders the edit form for that item. User either
   types directly, or taps "Search lyrics" → `LyricsSearchDialog` → picks a
   result → text field is populated with `plainLyrics`.
3. User may hand-edit the populated (or manually typed) text.
4. Saving the piece (existing `add_edit_piece_form_handler.dart` flow,
   unchanged) persists the whole `mediaItems` list, lyrics text included,
   through the existing `toJson`/JSON-blob path — no new persistence code.
5. Viewing the piece: `media_display_widget.dart` renders the stored text
   read-only via `SelectableText`.

## Error handling

- Empty track name: search button disabled client-side; no request sent.
- Network failure / timeout / non-200: `LrcLibService` throws
  `LrcLibException`; the dialog catches it, shows the error inline with a
  retry button. Nothing is written to the piece.
- Malformed JSON entries in the response: skipped individually (defensive
  parsing per-entry, wrapped in try/catch inside the list-mapping code),
  not fatal to the whole search.
- Selecting a result with `plainLyrics == null`: prevented at the UI level
  (row is non-tappable), not a runtime error path.

## Testing

- `LrcLibService`: unit tests against a fake/injected `http.Client`
  (constructor takes an optional `http.Client` for injection, defaulting to
  `http.Client()` — same DI seam pattern to add here since none of the
  existing services in this repo inject one, but it is the only way to
  unit-test HTTP parsing without a real network call). Cases: well-formed
  response → parsed list; entry missing `plainLyrics` → included with
  `plainLyrics: null`; entry missing `trackName` → skipped; non-200 status
  → throws `LrcLibException`; malformed top-level JSON (not an array) →
  throws `LrcLibException`.
- `MediaItem` / `MusicPiece` model tests
  (`test/model_tests.dart`): a `MediaItem` with `type: MediaType.lyrics`
  round-trips through `toJson`/`fromJson` and through
  `toJsonForBackup`/`fromJsonForBackup` with `pathOrUrl` left untouched
  (not relativized as a path).
- No widget tests exist for `media_section.dart` or the speed dial in this
  repo today (checked: `test/` only covers database, locale, localization,
  and models); this feature follows that existing precedent and does not
  introduce a new widget-testing pattern. Manual verification of the
  dialog and edit flow is done via `flutter run` before marking the
  feature complete, matching how the rest of `add_edit_piece` UI in this
  codebase is verified.

## Out of scope (explicitly)

- Synced/timestamped lyrics (`syncedLyrics`) — plain text only, per the
  user's request ("cercare in formato testuale").
- Auto-searching on piece creation — search is always a manual,
  user-initiated action from the edit screen.
- Caching search results across sessions.
- Editing lrclib.net search params beyond track/artist (no album/duration
  disambiguation UI) — YAGNI until proven necessary.
