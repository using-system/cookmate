import 'package:cookmate/features/l10n/presentation/language_picker_tile.dart';
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

AppLocalizations _l10n(WidgetTester tester) {
  return AppLocalizations.of(tester.element(find.byType(Scaffold)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'subtitle shows follow-system hint with resolved language when preference is system',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(_wrap(const LanguagePickerTile()));
      await tester.pumpAndSettle();

      final l10n = _l10n(tester);
      expect(find.text(l10n.settingsLanguageTitle), findsOneWidget);
      expect(
        find.text(l10n.settingsLanguageFollowSystem('English')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'subtitle shows the language name in its own language when preference is forced',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'locale_preference': 'fr',
      });

      await tester.pumpWidget(
        _wrap(const LanguagePickerTile(), locale: const Locale('fr')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Français'), findsOneWidget);
    },
  );
}
