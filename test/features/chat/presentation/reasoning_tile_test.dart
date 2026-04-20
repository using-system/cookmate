import 'package:cookmate/features/chat/presentation/reasoning_tile.dart';
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}

AppLocalizations _l10n(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold));
  return AppLocalizations.of(context);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows disabled subtitle when reasoning is off by default',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const ReasoningTile()));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsReasoningTitle), findsOneWidget);
    expect(find.text(l10n.settingsReasoningSubtitleOff), findsOneWidget);
  });

  testWidgets('toggling switch persists true', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const ReasoningTile()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('chat_reasoning_preference'), true);
  });

  testWidgets('shows disabled subtitle when stored as false', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'chat_reasoning_preference': false,
    });

    await tester.pumpWidget(_wrap(const ReasoningTile()));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsReasoningSubtitleOff), findsOneWidget);
  });
}
