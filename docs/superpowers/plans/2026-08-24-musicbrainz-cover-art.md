# MusicBrainz Cover Art Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a user search MusicBrainz from the piece edit screen and, picking a release, overwrite the piece's title/artist and replace its cover art with that release's artwork from the Cover Art Archive.

**Architecture:** A thin `MusicBrainzService` (structural twin of the existing `LrcLibService`) backs a `MusicBrainzSearchDialog` (structural twin of `LyricsSearchDialog`) that fetches cover art per-selection rather than per-row. `BasicDetailsSection` triggers the dialog and forwards a picked result upward; `AddEditPieceScreen` — the only place that already owns both `mediaItems` and `thumbnailPath` — does the actual three-way piece mutation (title, artist, cover art).

**Tech Stack:** Flutter/Dart, `http` package (already a dependency, `package:http/testing.dart` for tests), `path`/`uuid` packages (already dependencies, used the same way `MediaStorageManager` and `AddEditPieceMediaManager` already use them).

**Spec:** `docs/superpowers/specs/2026-08-24-musicbrainz-cover-art-design.md`

## Global Constraints

- No database schema change — this feature only ever writes to `title`, `artistComposer`, `thumbnailPath`, and `mediaItems`, all of which already exist on `MusicPiece`.
- MusicBrainz and the Cover Art Archive are both public, key-less APIs. Every request carries `User-Agent: Repertoire Music App (Flutter)` (the existing convention from `LrcLibService`), a 10s timeout, and no retry/caching logic.
- Search MusicBrainz's `release` endpoint (not `recording`) — a release MBID is directly usable against the Cover Art Archive with no extra lookup step.
- A release with no cover art (`404` from the Cover Art Archive) is not an error — it's a valid outcome that still applies title/artist, leaves any existing thumbnail untouched, and tells the user via a snackbar.
- Picking a result always overwrites title/artist. It replaces the cover art only when the picked release actually has one.
- This repo has no widget-test infrastructure (established precedent from the lyrics feature). Tasks 2–3 (UI wiring) are verified via `flutter analyze` (zero issues) plus the full existing automated suite staying green, not new widget tests. Task 1 (the service, pure Dart) gets real automated tests, same as `LrcLibService` did.
- Run all Flutter commands with `export PATH="/home/ilbebo/tools/flutter/bin:$PATH"` first in this environment.

---

### Task 1: `MusicBrainzService`

**Files:**
- Create: `lib/services/musicbrainz_service.dart`
- Test: `test/musicbrainz_service_test.dart`

**Interfaces:**
- Produces (used by Task 2):
  - `class MusicBrainzException implements Exception { final String message; MusicBrainzException(this.message); }`
  - `class MusicBrainzResult { final String mbid; final String title; final String artist; final String? date; }`
  - `class MusicBrainzService { MusicBrainzService({http.Client? client}); Future<List<MusicBrainzResult>> search({required String title, required String artist}); Future<Uint8List?> fetchCoverArtBytes(String mbid); }`

- [ ] **Step 1: Write the failing tests**

Create `test/musicbrainz_service_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repertoire/services/musicbrainz_service.dart';

void main() {
  group('MusicBrainzService', () {
    group('search', () {
      test('parses a well-formed response into a list of results', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'releases': [
                {
                  'id': 'abc-123',
                  'title': 'A Night at the Opera',
                  'date': '1975-11-21',
                  'artist-credit': [
                    {'name': 'Queen'},
                  ],
                },
              ],
            }),
            200,
          );
        });
        final service = MusicBrainzService(client: mockClient);

        final results = await service.search(
          title: 'Bohemian Rhapsody',
          artist: 'Queen',
        );

        expect(results, hasLength(1));
        expect(results[0].mbid, 'abc-123');
        expect(results[0].title, 'A Night at the Opera');
        expect(results[0].artist, 'Queen');
        expect(results[0].date, '1975-11-21');
      });

      test('skips entries missing id or title', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'releases': [
                {
                  'title': 'No ID',
                  'artist-credit': [
                    {'name': 'Someone'},
                  ],
                },
                {
                  'id': 'valid-1',
                  'title': 'Valid',
                  'artist-credit': [
                    {'name': 'Valid Artist'},
                  ],
                },
              ],
            }),
            200,
          );
        });
        final service = MusicBrainzService(client: mockClient);

        final results = await service.search(title: 'x', artist: 'y');

        expect(results, hasLength(1));
        expect(results[0].title, 'Valid');
      });

      test('skips entries with empty or missing artist-credit', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'releases': [
                {'id': 'no-artist', 'title': 'No Artist', 'artist-credit': []},
              ],
            }),
            200,
          );
        });
        final service = MusicBrainzService(client: mockClient);

        final results = await service.search(title: 'x', artist: 'y');

        expect(results, isEmpty);
      });

      test('throws MusicBrainzException on non-200 status', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });
        final service = MusicBrainzService(client: mockClient);

        expect(
          () => service.search(title: 'x', artist: 'y'),
          throwsA(isA<MusicBrainzException>()),
        );
      });

      test(
        'throws MusicBrainzException when response has no releases array',
        () async {
          final mockClient = MockClient((request) async {
            return http.Response(jsonEncode({'error': 'nope'}), 200);
          });
          final service = MusicBrainzService(client: mockClient);

          expect(
            () => service.search(title: 'x', artist: 'y'),
            throwsA(isA<MusicBrainzException>()),
          );
        },
      );
    });

    group('fetchCoverArtBytes', () {
      test('returns bytes on 200', () async {
        final mockClient = MockClient((request) async {
          return http.Response.bytes([1, 2, 3, 4], 200);
        });
        final service = MusicBrainzService(client: mockClient);

        final bytes = await service.fetchCoverArtBytes('abc-123');

        expect(bytes, [1, 2, 3, 4]);
      });

      test('returns null on 404 (no cover art)', () async {
        final mockClient = MockClient((request) async {
          return http.Response('', 404);
        });
        final service = MusicBrainzService(client: mockClient);

        final bytes = await service.fetchCoverArtBytes('abc-123');

        expect(bytes, isNull);
      });

      test('throws MusicBrainzException on server error', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });
        final service = MusicBrainzService(client: mockClient);

        expect(
          () => service.fetchCoverArtBytes('abc-123'),
          throwsA(isA<MusicBrainzException>()),
        );
      });
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter test test/musicbrainz_service_test.dart
```

Expected: FAIL to compile — `package:repertoire/services/musicbrainz_service.dart` doesn't exist yet.

- [ ] **Step 3: Implement `MusicBrainzService`**

Create `lib/services/musicbrainz_service.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Thrown when a MusicBrainz search or Cover Art Archive lookup fails
/// (network error, non-200 status, or an unexpected response shape).
class MusicBrainzException implements Exception {
  final String message;
  MusicBrainzException(this.message);

  @override
  String toString() => message;
}

/// One release result from a MusicBrainz search.
class MusicBrainzResult {
  final String mbid;
  final String title;
  final String artist;
  final String? date;

  MusicBrainzResult({
    required this.mbid,
    required this.title,
    required this.artist,
    this.date,
  });

  /// Returns null if the entry is missing an id, a title, or a usable
  /// artist credit — such entries are skipped rather than shown as a
  /// broken result.
  static MusicBrainzResult? fromJson(Map<String, dynamic> json) {
    final mbid = json['id'];
    final title = json['title'];
    if (mbid is! String || title is! String) return null;

    String? artist;
    final artistCredit = json['artist-credit'];
    if (artistCredit is List && artistCredit.isNotEmpty) {
      final first = artistCredit.first;
      if (first is Map<String, dynamic> && first['name'] is String) {
        artist = first['name'] as String;
      }
    }
    if (artist == null) return null;

    final date = json['date'];

    return MusicBrainzResult(
      mbid: mbid,
      title: title,
      artist: artist,
      date: date is String ? date : null,
    );
  }
}

/// Thin client for MusicBrainz's public, key-less release search
/// (https://musicbrainz.org/ws/2/release/) and the Cover Art Archive
/// (https://coverartarchive.org).
class MusicBrainzService {
  final http.Client _client;

  MusicBrainzService({http.Client? client})
    : _client = client ?? http.Client();

  static const String _searchUrl = 'https://musicbrainz.org/ws/2/release/';
  static const String _coverArtBaseUrl =
      'https://coverartarchive.org/release';
  static const Map<String, String> _headers = {
    'User-Agent': 'Repertoire Music App (Flutter)',
  };

  Future<List<MusicBrainzResult>> search({
    required String title,
    required String artist,
  }) async {
    final cleanTitle = title.replaceAll('"', '');
    final cleanArtist = artist.replaceAll('"', '');
    final query = cleanArtist.isEmpty
        ? 'release:"$cleanTitle"'
        : 'release:"$cleanTitle" AND artist:"$cleanArtist"';

    final uri = Uri.parse(_searchUrl).replace(
      queryParameters: {'query': query, 'fmt': 'json', 'limit': '10'},
    );

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw MusicBrainzException('Connection failed');
    }

    if (response.statusCode != 200) {
      throw MusicBrainzException('Server error (${response.statusCode})');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw MusicBrainzException('Invalid response');
    }

    if (decoded is! Map<String, dynamic> || decoded['releases'] is! List) {
      throw MusicBrainzException('Unexpected response format');
    }

    final results = <MusicBrainzResult>[];
    for (final entry in decoded['releases'] as List) {
      if (entry is Map<String, dynamic>) {
        final parsed = MusicBrainzResult.fromJson(entry);
        if (parsed != null) results.add(parsed);
      }
    }
    return results;
  }

  Future<Uint8List?> fetchCoverArtBytes(String mbid) async {
    final uri = Uri.parse('$_coverArtBaseUrl/$mbid/front-250');

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw MusicBrainzException('Connection failed');
    }

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw MusicBrainzException('Server error (${response.statusCode})');
    }

    return response.bodyBytes;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter test test/musicbrainz_service_test.dart
```

Expected: PASS, all 8 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/services/musicbrainz_service.dart test/musicbrainz_service_test.dart
git commit -m "feat: add MusicBrainzService for release search and cover art"
```

---

### Task 2: Localization + `MusicBrainzSearchDialog`

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`, `lib/l10n/app_it.arb`
- Modify (generated, do not hand-edit beyond running the generator): `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_zh.dart`, `lib/l10n/app_localizations_it.dart`
- Create: `lib/widgets/detail_widgets/musicbrainz_search_dialog.dart`

**Interfaces:**
- Consumes: `MusicBrainzService`, `MusicBrainzResult`, `MusicBrainzException` from Task 1.
- Produces (used by Task 3): `class MusicBrainzPickResult { final String title; final String artist; final Uint8List? coverArtBytes; }`; `class MusicBrainzSearchDialog extends StatefulWidget { const MusicBrainzSearchDialog({required String initialTitle, required String initialArtist, MusicBrainzService? service}); }` — shown via `showDialog<MusicBrainzPickResult>(...)`; pops with a `MusicBrainzPickResult` or `null` if cancelled.
- Produces: `context.l10n.searchMusicBrainz`, `.searchMusicBrainzDialogTitle`, `.noCoverArtAvailable`, `.musicBrainzSearchError(String)` — the first three consumed by Task 3, the last by this dialog itself. Reuses existing keys `context.l10n.title`, `context.l10n.artistComposer`, `context.l10n.retry`, and `context.l10n.noLyricsFound` (its English value, "No results found," is domain-generic despite the key's lyrics-sounding name — do not add a near-duplicate key for this dialog's empty-results state).

No automated test for this task (widget-test-free repo precedent) — verified by `flutter analyze` on the new file and, once Task 3 wires it in, the full-project `flutter analyze` + suite run.

- [ ] **Step 1: Add the new ARB keys (English)**

In `lib/l10n/app_en.arb`, find this line (search for `"loggingAndDeveloperOptions"`):

```
  "loggingAndDeveloperOptions": "Logging and developer options",
```

Insert immediately after it:

```
  "searchMusicBrainz": "Search on MusicBrainz",
  "searchMusicBrainzDialogTitle": "Search MusicBrainz",
  "noCoverArtAvailable": "No cover art found for this release",
  "musicBrainzSearchError": "Couldn't reach MusicBrainz: {error}",
  "@musicBrainzSearchError": {
    "description": "Shown when a MusicBrainz search or cover art lookup fails.",
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
  "searchMusicBrainz": "在 MusicBrainz 上搜索",
  "searchMusicBrainzDialogTitle": "搜索 MusicBrainz",
  "noCoverArtAvailable": "未找到此发行版的封面",
  "musicBrainzSearchError": "无法连接到 MusicBrainz：{error}",
  "@musicBrainzSearchError": {
    "description": "Shown when a MusicBrainz search or cover art lookup fails.",
    "placeholders": {
      "error": {
        "type": "String"
      }
    }
  },
```

- [ ] **Step 3: Add the matching keys (Italian)**

In `lib/l10n/app_it.arb`, find the same anchor line (search for `"loggingAndDeveloperOptions"`) and insert immediately after it:

```
  "searchMusicBrainz": "Cerca su MusicBrainz",
  "searchMusicBrainzDialogTitle": "Cerca su MusicBrainz",
  "noCoverArtAvailable": "Nessuna copertina trovata per questa release",
  "musicBrainzSearchError": "Impossibile raggiungere MusicBrainz: {error}",
  "@musicBrainzSearchError": {
    "description": "Shown when a MusicBrainz search or cover art lookup fails.",
    "placeholders": {
      "error": {
        "type": "String"
      }
    }
  },
```

- [ ] **Step 4: Regenerate localization sources**

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter gen-l10n
grep -n "String get searchMusicBrainz " lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_zh.dart lib/l10n/app_localizations_it.dart
```

Expected: the grep prints one matching line per file — confirms the generator picked up the new key in all three locales.

- [ ] **Step 5: Implement `MusicBrainzSearchDialog`**

Create `lib/widgets/detail_widgets/musicbrainz_search_dialog.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:repertoire/l10n/l10n.dart';
import 'package:repertoire/services/musicbrainz_service.dart';

/// Result of picking a MusicBrainz search result: the release's title and
/// artist, plus its cover art bytes (null if this release has no cover art
/// in the Cover Art Archive).
class MusicBrainzPickResult {
  final String title;
  final String artist;
  final Uint8List? coverArtBytes;

  MusicBrainzPickResult({
    required this.title,
    required this.artist,
    this.coverArtBytes,
  });
}

/// A dialog that searches MusicBrainz for a release and, on selection,
/// fetches that release's cover art from the Cover Art Archive.
///
/// Pops with a [MusicBrainzPickResult], or `null` if dismissed without a
/// selection.
class MusicBrainzSearchDialog extends StatefulWidget {
  final String initialTitle;
  final String initialArtist;
  final MusicBrainzService? service;

  const MusicBrainzSearchDialog({
    super.key,
    required this.initialTitle,
    required this.initialArtist,
    this.service,
  });

  @override
  State<MusicBrainzSearchDialog> createState() =>
      _MusicBrainzSearchDialogState();
}

class _MusicBrainzSearchDialogState extends State<MusicBrainzSearchDialog> {
  late final MusicBrainzService _service;
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;

  bool _isSearching = false;
  String? _errorMessage;
  VoidCallback? _retryAction;
  List<MusicBrainzResult>? _results;
  String? _fetchingMbid;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? MusicBrainzService();
    _titleController = TextEditingController(text: widget.initialTitle);
    _artistController = TextEditingController(text: widget.initialArtist);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _retryAction = null;
      _results = null;
    });

    try {
      final results = await _service.search(
        title: title,
        artist: _artistController.text.trim(),
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
        _retryAction = _search;
      });
    }
  }

  Future<void> _pick(MusicBrainzResult result) async {
    setState(() {
      _fetchingMbid = result.mbid;
      _errorMessage = null;
      _retryAction = null;
    });

    try {
      final coverArtBytes = await _service.fetchCoverArtBytes(result.mbid);
      if (!mounted) return;
      Navigator.of(context).pop(
        MusicBrainzPickResult(
          title: result.title,
          artist: result.artist,
          coverArtBytes: coverArtBytes,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fetchingMbid = null;
        _errorMessage = e.toString();
        _retryAction = () => _pick(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleController.text.trim();
    return AlertDialog(
      title: Text(context.l10n.searchMusicBrainzDialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: context.l10n.title),
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _artistController,
              decoration: InputDecoration(
                labelText: context.l10n.artistComposer,
              ),
              onFieldSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.search),
              label: Text(context.l10n.searchMusicBrainz),
              onPressed: (_isSearching || title.isEmpty) ? null : _search,
            ),
            const SizedBox(height: 12),
            if (_isSearching) const Center(child: CircularProgressIndicator()),
            if (_errorMessage != null) ...[
              Text(
                context.l10n.musicBrainzSearchError(_errorMessage!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _retryAction,
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
                          final isFetching = _fetchingMbid == result.mbid;
                          final subtitleParts = <String>[
                            result.artist,
                            if (result.date != null) result.date!,
                          ];
                          return ListTile(
                            enabled: _fetchingMbid == null,
                            title: Text(result.title),
                            subtitle: Text(subtitleParts.join(' • ')),
                            trailing: isFetching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                            onTap: _fetchingMbid == null
                                ? () => _pick(result)
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

- [ ] **Step 6: Verify it compiles**

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter analyze lib/widgets/detail_widgets/musicbrainz_search_dialog.dart
```

Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/l10n/app_it.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_zh.dart lib/l10n/app_localizations_it.dart lib/widgets/detail_widgets/musicbrainz_search_dialog.dart
git commit -m "feat: add MusicBrainzSearchDialog"
```

---

### Task 3: Wire the search into the piece edit screen

**Files:**
- Modify: `lib/widgets/add_edit_piece/basic_details_section.dart`
- Modify: `lib/screens/add_edit_piece_screen.dart`

**Interfaces:**
- Consumes: `MusicBrainzSearchDialog`, `MusicBrainzPickResult` from Task 2; `context.l10n.searchMusicBrainz`, `.noCoverArtAvailable` from Task 2.
- Produces: `BasicDetailsSection` gains a new required constructor parameter `final void Function(String title, String artist, Uint8List? coverArtBytes) onMusicBrainzResultApplied;`.

No new automated test (same widget-test-free precedent) — verified by `flutter analyze` plus the full existing suite, and a manual end-to-end check if `flutter run` against a real device is available in your environment (it was not available in the sandboxed session that wrote this plan — see the plan's Global Constraints).

- [ ] **Step 1: Convert title/artist to controllers and add the search trigger in `BasicDetailsSection`**

`lib/widgets/add_edit_piece/basic_details_section.dart` currently reads:

```dart
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:repertoire/models/music_piece.dart';

import 'package:repertoire/l10n/l10n.dart';

class BasicDetailsSection extends StatefulWidget {
  final MusicPiece musicPiece;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onArtistComposerChanged;
  final ValueChanged<int> onTransposeSemitonesChanged;
  final VoidCallback? onSaveRequested;

  const BasicDetailsSection({
    super.key,
    required this.musicPiece,
    required this.onTitleChanged,
    required this.onArtistComposerChanged,
    required this.onTransposeSemitonesChanged,
    this.onSaveRequested,
  });

  @override
  State<BasicDetailsSection> createState() => _BasicDetailsSectionState();
}

class _BasicDetailsSectionState extends State<BasicDetailsSection> {
  late int _transposeSemitones;

  @override
  void initState() {
    super.initState();
    _transposeSemitones = widget.musicPiece.transposeSemitones;
  }

  String _formatSemitones(int value) => value > 0 ? '+$value' : '$value';

  Future<void> _showTransposePicker() async {
    int pendingValue = _transposeSemitones;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.transposeSemitones),
        content: StatefulBuilder(
          builder: (context, setDialogState) => NumberPicker(
            value: pendingValue,
            minValue: -24,
            maxValue: 24,
            textMapper: (value) => _formatSemitones(int.parse(value)),
            onChanged: (value) =>
                setDialogState(() => pendingValue = value),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(pendingValue),
            child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
          ),
        ],
      ),
    );
    if (result != null && result != _transposeSemitones) {
      setState(() => _transposeSemitones = result);
      widget.onTransposeSemitonesChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          initialValue: widget.musicPiece.title,
          decoration: InputDecoration(labelText: context.l10n.title),
          textInputAction: TextInputAction.next,
          validator: (value) =>
              value!.isEmpty ? context.l10n.pleaseEnterATitle : null,
          onChanged: widget.onTitleChanged,
          onSaved: (value) => widget.onTitleChanged(value!),
        ),
        TextFormField(
          initialValue: widget.musicPiece.artistComposer,
          decoration: InputDecoration(labelText: context.l10n.artistComposer),
          textInputAction: TextInputAction.next,
          onChanged: widget.onArtistComposerChanged,
          onSaved: (value) => widget.onArtistComposerChanged(value!),
        ),
        InkWell(
          onTap: _showTransposePicker,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: context.l10n.transposeSemitones,
            ),
            child: Text(_formatSemitones(_transposeSemitones)),
          ),
        ),
      ],
    );
  }
}
```

Replace the ENTIRE file with:

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/widgets/detail_widgets/musicbrainz_search_dialog.dart';

import 'package:repertoire/l10n/l10n.dart';

class BasicDetailsSection extends StatefulWidget {
  final MusicPiece musicPiece;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onArtistComposerChanged;
  final ValueChanged<int> onTransposeSemitonesChanged;
  final void Function(String title, String artist, Uint8List? coverArtBytes)
  onMusicBrainzResultApplied;
  final VoidCallback? onSaveRequested;

  const BasicDetailsSection({
    super.key,
    required this.musicPiece,
    required this.onTitleChanged,
    required this.onArtistComposerChanged,
    required this.onTransposeSemitonesChanged,
    required this.onMusicBrainzResultApplied,
    this.onSaveRequested,
  });

  @override
  State<BasicDetailsSection> createState() => _BasicDetailsSectionState();
}

class _BasicDetailsSectionState extends State<BasicDetailsSection> {
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late int _transposeSemitones;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.musicPiece.title);
    _artistController = TextEditingController(
      text: widget.musicPiece.artistComposer,
    );
    _transposeSemitones = widget.musicPiece.transposeSemitones;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  String _formatSemitones(int value) => value > 0 ? '+$value' : '$value';

  Future<void> _showTransposePicker() async {
    int pendingValue = _transposeSemitones;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.transposeSemitones),
        content: StatefulBuilder(
          builder: (context, setDialogState) => NumberPicker(
            value: pendingValue,
            minValue: -24,
            maxValue: 24,
            textMapper: (value) => _formatSemitones(int.parse(value)),
            onChanged: (value) =>
                setDialogState(() => pendingValue = value),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(pendingValue),
            child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
          ),
        ],
      ),
    );
    if (result != null && result != _transposeSemitones) {
      setState(() => _transposeSemitones = result);
      widget.onTransposeSemitonesChanged(result);
    }
  }

  Future<void> _showMusicBrainzSearch() async {
    final result = await showDialog<MusicBrainzPickResult>(
      context: context,
      builder: (dialogContext) => MusicBrainzSearchDialog(
        initialTitle: _titleController.text,
        initialArtist: _artistController.text,
      ),
    );
    if (result == null) return;

    _titleController.text = result.title;
    _artistController.text = result.artist;
    widget.onMusicBrainzResultApplied(
      result.title,
      result.artist,
      result.coverArtBytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(labelText: context.l10n.title),
          textInputAction: TextInputAction.next,
          validator: (value) =>
              value!.isEmpty ? context.l10n.pleaseEnterATitle : null,
          onChanged: widget.onTitleChanged,
          onSaved: (value) => widget.onTitleChanged(value!),
        ),
        TextFormField(
          controller: _artistController,
          decoration: InputDecoration(labelText: context.l10n.artistComposer),
          textInputAction: TextInputAction.next,
          onChanged: widget.onArtistComposerChanged,
          onSaved: (value) => widget.onArtistComposerChanged(value!),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.search),
            label: Text(context.l10n.searchMusicBrainz),
            onPressed: _showMusicBrainzSearch,
          ),
        ),
        InkWell(
          onTap: _showTransposePicker,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: context.l10n.transposeSemitones,
            ),
            child: Text(_formatSemitones(_transposeSemitones)),
          ),
        ),
      ],
    );
  }
}
```

Note: `_titleController.text = result.title` and `_artistController.text = result.artist` are assigned directly, WITHOUT wrapping in `setState` — a `TextEditingController` is a `ChangeNotifier` that the `TextFormField` it's attached to already listens to directly, so assigning `.text` alone triggers the field to redraw. This matches the exact pattern already used for `_lyricsController` in `lib/widgets/detail_widgets/media_section.dart` — do not add a `setState` wrapper here; it would be redundant, not wrong, but inconsistent with the established codebase convention.

- [ ] **Step 2: Add the piece-level handler in `AddEditPieceScreen`**

In `lib/screens/add_edit_piece_screen.dart`, the imports currently read:

```dart
import 'package:repertoire/models/tag_group.dart';
import 'package:flutter/material.dart';
import '../models/music_piece.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../models/learning_progress_config.dart';
import '../widgets/add_edit_piece/learning_progress_config_dialog.dart';

import '../models/group.dart';
import '../database/music_piece_repository.dart';
import '../utils/app_logger.dart';
import '../widgets/add_edit_piece/basic_details_section.dart';
import '../widgets/add_edit_piece/groups_section.dart';
import '../widgets/add_edit_piece/tag_groups_section.dart';
import '../widgets/add_edit_piece/media_section.dart';
import '../widgets/add_edit_piece/speed_dial_widget.dart';
import 'add_edit_piece/add_edit_piece_media_manager.dart';
import 'add_edit_piece/add_edit_piece_tag_manager.dart';
import 'add_edit_piece/add_edit_piece_form_handler.dart';

import 'dart:io';
import 'package:repertoire/services/pitch_controllable_player.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

import 'package:repertoire/l10n/l10n.dart';
```

Change to (adding four imports: `dart:typed_data`, `path`, `uuid`, and `MediaStorageManager`):

```dart
import 'package:repertoire/models/tag_group.dart';
import 'package:flutter/material.dart';
import '../models/music_piece.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../models/learning_progress_config.dart';
import '../widgets/add_edit_piece/learning_progress_config_dialog.dart';

import '../models/group.dart';
import '../database/music_piece_repository.dart';
import '../utils/app_logger.dart';
import '../widgets/add_edit_piece/basic_details_section.dart';
import '../widgets/add_edit_piece/groups_section.dart';
import '../widgets/add_edit_piece/tag_groups_section.dart';
import '../widgets/add_edit_piece/media_section.dart';
import '../widgets/add_edit_piece/speed_dial_widget.dart';
import 'add_edit_piece/add_edit_piece_media_manager.dart';
import 'add_edit_piece/add_edit_piece_tag_manager.dart';
import 'add_edit_piece/add_edit_piece_form_handler.dart';

import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:repertoire/services/media_storage_manager.dart';
import 'package:repertoire/services/pitch_controllable_player.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

import 'package:repertoire/l10n/l10n.dart';
```

Next, still in `lib/screens/add_edit_piece_screen.dart`, find the `_onMediaItemsChanged` method:

```dart
  void _onMediaItemsChanged(List<MediaItem> newMediaItems) {
    final currentIds = _musicPiece.mediaItems.map((e) => e.id).toSet();
    final newId = newMediaItems
        .map((e) => e.id)
        .firstWhere((id) => !currentIds.contains(id), orElse: () => '');

    setState(() {
      _musicPiece = _musicPiece.copyWith(mediaItems: newMediaItems);
      if (newId.isNotEmpty) {
        final newItem = newMediaItems.firstWhere((e) => e.id == newId);
        if (newItem.type == MediaType.thumbnails) {
          _musicPiece = _musicPiece.copyWith(thumbnailPath: newItem.pathOrUrl);
        }
        _newlyAddedIds = [newId];
        _scrollToItem(newId);
      }
    });
  }
```

Add a new method immediately after it (same indentation level, inside the
same `State` class):

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
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
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
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noCoverArtAvailable)),
      );
    }

    if (!mounted) return;
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

- [ ] **Step 3: Wire the new callback into `BasicDetailsSection`'s constructor call**

Still in `lib/screens/add_edit_piece_screen.dart`, find:

```dart
                    child: BasicDetailsSection(
                      musicPiece: _musicPiece,
                      onTitleChanged: (value) => _musicPiece.title = value,
                      onArtistComposerChanged: (value) =>
                          _musicPiece.artistComposer = value,
                      onTransposeSemitonesChanged: (value) =>
                          _musicPiece.transposeSemitones = value,
                      onSaveRequested: _savePiece,
```

Change to:

```dart
                    child: BasicDetailsSection(
                      musicPiece: _musicPiece,
                      onTitleChanged: (value) => _musicPiece.title = value,
                      onArtistComposerChanged: (value) =>
                          _musicPiece.artistComposer = value,
                      onTransposeSemitonesChanged: (value) =>
                          _musicPiece.transposeSemitones = value,
                      onMusicBrainzResultApplied: _onMusicBrainzResultApplied,
                      onSaveRequested: _savePiece,
```

- [ ] **Step 4: Verify the project compiles and the full test suite passes**

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter analyze
```

Expected: `No issues found!` (the same small set of pre-existing
`deprecated_member_use` info notices from before this feature are fine;
there must be zero new errors).

```bash
export PATH="/home/ilbebo/tools/flutter/bin:$PATH"
flutter test
```

Expected: `All tests passed!` — paste the ACTUAL raw output of both commands
into your report, not a summary.

- [ ] **Step 5: Manual verification (if a running app is reachable)**

If this environment can run the app (e.g. `flutter run -d <device-id>`
against a connected device or emulator — check `flutter devices` first; if
none are available or the environment has no interactive display, skip
this step and say so explicitly in your report rather than attempting it):

1. Open an existing piece (or create one, e.g. title "Bohemian Rhapsody",
   artist "Queen") → edit.
2. Confirm a "Search on MusicBrainz" button appears below the artist field.
3. Tap it. Confirm the dialog opens prefilled with the current title/artist.
4. Tap Search. Confirm a result list appears (requires network access)
   with title/artist/date per row.
5. Tap a result. Confirm the dialog shows a brief loading spinner on that
   row, then closes.
6. Confirm the title/artist fields in the edit screen now show the picked
   release's values, and (if that release had cover art) the piece's
   thumbnail has changed. If no cover art was found, confirm a snackbar
   says so and the previous thumbnail (if any) is unchanged.
7. Save the piece. Reopen it. Confirm the new title/artist/thumbnail
   persisted.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/add_edit_piece/basic_details_section.dart lib/screens/add_edit_piece_screen.dart
git commit -m "feat: wire MusicBrainz search into the piece edit screen"
```
