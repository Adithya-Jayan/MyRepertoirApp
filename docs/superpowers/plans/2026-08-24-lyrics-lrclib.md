# Lyrics Attachment (lrclib.net) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a user attach a piece's lyrics as plain text, either typed/pasted manually or imported from a lrclib.net search, editable before saving.

**Architecture:** Add `MediaType.lyrics` as a new inline-text media type (same storage shape as the existing `MediaType.markdown`: the text lives directly in `MediaItem.pathOrUrl`, no file on disk). Add a small `LrcLibService` HTTP client for lrclib.net's public search endpoint, and a `LyricsSearchDialog` that lets the user search and pick a result, which fills the existing per-item text-edit field.

**Tech Stack:** Flutter/Dart, `http` package (already a dependency, including its bundled `package:http/testing.dart` for offline HTTP tests), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-08-24-lyrics-lrclib-design.md`

## Global Constraints

- No database schema change — media items are one JSON blob column; nothing here touches SQL.
- Reuse the existing "inline text, not a file path" exemption pattern already applied to `MediaType.markdown` — do not invent a second mechanism.
- lrclib.net is a public API with no API key. Requests get a descriptive `User-Agent` header (`Repertoire Music App (Flutter)`), a 10s timeout, and no retry/caching logic (YAGNI — this is a manual, user-initiated search).
- Only plain lyrics (`plainLyrics`) are imported — synced/timestamped lyrics are out of scope.
- This repo has no existing widget-test infrastructure (`test/` only covers database, locale, localization, and models). Tasks 3–5 follow that existing precedent: verified via `flutter analyze` + the full `flutter test` suite (regression) + manual `flutter run` verification, not new widget tests. Tasks 1–2 (model layer, HTTP service) get real automated tests — that logic is pure and testable without a widget harness.
- Run all Flutter commands with `export PATH="/home/ilbebo/tools/flutter/bin:$PATH"` first in this environment (the `flutter` binary is not on the default PATH).

---

### Task 1: `MediaType.lyrics` + `MediaItem` backup exemption

**Files:**
- Modify: `lib/models/media_type.dart`
- Modify: `lib/models/media_item.dart:65` and `lib/models/media_item.dart:83`
- Test: `test/model_tests.dart`

**Interfaces:**
- Produces: `MediaType.lyrics` (new enum value, last in `MediaType.values`, after `midi`). Every later task's UI code and the exhaustive-switch call sites in Task 3 reference this exact name.
- Produces: `MediaItem.toJsonForBackup`/`fromJsonForBackup` treat `MediaType.lyrics` as inline content (like `markdown`/`mediaLink`/`learningProgress`) — `pathOrUrl` is copied verbatim, never passed through `getRelativePath`/`getAbsolutePath`.

- [ ] **Step 1: Extend the `MediaType.values` test to expect `lyrics`**

In `test/model_tests.dart`, the first test in the file is:

```dart
  group('MediaType', () {
    test('should have correct values', () {
      expect(MediaType.values, [
        MediaType.markdown,
        MediaType.pdf,
        MediaType.image,
        MediaType.audio,
        MediaType.mediaLink,
        MediaType.thumbnails,
        MediaType.learningProgress,
        MediaType.localVideo,
        MediaType.midi,
      ]);
    });
  });
```

Change the list to end with `MediaType.midi, MediaType.lyrics,`.

Also add a new test in the `group('MusicPiece', ...)` block (after the two `transposeSemitones` tests you'll find already there), testing the backup exemption:

```dart
    test('MediaItem with type lyrics keeps pathOrUrl as inline text through backup round-trip', () {
      final item = MediaItem(
        id: 'lyr1',
        type: MediaType.lyrics,
        pathOrUrl: 'Line one\nLine two',
      );

      final json = item.toJsonForBackup('/some/storage/path');
      expect(json['pathOrUrl'], 'Line one\nLine two');

      final roundTripped = MediaItem.fromJsonForBackup(json, '/some/storage/path');
      expect(roundTripped.pathOrUrl, 'Line one\nLine two');
    });
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter test test/model_tests.dart
```

Expected: FAIL — `MediaType.lyrics` isn't defined yet, and the values-list length mismatches.

- [ ] **Step 3: Add the enum value**

In `lib/models/media_type.dart`, the enum currently ends:

```dart
  /// Represents a MIDI file.
  midi,
  // Add other types as needed, e.g., 'text' for plain text notes
}
```

Change to:

```dart
  /// Represents a MIDI file.
  midi,
  /// Represents song lyrics as plain text.
  lyrics,
  // Add other types as needed, e.g., 'text' for plain text notes
}
```

- [ ] **Step 4: Add `lyrics` to the two backup-exemption checks**

In `lib/models/media_item.dart`, `toJsonForBackup` currently has:

```dart
        'pathOrUrl': (type == MediaType.mediaLink || type == MediaType.markdown || type == MediaType.learningProgress)
            ? pathOrUrl
            : getRelativePath(pathOrUrl, storagePath),
```

Change to:

```dart
        'pathOrUrl': (type == MediaType.mediaLink || type == MediaType.markdown || type == MediaType.learningProgress || type == MediaType.lyrics)
            ? pathOrUrl
            : getRelativePath(pathOrUrl, storagePath),
```

`fromJsonForBackup` currently has:

```dart
          if (mediaType == MediaType.mediaLink || mediaType == MediaType.markdown || mediaType == MediaType.learningProgress) {
            return json['pathOrUrl'];
          }
```

Change to:

```dart
          if (mediaType == MediaType.mediaLink || mediaType == MediaType.markdown || mediaType == MediaType.learningProgress || mediaType == MediaType.lyrics) {
            return json['pathOrUrl'];
          }
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter test test/model_tests.dart
```

Expected: PASS, all tests including the two new ones.

Note: this alone will NOT make `flutter analyze` clean yet — several files have exhaustive `switch` statements over `MediaType` that now have a missing-case compile error. That's expected and fixed in Task 3. Do not run a full `flutter analyze` or `flutter test` (whole suite) until Task 3 is done; `flutter test test/model_tests.dart` in isolation still compiles fine because that file doesn't touch the broken switches.

- [ ] **Step 6: Commit**

```bash
git add lib/models/media_type.dart lib/models/media_item.dart test/model_tests.dart
git commit -m "feat: add MediaType.lyrics as an inline-text media type"
```

---

### Task 2: `LrcLibService`

**Files:**
- Create: `lib/services/lrclib_service.dart`
- Test: `test/lrclib_service_test.dart`

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces (used by Task 4):
  - `class LrcLibException implements Exception { final String message; LrcLibException(this.message); }`
  - `class LrcLibResult { final String trackName; final String artistName; final String? albumName; final int? durationSeconds; final String? plainLyrics; }`
  - `class LrcLibService { LrcLibService({http.Client? client}); Future<List<LrcLibResult>> search({required String trackName, required String artistName}); }`

- [ ] **Step 1: Write the failing tests**

Create `test/lrclib_service_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repertoire/services/lrclib_service.dart';

void main() {
  group('LrcLibService', () {
    test('parses a well-formed response into a list of results', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'trackName': 'Test Song',
              'artistName': 'Test Artist',
              'albumName': 'Test Album',
              'duration': 210.5,
              'plainLyrics': 'La la la',
            },
          ]),
          200,
        );
      });
      final service = LrcLibService(client: mockClient);

      final results = await service.search(
        trackName: 'Test Song',
        artistName: 'Test Artist',
      );

      expect(results, hasLength(1));
      expect(results[0].trackName, 'Test Song');
      expect(results[0].artistName, 'Test Artist');
      expect(results[0].albumName, 'Test Album');
      expect(results[0].durationSeconds, 211);
      expect(results[0].plainLyrics, 'La la la');
    });

    test('includes entries with null plainLyrics', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'trackName': 'Instrumental',
              'artistName': 'Someone',
              'plainLyrics': null,
            },
          ]),
          200,
        );
      });
      final service = LrcLibService(client: mockClient);

      final results = await service.search(
        trackName: 'Instrumental',
        artistName: 'Someone',
      );

      expect(results, hasLength(1));
      expect(results[0].plainLyrics, isNull);
    });

    test('skips entries missing trackName or artistName', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'artistName': 'No Track Name'},
            {'trackName': 'Valid', 'artistName': 'Valid Artist'},
          ]),
          200,
        );
      });
      final service = LrcLibService(client: mockClient);

      final results = await service.search(trackName: 'x', artistName: 'y');

      expect(results, hasLength(1));
      expect(results[0].trackName, 'Valid');
    });

    test('throws LrcLibException on non-200 status', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      final service = LrcLibService(client: mockClient);

      expect(
        () => service.search(trackName: 'x', artistName: 'y'),
        throwsA(isA<LrcLibException>()),
      );
    });

    test('throws LrcLibException when response is not a JSON array', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'not an array'}), 200);
      });
      final service = LrcLibService(client: mockClient);

      expect(
        () => service.search(trackName: 'x', artistName: 'y'),
        throwsA(isA<LrcLibException>()),
      );
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter test test/lrclib_service_test.dart
```

Expected: FAIL to compile — `package:repertoire/services/lrclib_service.dart` doesn't exist yet.

- [ ] **Step 3: Implement `LrcLibService`**

Create `lib/services/lrclib_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thrown when a lrclib.net search fails (network error, non-200 status,
/// or a response that isn't the JSON array the API is documented to return).
class LrcLibException implements Exception {
  final String message;
  LrcLibException(this.message);

  @override
  String toString() => message;
}

/// One search result from lrclib.net.
class LrcLibResult {
  final String trackName;
  final String artistName;
  final String? albumName;
  final int? durationSeconds;
  final String? plainLyrics;

  LrcLibResult({
    required this.trackName,
    required this.artistName,
    this.albumName,
    this.durationSeconds,
    this.plainLyrics,
  });

  /// Returns null if the entry is missing a track or artist name — such
  /// entries are skipped rather than shown as a broken result.
  static LrcLibResult? fromJson(Map<String, dynamic> json) {
    final trackName = json['trackName'];
    final artistName = json['artistName'];
    if (trackName is! String || artistName is! String) return null;

    final duration = json['duration'];
    final albumName = json['albumName'];
    final plainLyrics = json['plainLyrics'];

    return LrcLibResult(
      trackName: trackName,
      artistName: artistName,
      albumName: albumName is String ? albumName : null,
      durationSeconds: duration is num ? duration.round() : null,
      plainLyrics: plainLyrics is String ? plainLyrics : null,
    );
  }
}

/// Thin client for lrclib.net's public, key-less search API
/// (https://lrclib.net/api/search).
class LrcLibService {
  final http.Client _client;

  LrcLibService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'https://lrclib.net/api/search';

  Future<List<LrcLibResult>> search({
    required String trackName,
    required String artistName,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'track_name': trackName,
        if (artistName.isNotEmpty) 'artist_name': artistName,
      },
    );

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'User-Agent': 'Repertoire Music App (Flutter)'})
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw LrcLibException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw LrcLibException(
        'lrclib.net returned status ${response.statusCode}',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw LrcLibException('Invalid response from lrclib.net');
    }

    if (decoded is! List) {
      throw LrcLibException('Unexpected response format from lrclib.net');
    }

    final results = <LrcLibResult>[];
    for (final entry in decoded) {
      if (entry is Map<String, dynamic>) {
        final parsed = LrcLibResult.fromJson(entry);
        if (parsed != null) results.add(parsed);
      }
    }
    return results;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter test test/lrclib_service_test.dart
```

Expected: PASS, all 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/services/lrclib_service.dart test/lrclib_service_test.dart
git commit -m "feat: add LrcLibService for lrclib.net lyrics search"
```

---

### Task 3: Wire `MediaType.lyrics` through existing switches, labels, and display

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`
- Modify (generated, do not hand-edit beyond running the generator): `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_zh.dart`
- Modify: `lib/l10n/l10n.dart`
- Modify: `lib/screens/add_edit_piece/add_edit_piece_media_manager.dart`
- Modify: `lib/widgets/add_edit_piece/speed_dial_widget.dart`
- Modify: `lib/widgets/media_display_widget.dart`
- Modify: `lib/widgets/detail_widgets/media_display_list.dart`
- Modify: `lib/services/backup/restore_manager.dart`

**Interfaces:**
- Consumes: `MediaType.lyrics` from Task 1.
- Produces: `context.l10n.lyrics`, `context.l10n.lyricsContent`, `context.l10n.searchLyrics`, `context.l10n.searchLyricsDialogTitle`, `context.l10n.trackNameLabel`, `context.l10n.artistNameLabel`, `context.l10n.noLyricsAvailable`, `context.l10n.noLyricsFound`, `context.l10n.lyricsSearchError(String error)` — all consumed by Tasks 4 and 5. Reuses the existing `context.l10n.retry` key (already present in `app_en.arb`) rather than adding a duplicate.

This task has no new automated tests of its own — it is compiler-forced wiring (adding the missing `case` branches an exhaustive `switch` demands) plus label plumbing. Correctness is verified by `flutter analyze` reporting zero issues and the full existing test suite staying green, per the Global Constraints note on this repo's testing precedent.

- [ ] **Step 1: Add the new ARB keys (English)**

In `lib/l10n/app_en.arb`, find this line (search for `"loggingAndDeveloperOptions"`):

```
  "loggingAndDeveloperOptions": "Logging and developer options",
```

Insert immediately after it:

```
  "lyrics": "Lyrics",
  "lyricsContent": "Lyrics",
  "searchLyrics": "Search lyrics (lrclib.net)",
  "searchLyricsDialogTitle": "Search lyrics",
  "trackNameLabel": "Track name",
  "artistNameLabel": "Artist name",
  "noLyricsAvailable": "No plain lyrics",
  "noLyricsFound": "No results found",
  "lyricsSearchError": "Couldn't reach lrclib.net: {error}",
  "@lyricsSearchError": {
    "description": "Shown when a lrclib.net lyrics search fails.",
    "placeholders": {
      "error": {
        "type": "String"
      }
    }
  },
```

- [ ] **Step 2: Add the matching keys (Simplified Chinese)**

In `lib/l10n/app_zh.arb`, find the same anchor line (search for `"loggingAndDeveloperOptions"`) and insert immediately after it:

```
  "lyrics": "歌词",
  "lyricsContent": "歌词",
  "searchLyrics": "搜索歌词 (lrclib.net)",
  "searchLyricsDialogTitle": "搜索歌词",
  "trackNameLabel": "曲目名称",
  "artistNameLabel": "艺术家名称",
  "noLyricsAvailable": "无纯文本歌词",
  "noLyricsFound": "未找到结果",
  "lyricsSearchError": "无法连接到 lrclib.net：{error}",
  "@lyricsSearchError": {
    "description": "Shown when a lrclib.net lyrics search fails.",
    "placeholders": {
      "error": {
        "type": "String"
      }
    }
  },
```

- [ ] **Step 3: Regenerate localization sources**

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter gen-l10n
grep -n "String get lyrics " lib/l10n/app_localizations_en.dart
```

Expected: the grep prints a line — confirms the generator picked up the new key. (`flutter gen-l10n` prints nothing on success beyond the l10n.yaml notice you may already have seen in this environment.)

- [ ] **Step 4: Add the `MediaType.lyrics` branch to the label switch**

In `lib/l10n/l10n.dart`, the `LocalizedMediaTypeX` extension currently ends:

```dart
      MediaType.localVideo => l10n.localVideo,
      MediaType.midi => l10n.midi,
    };
```

Change to:

```dart
      MediaType.localVideo => l10n.localVideo,
      MediaType.midi => l10n.midi,
      MediaType.lyrics => l10n.lyrics,
    };
```

- [ ] **Step 5: Add the `MediaType.lyrics` branch to the media-picker switch**

In `lib/screens/add_edit_piece/add_edit_piece_media_manager.dart`, `pickFile`'s switch currently ends:

```dart
      case MediaType.mediaLink:
      case MediaType.learningProgress: // Handled separately
        return [];
    }
```

Change to:

```dart
      case MediaType.mediaLink:
      case MediaType.learningProgress: // Handled separately
      case MediaType.lyrics: // Handled separately (inline text, no file picker)
        return [];
    }
```

In the same file, `addMediaItem` currently starts:

```dart
    final newMediaItems = List<MediaItem>.from(currentMediaItems);
    if (type == MediaType.mediaLink || type == MediaType.markdown) {
```

Change the condition to:

```dart
    final newMediaItems = List<MediaItem>.from(currentMediaItems);
    if (type == MediaType.mediaLink ||
        type == MediaType.markdown ||
        type == MediaType.lyrics) {
```

- [ ] **Step 6: Add the speed-dial entry**

In `lib/widgets/add_edit_piece/speed_dial_widget.dart`, the children list currently ends:

```dart
      SpeedDialChild(
        child: const Icon(Icons.bar_chart),
        label: context.l10n.learningProgress,
        onTap: () => onAddMediaItem(MediaType.learningProgress),
      ),
    ];
```

Change to:

```dart
      SpeedDialChild(
        child: const Icon(Icons.bar_chart),
        label: context.l10n.learningProgress,
        onTap: () => onAddMediaItem(MediaType.learningProgress),
      ),
      SpeedDialChild(
        child: const Icon(Icons.lyrics),
        label: context.l10n.lyrics,
        onTap: () => onAddMediaItem(MediaType.lyrics),
      ),
    ];
```

(The existing `dialChildren.sort(...)` call right below already re-sorts alphabetically by label — no further change needed.)

- [ ] **Step 7: Render lyrics as plain selectable text**

In `lib/widgets/media_display_widget.dart`, the content switch currently starts:

```dart
    switch (currentMediaItem.type) {
      case MediaType.markdown:
        content = MarkdownBody(data: currentMediaItem.pathOrUrl);
        break;
```

Change to:

```dart
    switch (currentMediaItem.type) {
      case MediaType.markdown:
        content = MarkdownBody(data: currentMediaItem.pathOrUrl);
        break;
      case MediaType.lyrics:
        content = SelectableText(currentMediaItem.pathOrUrl);
        break;
```

- [ ] **Step 8: Make lyrics shareable as plain text**

In `lib/widgets/detail_widgets/media_display_list.dart`, `_shareMediaItem`'s switch currently starts:

```dart
      switch (item.type) {
        case MediaType.mediaLink:
        case MediaType.markdown:
          params = ShareParams(
            text: item.pathOrUrl,
            sharePositionOrigin: shareOrigin,
          );
          break;
```

Change to:

```dart
      switch (item.type) {
        case MediaType.mediaLink:
        case MediaType.markdown:
        case MediaType.lyrics:
          params = ShareParams(
            text: item.pathOrUrl,
            sharePositionOrigin: shareOrigin,
          );
          break;
```

- [ ] **Step 9: Exempt lyrics from the backup path-correction pass**

In `lib/services/backup/restore_manager.dart`, the condition currently reads:

```dart
        if (mediaItem.type != MediaType.mediaLink &&
            mediaItem.type != MediaType.markdown &&
            mediaItem.type != MediaType.learningProgress &&
            mediaItem.pathOrUrl.isNotEmpty) {
```

Change to:

```dart
        if (mediaItem.type != MediaType.mediaLink &&
            mediaItem.type != MediaType.markdown &&
            mediaItem.type != MediaType.learningProgress &&
            mediaItem.type != MediaType.lyrics &&
            mediaItem.pathOrUrl.isNotEmpty) {
```

- [ ] **Step 10: Verify the whole project compiles and existing tests still pass**

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter analyze
```

Expected: `No issues found!` (the same 8 pre-existing `deprecated_member_use` info notices from before this feature are fine; there must be zero new errors — specifically, zero "missing case" errors on `MediaType.lyrics`).

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter test test/model_tests.dart test/database_helper_test.dart test/locale_notifier_test.dart test/localization_test.dart test/lrclib_service_test.dart -r expanded
```

Expected: `All tests passed!`

- [ ] **Step 11: Manual verification**

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter run -d linux
```

In the running app: open any piece → edit → tap the speed-dial "+" → confirm a "Lyrics" option now appears (alphabetically sorted among the others) → tap it → confirm a new empty media item labeled "Lyrics" appears in the list → go to the piece's detail view → confirm the (empty) lyrics item renders without error. Stop the app (`Ctrl+C` in the terminal running it) when done.

- [ ] **Step 12: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_zh.dart lib/l10n/l10n.dart lib/screens/add_edit_piece/add_edit_piece_media_manager.dart lib/widgets/add_edit_piece/speed_dial_widget.dart lib/widgets/media_display_widget.dart lib/widgets/detail_widgets/media_display_list.dart lib/services/backup/restore_manager.dart
git commit -m "feat: wire MediaType.lyrics through media UI, sharing, and backup"
```

---

### Task 4: `LyricsSearchDialog`

**Files:**
- Create: `lib/widgets/detail_widgets/lyrics_search_dialog.dart`

**Interfaces:**
- Consumes: `LrcLibService`, `LrcLibResult`, `LrcLibException` from Task 2; `context.l10n.searchLyricsDialogTitle`, `.trackNameLabel`, `.artistNameLabel`, `.searchLyrics`, `.lyricsSearchError(String)`, `.retry`, `.noLyricsFound`, `.noLyricsAvailable` from Task 3.
- Produces (used by Task 5): `class LyricsSearchDialog extends StatefulWidget { const LyricsSearchDialog({required String initialTrackName, required String initialArtistName, LrcLibService? service}); }` — shown via `showDialog<String>(...)`; pops with the selected result's `plainLyrics` (a non-empty `String`) or `null` if cancelled/no selection made.

No automated test for this task (widget-test-free repo precedent, see Global Constraints) — verified by Step 2's manual check and, more thoroughly, as part of Task 5's end-to-end manual verification once it's wired into the real edit screen.

- [ ] **Step 1: Implement the dialog**

Create `lib/widgets/detail_widgets/lyrics_search_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:repertoire/l10n/l10n.dart';
import 'package:repertoire/services/lrclib_service.dart';

/// A dialog that searches lrclib.net for a track's lyrics.
///
/// Pops with the plain-text lyrics of the result the user picks, or `null`
/// if the dialog is dismissed without a selection.
class LyricsSearchDialog extends StatefulWidget {
  final String initialTrackName;
  final String initialArtistName;
  final LrcLibService? service;

  const LyricsSearchDialog({
    super.key,
    required this.initialTrackName,
    required this.initialArtistName,
    this.service,
  });

  @override
  State<LyricsSearchDialog> createState() => _LyricsSearchDialogState();
}

class _LyricsSearchDialogState extends State<LyricsSearchDialog> {
  late final LrcLibService _service;
  late final TextEditingController _trackController;
  late final TextEditingController _artistController;

  bool _isSearching = false;
  String? _errorMessage;
  List<LrcLibResult>? _results;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? LrcLibService();
    _trackController = TextEditingController(text: widget.initialTrackName);
    _artistController = TextEditingController(text: widget.initialArtistName);
  }

  @override
  void dispose() {
    _trackController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final trackName = _trackController.text.trim();
    if (trackName.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _results = null;
    });

    try {
      final results = await _service.search(
        trackName: trackName,
        artistName: _artistController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _results = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }

  @override
  Widget build(BuildContext context) {
    final trackName = _trackController.text.trim();
    return AlertDialog(
      title: Text(context.l10n.searchLyricsDialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _trackController,
              decoration: InputDecoration(
                labelText: context.l10n.trackNameLabel,
              ),
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _artistController,
              decoration: InputDecoration(
                labelText: context.l10n.artistNameLabel,
              ),
              onFieldSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.search),
              label: Text(context.l10n.searchLyrics),
              onPressed: (_isSearching || trackName.isEmpty) ? null : _search,
            ),
            const SizedBox(height: 12),
            if (_isSearching)
              const Center(child: CircularProgressIndicator()),
            if (_errorMessage != null) ...[
              Text(
                context.l10n.lyricsSearchError(_errorMessage!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _search,
                child: Text(context.l10n.retry),
              ),
            ],
            if (_results != null)
              Flexible(
                child: _results!.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(context.l10n.noLyricsFound),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _results!.length,
                        itemBuilder: (context, index) {
                          final result = _results![index];
                          final hasLyrics = result.plainLyrics != null;
                          final duration = result.durationSeconds;
                          final subtitleParts = <String>[
                            result.artistName,
                            if (result.albumName != null) result.albumName!,
                            if (duration != null) _formatDuration(duration),
                          ];
                          return ListTile(
                            enabled: hasLyrics,
                            title: Text(result.trackName),
                            subtitle: Text(subtitleParts.join(' • ')),
                            trailing: hasLyrics
                                ? null
                                : Text(
                                    context.l10n.noLyricsAvailable,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                            onTap: hasLyrics
                                ? () => Navigator.of(
                                    context,
                                  ).pop(result.plainLyrics)
                                : null,
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter analyze lib/widgets/detail_widgets/lyrics_search_dialog.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/detail_widgets/lyrics_search_dialog.dart
git commit -m "feat: add LyricsSearchDialog for lrclib.net lyrics search"
```

---

### Task 5: Wire the search dialog and text editor into the media edit screen

**Files:**
- Modify: `lib/widgets/detail_widgets/media_section.dart`

**Interfaces:**
- Consumes: `LyricsSearchDialog` from Task 4; `MediaType.lyrics` from Task 1; `context.l10n.searchLyrics`, `.lyricsContent` from Task 3.

No new automated test (same widget-test-free precedent) — verified by `flutter analyze` plus the full manual end-to-end check in Step 4, which is the first point in this plan where the complete feature (add → search → pick → edit → save → view) can be exercised together.

- [ ] **Step 1: Add a lyrics text controller to `_MediaSectionState`**

In `lib/widgets/detail_widgets/media_section.dart`, the state class currently starts:

```dart
class _MediaSectionState extends State<MediaSection> {
  bool _isLoadingThumbnail = false;
  String? _currentThumbnailPath;

  @override
  void initState() {
    super.initState();
    _currentThumbnailPath = widget.item.thumbnailPath;
  }

  @override
  void didUpdateWidget(MediaSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.thumbnailPath != widget.item.thumbnailPath) {
      setState(() {
        _currentThumbnailPath = widget.item.thumbnailPath;
      });
    }
  }
```

Change to:

```dart
class _MediaSectionState extends State<MediaSection> {
  bool _isLoadingThumbnail = false;
  String? _currentThumbnailPath;
  TextEditingController? _lyricsController;

  @override
  void initState() {
    super.initState();
    _currentThumbnailPath = widget.item.thumbnailPath;
    if (widget.item.type == MediaType.lyrics) {
      _lyricsController = TextEditingController(text: widget.item.pathOrUrl);
    }
  }

  @override
  void didUpdateWidget(MediaSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.thumbnailPath != widget.item.thumbnailPath) {
      setState(() {
        _currentThumbnailPath = widget.item.thumbnailPath;
      });
    }
  }

  @override
  void dispose() {
    _lyricsController?.dispose();
    super.dispose();
  }
```

A `TextEditingController` (rather than the `initialValue:` pattern the sibling markdown field uses) is required here because, unlike markdown, this field's text can change from *outside* itself — via the search dialog's result — and `TextFormField.initialValue` is only read once, on first build; it silently ignores later external changes to the same value. The controller is the one Flutter-idiomatic way to push a new value into an already-built field.

- [ ] **Step 2: Add the import**

At the top of `lib/widgets/detail_widgets/media_section.dart`, alongside the other same-directory widget imports (e.g. `import 'package:repertoire/widgets/add_edit_piece/pdf_config_dialog.dart';`), add:

```dart
import 'package:repertoire/widgets/detail_widgets/lyrics_search_dialog.dart';
```

- [ ] **Step 3: Add the lyrics branch to the edit-form if/else-if chain**

In the same file, the chain currently reads:

```dart
                else if (widget.item.type == MediaType.markdown)
                  TextFormField(
                    initialValue: widget.item.pathOrUrl,
                    decoration: InputDecoration(
                      labelText: context.l10n.markdownContent,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 5,
                    onChanged: (value) => widget.onUpdateMediaItem(
                      widget.item.copyWith(pathOrUrl: value),
                    ),
                  )
                else
                  TextFormField(
                    initialValue: widget.item.pathOrUrl,
                    decoration: InputDecoration(
                      labelText: context.l10n.pathOrUrl,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => widget.onUpdateMediaItem(
                      widget.item.copyWith(pathOrUrl: value),
                    ),
                  ),
```

Change to (inserting a new `else if` branch before the final `else`):

```dart
                else if (widget.item.type == MediaType.markdown)
                  TextFormField(
                    initialValue: widget.item.pathOrUrl,
                    decoration: InputDecoration(
                      labelText: context.l10n.markdownContent,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 5,
                    onChanged: (value) => widget.onUpdateMediaItem(
                      widget.item.copyWith(pathOrUrl: value),
                    ),
                  )
                else if (widget.item.type == MediaType.lyrics)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.search),
                        label: Text(context.l10n.searchLyrics),
                        onPressed: () async {
                          final picked = await showDialog<String>(
                            context: context,
                            builder: (context) => LyricsSearchDialog(
                              initialTrackName: widget.musicPiece.title,
                              initialArtistName:
                                  widget.musicPiece.artistComposer,
                            ),
                          );
                          if (picked != null) {
                            _lyricsController?.text = picked;
                            widget.onUpdateMediaItem(
                              widget.item.copyWith(pathOrUrl: picked),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _lyricsController,
                        decoration: InputDecoration(
                          labelText: context.l10n.lyricsContent,
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 8,
                        onChanged: (value) => widget.onUpdateMediaItem(
                          widget.item.copyWith(pathOrUrl: value),
                        ),
                      ),
                    ],
                  )
                else
                  TextFormField(
                    initialValue: widget.item.pathOrUrl,
                    decoration: InputDecoration(
                      labelText: context.l10n.pathOrUrl,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => widget.onUpdateMediaItem(
                      widget.item.copyWith(pathOrUrl: value),
                    ),
                  ),
```

- [ ] **Step 4: Verify the project compiles and the full test suite passes**

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter analyze
flutter test test/model_tests.dart test/database_helper_test.dart test/locale_notifier_test.dart test/localization_test.dart test/lrclib_service_test.dart -r expanded
```

Expected: `No issues found!` and `All tests passed!` (same baseline as Task 3 Step 10).

- [ ] **Step 5: Manual end-to-end verification**

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter run -d linux
```

1. Open an existing piece (or create one, e.g. title "Bohemian Rhapsody", artist "Queen") → edit.
2. Tap the speed-dial "+" → "Lyrics". Confirm a new lyrics item appears with a "Search lyrics (lrclib.net)" button and an empty multi-line text field.
3. Tap "Search lyrics (lrclib.net)". Confirm the dialog opens with the track/artist fields prefilled from the piece's title/artist.
4. Tap "Search". Confirm a result list appears (requires network access) with track/artist/album/duration per row, and that rows without plain lyrics are visibly disabled.
5. Tap a result with lyrics. Confirm the dialog closes and the multi-line text field is now populated with that result's lyrics text.
6. Edit the text by hand (e.g. delete a line). Confirm the edit sticks (not reverted).
7. Save the piece. Reopen it (navigate away and back, or restart the app). Confirm the lyrics text persisted exactly as edited.
8. Open the piece's detail view (not edit mode). Confirm the lyrics render as plain selectable text (try selecting a word) and are labeled "Lyrics" in the media list.
9. Test the manual-entry path too: add a second lyrics item, type text directly without using search, save, and confirm it persists the same way.
10. Stop the app (`Ctrl+C`).

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/detail_widgets/media_section.dart
git commit -m "feat: wire lyrics search dialog and text editor into media edit screen"
```
