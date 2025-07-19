import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/utils/app_logger.dart';

class MusicPieceFilter {
  final String searchQuery;
  final Map<String, dynamic> filterOptions;
  final String sortOption;

  MusicPieceFilter({
    required this.searchQuery,
    required this.filterOptions,
    required this.sortOption,
  });

  List<MusicPiece> filterAndSort(List<MusicPiece> pieces) {
    AppLogger.log('MusicPieceFilter: filterAndSort called with searchQuery: "$searchQuery" and ${pieces.length} pieces');
    List<MusicPiece> filteredPieces = pieces.where((piece) {
      final lowerCaseSearchQuery = searchQuery.toLowerCase();
      // Check if the piece matches the search query in title, artist/composer, or tags.
      // Only apply search filter if searchQuery is not empty
      final matchesSearch = searchQuery.isEmpty || 
          piece.title.toLowerCase().contains(lowerCaseSearchQuery) ||
          piece.artistComposer.toLowerCase().contains(lowerCaseSearchQuery) ||
          piece.tagGroups.any((tg) => tg.tags.any((tag) => tag.toLowerCase().contains(lowerCaseSearchQuery))) ||
          piece.tags.any((t) => t.toLowerCase().contains(lowerCaseSearchQuery));
      
      AppLogger.log('MusicPieceFilter: Piece "${piece.title}" - searchQuery: "$searchQuery", matchesSearch: $matchesSearch');
      
      if (!matchesSearch && searchQuery.isNotEmpty) {
        AppLogger.log('MusicPieceFilter: Piece "${piece.title}" filtered out by search');
      }

      // Check for title match from filter options.
      final titleMatch = filterOptions['title'] == null ||
          piece.title.toLowerCase().contains(filterOptions['title'].toLowerCase());
      // Check for artist/composer match from filter options.
      final artistComposerMatch = filterOptions['artistComposer'] == null ||
          piece.artistComposer.toLowerCase().contains(filterOptions['artistComposer'].toLowerCase());
      // Check for ordered tags match from filter options.
      final orderedTagsMatch = (filterOptions['orderedTags'] == null || (filterOptions['orderedTags'] as Map<String, List<String>>).isEmpty) ||
          (filterOptions['orderedTags'] as Map<String, List<String>>).entries.every((entry) {
            final selectedTagSetName = entry.key;
            final selectedTags = entry.value;
            return piece.tagGroups.any((pieceTagGroup) =>
                pieceTagGroup.name == selectedTagSetName &&
                selectedTags.every((selectedTag) => pieceTagGroup.tags.contains(selectedTag)));
          });
      // Check for general tags match from filter options.
      final tagsMatch = filterOptions['tags'] == null ||
          piece.tags.any((t) => t.toLowerCase().contains(filterOptions['tags'].toLowerCase()));

      // Apply practice tracking filter.
      final practiceTrackingFilter = filterOptions['practiceTracking'];
      bool practiceTrackingMatch = true;
      if (practiceTrackingFilter == 'enabled') {
        practiceTrackingMatch = piece.enablePracticeTracking;
      } else if (practiceTrackingFilter == 'disabled') {
        practiceTrackingMatch = !piece.enablePracticeTracking;
      }

      // Apply practice duration filter.
      final practiceDurationFilter = filterOptions['practiceDuration'];
      bool practiceDurationMatch = true;
      if (practiceDurationFilter != null) {
        if (practiceDurationFilter == 'last7Days') {
          practiceDurationMatch = piece.lastPracticeTime != null &&
              DateTime.now().difference(piece.lastPracticeTime!).inDays <= 7;
        } else if (practiceDurationFilter == 'notIn30Days') {
          practiceDurationMatch = piece.lastPracticeTime != null &&
              DateTime.now().difference(piece.lastPracticeTime!).inDays > 30;
        } else if (practiceDurationFilter == 'neverPracticed') {
          practiceDurationMatch = piece.lastPracticeTime == null;
        }
      }

      // Combine all filter conditions.
      return matchesSearch && titleMatch && artistComposerMatch && orderedTagsMatch && tagsMatch && practiceTrackingMatch && practiceDurationMatch;
    }).toList();

    // Apply sorting based on the selected sort option.
    if (sortOption == 'alphabetical_asc') {
      filteredPieces.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (sortOption == 'alphabetical_desc') {
      filteredPieces.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
    } else if (sortOption.startsWith('last_practiced')) {
      filteredPieces.sort((a, b) {
        // Prioritize pieces with practice tracking enabled.
        if (a.enablePracticeTracking && !b.enablePracticeTracking) return -1;
        if (!a.enablePracticeTracking && b.enablePracticeTracking) return 1;
        if (!a.enablePracticeTracking && !b.enablePracticeTracking) return 0;

        // Handle pieces that have never been practiced.
        final aNeverPracticed = a.lastPracticeTime == null;
        final bNeverPracticed = b.lastPracticeTime == null;
        if (aNeverPracticed && bNeverPracticed) return 0;

        // Sort by last practice time (ascending or descending).
        if (sortOption == 'last_practiced_asc') {
          if (aNeverPracticed) return 1;
          if (bNeverPracticed) return -1;
          return a.lastPracticeTime!.compareTo(b.lastPracticeTime!);
        } else {
          if (aNeverPracticed) return 1;
          if (bNeverPracticed) return -1;
          return b.lastPracticeTime!.compareTo(a.lastPracticeTime!);
        }
      });
    }

    return filteredPieces;
  }
}
