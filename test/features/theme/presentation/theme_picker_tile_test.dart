import 'package:cookmate/features/theme/presentation/theme_picker_tile.dart';
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

  testWidgets('shows the Dark option label as subtitle on first launch',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const ThemePickerTile()));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsThemeTitle), findsOneWidget);
    expect(find.text(l10n.settingsThemeOptionDark), findsOneWidget);
  });

  testWidgets('shows the stored theme label as subtitle', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'theme_preference': 'matrix',
    });

    await tester.pumpWidget(_wrap(const ThemePickerTile()));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsThemeOptionMatrix), findsOneWidget);
  });

  testWidgets('tapping a dialog option updates the subtitle', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const ThemePickerTile()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    await tester.tap(find.text(l10n.settingsThemeOptionPink));
    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsThemeOptionPink), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_preference'), 'pink');
  });
}
