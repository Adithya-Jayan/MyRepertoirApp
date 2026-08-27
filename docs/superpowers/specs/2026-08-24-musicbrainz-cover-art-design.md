# MusicBrainz Cover Art & Details — Design Spec

**Status:** Approved for planning

## Goal

Let a user, while editing a piece's title/artist, search MusicBrainz and pick
a matching release; picking one overwrites the piece's title and artist with
MusicBrainz's values and replaces the piece's cover art (thumbnail) with
that release's cover art from the Cover Art Archive.

## Why this shape

MusicBrainz stores songs as abstract "recordings," but cover art in the
Cover Art Archive is indexed by **release** (a specific album/single/EP
pressing), not by recording. Searching MusicBrainz's `release` endpoint
directly — rather than `recording` and then resolving to a release — gives
one MBID per result that is immediately usable against the Cover Art
Archive, with no extra disambiguation step. This is the only material
technical choice in this feature; everything else follows the pattern
already established by the lyrics/lrclib.net integration:

- A thin HTTP service (`MusicBrainzService`), same shape as `LrcLibService`:
  one search method, defensive per-entry parsing, a typed exception, no
  retry/caching (manual, user-initiated search only).
- A search dialog (`MusicBrainzSearchDialog`), same shape as
  `LyricsSearchDialog`: prefilled from the piece's current title/artist,
  editable, a result list, tap-to-pick.
- Applying a pick is the one new piece of plumbing: unlike lyrics (which
  only ever touches one `MediaItem`'s `pathOrUrl`), a MusicBrainz pick
  touches three things on the `MusicPiece` at once — `title`,
  `artistComposer`, and the cover art (`thumbnailPath` plus the
  `MediaType.thumbnails` `MediaItem` that mirrors it, per the existing
  manual-thumbnail-picker convention in
  `add_edit_piece_screen.dart:_onMediaItemsChanged`). That three-way update
  has to happen in the screen that already owns all three, not in
  `BasicDetailsSection` itself.

## Components

### 1. `MusicBrainzService` (new file: `lib/services/musicbrainz_service.dart`)

Two responsibilities, two methods, no shared state between them beyond the
injected `http.Client`:

```dart
class MusicBrainzException implements Exception {
  final String message;
  MusicBrainzException(this.message);
}

class MusicBrainzResult {
  final String mbid;
  final String title;
  final String artist;
  final String? date; // MusicBrainz release date, e.g. "1975-10-31" or "1975" — nullable, format varies
}

class MusicBrainzService {
  MusicBrainzService({http.Client? client});

  Future<List<MusicBrainzResult>> search({
    required String title,
    required String artist,
  });

  Future<Uint8List?> fetchCoverArtBytes(String mbid);
}
```

**`search`:**

```
GET https://musicbrainz.org/ws/2/release/?query=release:"{title}" AND artist:"{artist}"&fmt=json&limit=10
```

- `title`/`artist` are inserted into the Lucene-style query string quoted,
  with internal `"` characters stripped first (MusicBrainz's query parser
  treats unescaped quotes as syntax; stripping is simpler and sufficient
  here than escaping, since song/artist names essentially never need a
  literal quote to be found).
- Response is a JSON object with a top-level `"releases"` array. Each entry
  parsed defensively — same policy as `LrcLibResult.fromJson`: an entry
  missing `id` or `title` is skipped, not fatal. `artist` comes from
  `artist-credit[0].name` (first credited artist name); an entry with an
  empty/missing `artist-credit` array is skipped, since a cover-art search
  result with no artist to display is not useful here. `date` is copied
  through as-is if present as a string, else `null`.
- A required `User-Agent` header is sent — MusicBrainz's usage policy
  requires one identifying the application (unauthenticated requests
  without one are throttled harder). Value: `Repertoire Music App
  (Flutter)`, matching the existing convention from `LrcLibService`.
- 10s timeout, no retry, no caching — same as `LrcLibService`.
- Non-200 status, non-JSON-object body, or a body without a `"releases"`
  array all throw `MusicBrainzException` with a short generic message
  (`'Server error (…)'`, `'Invalid response'`, `'Unexpected response
  format'`) — mirroring `LrcLibService`'s post-fix error-message shape
  (short causes, no redundant service-name repetition, no raw
  exception/URI text — see `lrclib_service.dart` as the reference for
  exactly what "short cause" means here).

**`fetchCoverArtBytes`:**

```
GET https://coverartarchive.org/release/{mbid}/front-250
```

- Returns the 250px-wide front-cover thumbnail directly (the Cover Art
  Archive redirects this URL to the actual image; the `http` package
  follows redirects by default, so no special handling is needed —
  identical in shape to the existing image-download step in
  `thumbnail_service.dart`'s `fetchAndSaveThumbnail`).
- `200` → return the body bytes.
- `404` → return `null` (this release genuinely has no cover art in the
  archive — an expected, non-error outcome, not an exception).
- Any other status, or a network/timeout error → throw
  `MusicBrainzException`.
- Same `User-Agent` header, same 10s timeout.

### 2. `MusicBrainzSearchDialog` (new file: `lib/widgets/detail_widgets/musicbrainz_search_dialog.dart`)

Structural twin of `LyricsSearchDialog`, with one behavioral difference:
picking a result in this dialog does more work before it can pop, because
the cover art has to be fetched (and possibly be absent) before the caller
has something complete to apply.

- Constructor: `MusicBrainzSearchDialog({required String initialTitle,
  required String initialArtist, MusicBrainzService? service})`.
- Two prefilled, editable fields (title, artist) + a Search button,
  identical shape to `LyricsSearchDialog`'s track/artist fields.
- Results list: each row shows title — artist — date (when present). Every
  row is tappable (unlike the lyrics dialog, there is no per-row
  "unavailable" state at search time — cover-art availability is only
  knowable per-release, and checking it for every row up front would mean
  N Cover Art Archive requests per search; instead, availability is
  resolved lazily, only for the one release the user actually picks).
- On tap: the row shows a small inline loading indicator (replacing its
  trailing area) while `fetchCoverArtBytes(result.mbid)` runs. On success
  (bytes or `null`), the dialog pops with a
  `MusicBrainzPickResult(title, artist, coverArtBytes)` — `coverArtBytes`
  is nullable, signaling "apply title/artist, no cover art available for
  this release" rather than treating a missing cover as a failure. On a
  thrown `MusicBrainzException` from the cover-art fetch, the row's loading
  state clears and an inline error appears in the dialog (same
  error-plus-retry shape as `LyricsSearchDialog`), and the user can tap the
  same row again or a different one — the search results themselves are
  not discarded.
- A separate `MusicBrainzPickResult` class (not exported beyond this
  dialog + its caller) — a small value holder:
  ```dart
  class MusicBrainzPickResult {
    final String title;
    final String artist;
    final Uint8List? coverArtBytes;
  }
  ```
- Cancel pops with `null`, same as the lyrics dialog.

### 3. Applying a pick: `BasicDetailsSection` → `AddEditPieceScreen`

**Trigger:** a new `OutlinedButton.icon` in `BasicDetailsSection`, placed
directly below the artist field (above the transpose picker), labeled via a
new l10n key `searchMusicBrainz` ("Search on MusicBrainz" /
"Cerca su MusicBrainz" / "在 MusicBrainz 上搜索"). Opens
`MusicBrainzSearchDialog` with `initialTitle`/`initialArtist` from the
section's own now-controller-backed title/artist text (see below).

**Why title/artist become `TextEditingController`-backed:** today
`BasicDetailsSection`'s title and artist fields use `initialValue`, which —
same issue already solved once for the lyrics text field in
`media_section.dart` — is read only on first build and silently ignores
later external changes to the same value. A MusicBrainz pick changes
`musicPiece.title`/`.artistComposer` from *outside* the field (the dialog
result, not a keystroke), so both fields need controllers, exactly the
pattern already used for `_lyricsController`. `BasicDetailsSection` is
already a `StatefulWidget` (converted for the NumberPicker's local display
state), so this is an incremental addition to existing state, not a new
conversion.

**New callback on `BasicDetailsSection`:**

```dart
final void Function(String title, String artist, Uint8List? coverArtBytes)
    onMusicBrainzResultApplied;
```

`BasicDetailsSection`'s own responsibility on a non-null dialog result is
narrow: update its two controllers' `.text` (so the visible fields refresh
immediately, same mechanism as the lyrics controller) and forward the full
result upward via this callback — it does **not** touch `mediaItems` or
`thumbnailPath` itself, since it has no access to either.

**In `AddEditPieceScreen`**, a new handler wired to that callback:

```dart
Future<void> _onMusicBrainzResultApplied(
  String title,
  String artist,
  Uint8List? coverArtBytes,
) async {
  String? newThumbnailPath = _musicPiece.thumbnailPath;
  var mediaItems = _musicPiece.mediaItems;

  if (coverArtBytes != null) {
    final dir = await MediaStorageManager.getPieceMediaDirectory(
      _musicPiece.id,
      MediaType.thumbnails,
    );
    if (dir != null) {
      if (!await dir.exists()) await dir.create(recursive: true);
      final file = File(p.join(dir.path, '${const Uuid().v4()}.jpg'));
      await file.writeAsBytes(coverArtBytes);
      newThumbnailPath = file.path;

      mediaItems = [
        ...mediaItems.where((m) => m.type != MediaType.thumbnails),
        MediaItem(
          id: const Uuid().v4(),
          type: MediaType.thumbnails,
          pathOrUrl: file.path,
        ),
      ];
    }
  }

  setState(() {
    _musicPiece = _musicPiece.copyWith(
      title: title,
      artistComposer: artist,
      mediaItems: mediaItems,
      thumbnailPath: newThumbnailPath,
    );
  });
}
```

- `coverArtBytes == null` (no result had cover art, or the user picked a
  release specifically without one) leaves the existing thumbnail and
  `mediaItems` list untouched — title/artist are still applied. This is
  the one case where "always overwrite" (the approved behavior for
  title/artist) does *not* extend to the thumbnail, because there is
  nothing to overwrite it *with* — the alternative (clearing an existing
  good thumbnail because a search happened not to find art) would be
  actively worse for the user than leaving it alone.
- When `coverArtBytes != null`, any existing `MediaType.thumbnails` item is
  replaced outright (filtered out, new one appended) — this is the "always
  replace" behavior approved for the cover art case, implemented at the
  `mediaItems` level rather than by mutating an existing item in place,
  consistent with how every other media-item list update in this codebase
  works (`_onMediaItemsChanged`, `AddEditPieceMediaManager.deleteMediaItem`,
  etc. — always produce a new filtered/appended list, never mutate an
  entry).
- The old thumbnail file on disk is intentionally not deleted here — it
  becomes an orphaned file, cleaned up the same way any other orphaned
  media file in this app already is: `media_cleanup_service.dart`'s
  existing sweep (which compares files on disk against files referenced by
  any piece) picks it up. No new cleanup code is needed.
- This handler is `async` (unlike the piece's other field-change handlers)
  because writing the downloaded bytes to disk is asynchronous; the
  dialog's own `showDialog<MusicBrainzPickResult>` await already happens
  in `BasicDetailsSection`, so `AddEditPieceScreen`'s handler is invoked
  only after a result exists — no loading state is needed at this call
  site itself.

### 4. Localization

New keys, `app_en.arb` / `app_zh.arb` / `app_it.arb` (all three locales now
exist in this repo):

- `searchMusicBrainz` — "Search on MusicBrainz"
- `searchMusicBrainzDialogTitle` — "Search MusicBrainz"
- `noCoverArtAvailable` — "No cover art found for this release" (shown as
  a transient message, e.g. a SnackBar, in `AddEditPieceScreen` after
  applying a pick with `coverArtBytes == null`, so the user isn't left
  wondering why the thumbnail didn't change)
- `musicBrainzSearchError` — "Couldn't reach MusicBrainz: {error}"
  (placeholder parameter, same shape as `lyricsSearchError`)

Reused, not duplicated: the dialog's two text fields use the existing
`context.l10n.title` and `context.l10n.artistComposer` labels (both already
mean exactly "the field for a piece's title" / "the field for a piece's
artist") and `context.l10n.retry` — no new keys needed for any of the
three. `context.l10n.trackNameLabel`/`artistNameLabel` (added for the
lyrics dialog) are intentionally *not* reused here: those read naturally
for a song-lookup field ("Track name") but not for this dialog, which is
functionally the same title/artist pair already shown in
`BasicDetailsSection` — reusing `title`/`artistComposer` keeps the two UI
surfaces terminologically consistent instead of introducing a second
near-duplicate label for the same concept.

### 5. Data flow

1. User types/edits title and artist in `BasicDetailsSection`, then taps
   "Search on MusicBrainz."
2. `MusicBrainzSearchDialog` opens prefilled from the current controller
   text, user may adjust, taps Search →
   `MusicBrainzService.search(title:, artist:)` → result list rendered.
3. User taps a result → dialog fetches that release's cover art
   (`fetchCoverArtBytes`) → pops with a `MusicBrainzPickResult`.
4. `BasicDetailsSection` updates its title/artist controllers' visible text
   and calls `onMusicBrainzResultApplied`.
5. `AddEditPieceScreen` writes the cover art bytes to a local file (if
   present), replaces the `MediaType.thumbnails` `MediaItem`, updates
   `thumbnailPath`, and applies the new title/artist — all via one
   `setState`/`copyWith`, matching the existing pattern for every other
   piece-level field mutation in this screen.
6. Saving the piece persists everything through the existing
   `AddEditPieceFormHandler`/repository flow — no new persistence code.

### 6. Error handling

- Empty title in the dialog: Search button disabled, same as the lyrics
  dialog's empty-track-name guard.
- Network/timeout/non-200/malformed-JSON during `search`: inline error in
  the dialog with retry, same shape as `LyricsSearchDialog`.
- `fetchCoverArtBytes` returning `404` (no art) is not an error: the pick
  still completes, `AddEditPieceScreen` shows a one-line snackbar
  (`noCoverArtAvailable`) after applying title/artist so the user knows why
  no thumbnail appeared.
- `fetchCoverArtBytes` throwing (genuine network/server error, not a plain
  404): the tapped row's loading state clears, an inline dialog error with
  retry appears (retrying re-fetches cover art for the *same* release, not
  a new search) — the user is never silently left in a stuck-loading row.

### 7. Testing

- `MusicBrainzService`: unit tests via injected `http.Client`
  (`package:http/testing.dart`'s `MockClient`, same technique as
  `lrclib_service_test.dart`). Cases: well-formed `search` response → parsed
  list; entry missing `id`/`title` → skipped; entry with empty
  `artist-credit` → skipped; non-200 on `search` → throws; non-object body
  on `search` → throws; `fetchCoverArtBytes` 200 → returns bytes;
  `fetchCoverArtBytes` 404 → returns `null`; `fetchCoverArtBytes` 500 →
  throws.
- No widget tests for the dialog or the screen wiring — same established
  precedent as the lyrics feature (this repo has no widget-test
  infrastructure; `flutter analyze` plus the full existing suite is the
  verification gate for UI-wiring tasks).

## Out of scope (explicitly)

- Album/year/genre as new persistent `MusicPiece` fields — this iteration
  only writes to the three things already decided (title, artist, cover
  art); a future iteration could add a details panel, but nothing here
  should make that harder later (the `MusicBrainzResult`/`PickResult` types
  already carry `date`, unused today beyond display in the results list —
  a natural extension point, not a design commitment).
- Any caching of search results or cover art across sessions.
- Recording-level search or disambiguation UI (track duration, release
  format, etc.) — release title/artist/date is enough signal for a user to
  pick the right entry, per the approved MVP scope.
- Automatic search-on-piece-creation — always a manual, user-initiated
  action from the edit screen, same as lyrics search.
