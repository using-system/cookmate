import 'package:cookmate/app.dart';
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveLocale', () {
    final supported = AppLocalizations.supportedLocales;

    test('falls back to English when device locale is null', () {
      expect(resolveLocale(null, supported), const Locale('en'));
    });

    test('falls back to English when device language is unsupported', () {
      expect(resolveLocale(const Locale('ja'), supported), const Locale('en'));
    });

    test('returns the supported locale matching the device language code', () {
      for (final code in ['en', 'fr', 'es', 'de']) {
        final resolved = resolveLocale(Locale(code), supported);

        expect(resolved.languageCode, code);
      }
    });

    test('matches on language code even when device locale has a country code',
        () {
      final resolved = resolveLocale(const Locale('fr', 'CA'), supported);

      expect(resolved.languageCode, 'fr');
    });
  });
}
