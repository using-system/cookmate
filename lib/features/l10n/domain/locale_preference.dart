import 'package:flutter/widgets.dart';

sealed class LocalePreference {
  const LocalePreference();

  static const Set<String> supportedLanguageCodes = {'en', 'fr', 'es', 'de'};

  String toStorageValue();

  static LocalePreference fromStorageValue(String? raw) {
    if (raw == null || raw == 'system') {
      return const SystemLocalePreference();
    }
    if (supportedLanguageCodes.contains(raw)) {
      return ForcedLocalePreference(Locale(raw));
    }
    return const SystemLocalePreference();
  }
}

class SystemLocalePreference extends LocalePreference {
  const SystemLocalePreference();

  @override
  String toStorageValue() => 'system';
}

class ForcedLocalePreference extends LocalePreference {
  const ForcedLocalePreference(this.locale);

  final Locale locale;

  @override
  String toStorageValue() => locale.languageCode;
}
