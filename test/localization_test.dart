import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:repertoire/l10n/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('English and Simplified Chinese are supported', () {
    expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
    expect(AppLocalizations.supportedLocales, contains(const Locale('zh')));
  });

  test(
    'localizations load static, parameterized, and plural messages',
    () async {
      final english = await AppLocalizations.delegate.load(const Locale('en'));
      final chinese = await AppLocalizations.delegate.load(const Locale('zh'));

      expect(english.appTitle, 'Music Repertoire');
      expect(chinese.appTitle, '音乐曲目库');
      expect(english.languageName, 'English');
      expect(chinese.languageName, '简体中文');
      expect(chinese.mediaAddedToPiece('月光奏鸣曲'), '媒体已添加到“月光奏鸣曲”');
      expect(english.durationMinutes(3), '3 minutes');
      expect(chinese.durationMinutes(3), '3 分钟');
    },
  );
}
