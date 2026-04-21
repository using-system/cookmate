import 'package:cookmate/features/cookidoo/data/cookidoo_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CookidooClient.countryCodeFromLocale', () {
    test('extracts country code from standard locale (en-US → us)', () {
      expect(CookidooClient.countryCodeFromLocale('en-US'), 'us');
    });

    test('extracts country code from fr-FR locale', () {
      expect(CookidooClient.countryCodeFromLocale('fr-FR'), 'fr');
    });

    test('extracts country code in lowercase from de-DE', () {
      expect(CookidooClient.countryCodeFromLocale('de-DE'), 'de');
    });

    test('returns language code unchanged when no region tag is present', () {
      expect(CookidooClient.countryCodeFromLocale('en'), 'en');
    });

    test('returns gb for en-GB locale', () {
      expect(CookidooClient.countryCodeFromLocale('en-GB'), 'gb');
    });

    test('handles locales with multiple parts (returns last part)', () {
      // e.g. zh-Hant-TW → tw
      expect(CookidooClient.countryCodeFromLocale('zh-Hant-TW'), 'tw');
    });

    test('lowercases the country code', () {
      expect(CookidooClient.countryCodeFromLocale('pt-BR'), 'br');
    });
  });
}
