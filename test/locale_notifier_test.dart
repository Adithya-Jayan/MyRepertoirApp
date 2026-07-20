import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:repertoire/utils/locale_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const supportedLocales = [Locale('en'), Locale('zh'), Locale('de')];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to following the system locale', () async {
    final notifier = LocaleNotifier(supportedLocales: supportedLocales);

    await notifier.loadLocale();

    expect(notifier.locale, isNull);
    expect(notifier.preference, LocaleNotifier.systemPreference);
  });

  test('persists and restores any generated supported locale', () async {
    final notifier = LocaleNotifier(supportedLocales: supportedLocales);

    await notifier.setLocale(const Locale('de'));

    expect(notifier.locale, const Locale('de'));
    expect(
      (await SharedPreferences.getInstance()).getString(
        LocaleNotifier.preferenceKey,
      ),
      'de',
    );

    final restoredNotifier = LocaleNotifier(supportedLocales: supportedLocales);
    await restoredNotifier.loadLocale();

    expect(restoredNotifier.locale, const Locale('de'));
    expect(restoredNotifier.preference, 'de');
  });

  test('falls back to system for an unknown saved language', () async {
    SharedPreferences.setMockInitialValues({
      LocaleNotifier.preferenceKey: 'unsupported',
    });
    final notifier = LocaleNotifier(
      supportedLocales: supportedLocales,
      initialLocale: const Locale('en'),
    );

    await notifier.loadLocale();

    expect(notifier.locale, isNull);
  });

  test('rejects a locale that was not generated from an ARB file', () async {
    final notifier = LocaleNotifier(supportedLocales: supportedLocales);

    await expectLater(
      notifier.setLocale(const Locale('fr')),
      throwsArgumentError,
    );
    expect(notifier.locale, isNull);
  });
}
