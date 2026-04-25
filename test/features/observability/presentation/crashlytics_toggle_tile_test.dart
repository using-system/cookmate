import 'package:cookmate/features/observability/presentation/crashlytics_toggle_tile.dart';
import 'package:cookmate/features/observability/providers.dart';
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotifier extends CrashlyticsPreferenceNotifier {
  _FakeNotifier(this._initial);
  final bool _initial;

  @override
  Future<bool> build() async => _initial;

  @override
  Future<void> setPreference(bool enabled) async {
    final storage =
        await ref.read(crashlyticsPreferenceStorageProvider.future);
    state = const AsyncValue<bool>.loading().copyWithPrevious(state);
    await storage.write(enabled);
    state = AsyncValue.data(enabled);
  }
}

Widget _wrap(Widget child, {bool initialValue = false}) {
  return ProviderScope(
    overrides: [
      crashlyticsPreferenceProvider.overrideWith(
        () => _FakeNotifier(initialValue),
      ),
    ],
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

  testWidgets('shows title and description', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      _wrap(const CrashlyticsToggleTile()),
    );
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsCrashlyticsTitle), findsOneWidget);
    expect(find.text(l10n.settingsCrashlyticsDescription), findsOneWidget);
  });

  testWidgets('switch defaults to on', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      _wrap(const CrashlyticsToggleTile(), initialValue: true),
    );
    await tester.pumpAndSettle();

    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, true);
  });

  testWidgets('switch reflects stored true value', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'observability_crashlytics_enabled': true,
    });

    await tester.pumpWidget(
      _wrap(const CrashlyticsToggleTile(), initialValue: true),
    );
    await tester.pumpAndSettle();

    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, true);
  });

  testWidgets('toggling switch persists true', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      _wrap(const CrashlyticsToggleTile()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('observability_crashlytics_enabled'), true);
  });

  testWidgets('shows bug report icon', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      _wrap(const CrashlyticsToggleTile()),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
  });
}
