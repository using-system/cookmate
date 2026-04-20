import 'package:cookmate/features/chat/presentation/expert_picker_tile.dart';
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

  testWidgets('shows default summary in subtitle', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const ExpertPickerTile()));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsExpertTitle), findsOneWidget);
    expect(find.textContaining('8000'), findsOneWidget);
    expect(find.textContaining('0.80'), findsOneWidget);
  });

  testWidgets('tapping opens dialog with sliders', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const ExpertPickerTile()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsExpertDialogTitle), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(4));
  });

  testWidgets('shows stored values in subtitle', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'expert_max_tokens': 16000,
      'expert_top_k': 32,
      'expert_top_p': 0.8,
      'expert_temperature': 1.50,
    });

    await tester.pumpWidget(_wrap(const ExpertPickerTile()));
    await tester.pumpAndSettle();

    expect(find.textContaining('16000'), findsOneWidget);
    expect(find.textContaining('1.50'), findsOneWidget);
  });
}
