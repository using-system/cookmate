import 'package:cookmate/features/l10n/domain/locale_preference.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalePreference.fromStorageValue', () {
    test('returns SystemLocalePreference when raw is null', () {
      expect(
        LocalePreference.fromStorageValue(null),
        const SystemLocalePreference(),
      );
    });

    test('returns SystemLocalePreference when raw is "system"', () {
      expect(
        LocalePreference.fromStorageValue('system'),
        const SystemLocalePreference(),
      );
    });

    for (final code in LocalePreference.supportedLanguageCodes) {
      test('returns ForcedLocalePreference for supported code "$code"', () {
        final result = LocalePreference.fromStorageValue(code);

        expect(result, isA<ForcedLocalePreference>());
        expect(
          (result as ForcedLocalePreference).locale.languageCode,
          code,
        );
      });
    }

    test('returns SystemLocalePreference for an unsupported language code',
        () {
      expect(
        LocalePreference.fromStorageValue('ja'),
        const SystemLocalePreference(),
      );
    });

    test('returns SystemLocalePreference for an empty string', () {
      expect(
        LocalePreference.fromStorageValue(''),
        const SystemLocalePreference(),
      );
    });
  });

  group('LocalePreference.toStorageValue', () {
    test('SystemLocalePreference serializes to "system"', () {
      expect(const SystemLocalePreference().toStorageValue(), 'system');
    });

    test('ForcedLocalePreference serializes to its language code', () {
      expect(
        ForcedLocalePreference(const Locale('fr')).toStorageValue(),
        'fr',
      );
    });
  });

  group('LocalePreference equality', () {
    test('two SystemLocalePreference instances compare equal', () {
      expect(
        const SystemLocalePreference(),
        equals(const SystemLocalePreference()),
      );
    });

    test('two ForcedLocalePreference with same language code compare equal',
        () {
      expect(
        ForcedLocalePreference(const Locale('fr')),
        equals(ForcedLocalePreference(const Locale('fr'))),
      );
    });

    test('ForcedLocalePreference with different codes are not equal', () {
      expect(
        ForcedLocalePreference(const Locale('fr')),
        isNot(equals(ForcedLocalePreference(const Locale('en')))),
      );
    });

    test('SystemLocalePreference and ForcedLocalePreference are not equal',
        () {
      expect(
        const SystemLocalePreference(),
        isNot(equals(ForcedLocalePreference(const Locale('fr')))),
      );
    });
  });
}
