import 'package:flutter_test/flutter_test.dart';
import 'package:repertoire/utils/settings_manager.dart';

void main() {
  group('SettingsManager.renameTagGroupInOrderedTags', () {
    test('renames group key and preserves tags', () {
      final input = {
        'Genre': ['Jazz', 'Classical'],
        'Level': ['Beginner'],
      };

      final result = SettingsManager.renameTagGroupInOrderedTags(
        input,
        'Genre',
        'Style',
      );

      expect(result.containsKey('Genre'), isFalse);
      expect(result['Style'], ['Jazz', 'Classical']);
      expect(result['Level'], ['Beginner']);
    });

    test('no-op when group is not present', () {
      final input = {
        'Level': ['Beginner'],
      };
      final result = SettingsManager.renameTagGroupInOrderedTags(
        input,
        'Genre',
        'Style',
      );
      expect(result, input);
    });

    test('merges tags when target group already exists', () {
      final input = {
        'Genre': ['Jazz'],
        'Style': ['Rock'],
      };
      final result = SettingsManager.renameTagGroupInOrderedTags(
        input,
        'Genre',
        'Style',
      );
      expect(result.containsKey('Genre'), isFalse);
      expect(result['Style'], ['Rock', 'Jazz']);
    });
  });

  group('SettingsManager.renameTagInOrderedTags', () {
    test('renames tag within the specified group only', () {
      final input = {
        'Genre': ['Jazz', 'Classical'],
        'Mood': ['Jazz'],
      };

      final result = SettingsManager.renameTagInOrderedTags(
        input,
        'Genre',
        'Jazz',
        'Jazz/Fusion',
      );

      expect(result['Genre'], ['Jazz/Fusion', 'Classical']);
      expect(result['Mood'], ['Jazz']);
    });

    test('dedupes when new name already exists in group', () {
      final input = {
        'Genre': ['Jazz', 'Fusion'],
      };
      final result = SettingsManager.renameTagInOrderedTags(
        input,
        'Genre',
        'Jazz',
        'Fusion',
      );
      expect(result['Genre'], ['Fusion']);
    });

    test('no-op when group is not present', () {
      final input = {
        'Level': ['Beginner'],
      };
      final result = SettingsManager.renameTagInOrderedTags(
        input,
        'Genre',
        'Jazz',
        'Blues',
      );
      expect(result, input);
    });
  });

  group('SettingsManager filter options helpers', () {
    test('renameTagGroupInFilterOptions updates orderedTags', () {
      final options = {
        'orderedTags': {
          'Genre': ['Jazz'],
        },
        'practiceTracking': 'enabled',
      };

      final result = SettingsManager.renameTagGroupInFilterOptions(
        options,
        'Genre',
        'Style',
      );

      expect(result['orderedTags']['Style'], ['Jazz']);
      expect(result['practiceTracking'], 'enabled');
      expect(
        (result['orderedTags'] as Map).containsKey('Genre'),
        isFalse,
      );
    });

    test('renameTagInFilterOptions updates tag values', () {
      final options = {
        'orderedTags': {
          'Genre': ['Jazz', 'Rock'],
        },
      };

      final result = SettingsManager.renameTagInFilterOptions(
        options,
        'Genre',
        'Jazz',
        'Blues',
      );

      expect(result['orderedTags']['Genre'], ['Blues', 'Rock']);
    });
  });
}
