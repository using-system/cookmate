import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'features/l10n/providers.dart';

class CookmateApp extends ConsumerWidget {
  const CookmateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(effectiveLocaleProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveLocale,
      routerConfig: router,
    );
  }
}

@visibleForTesting
Locale resolveLocale(Locale? deviceLocale, Iterable<Locale> supportedLocales) {
  if (deviceLocale == null) {
    return const Locale('en');
  }
  for (final supported in supportedLocales) {
    if (supported.languageCode == deviceLocale.languageCode) {
      return supported;
    }
  }
  return const Locale('en');
}
