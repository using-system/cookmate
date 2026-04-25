import 'package:cookmate/features/observability/presentation/performance_toggle_tile.dart';
import 'package:cookmate/features/observability/providers.dart';
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotifier extends PerformancePreferenceNotifier {
  _FakeNotifier(this._initial);
  final bool _initial;

  @override
  Future<bool> build() async => _initial;

  @override
  Future<void> setPreference(bool enabled) async {
    final storage =
        await ref.read(performancePreferenceStorageProvider.future);
    state = const AsyncValue<bool>.loading().copyWithPrevious(state);
    await storage.write(enabled);
    state = AsyncValue.data(enabled);
  }
}

Widget _wrap(Widget child, {bool initialValue = true}) {
  return ProviderScope(
    overrides: [
      performancePreferenceProvider.overrideWith(
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
      _wrap(const PerformanceToggleTile()),
    );
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsPerformanceTitle), findsOneWidget);
    expect(find.text(l10n.settingsPerformanceDescription), findsOneWidget);
  });

  testWidgets('switch defaults to on', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      _wrap(const PerformanceToggleTile(), initialValue: true),
    );
    await tester.pumpAndSettle();

    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, true);
  });

  testWidgets('switch reflects provided false value', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'observability_performance_enabled': false,
    });

    await tester.pumpWidget(
      _wrap(const PerformanceToggleTile(), initialValue: false),
    );
    await tester.pumpAndSettle();

    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, false);
  });

  testWidgets('toggling switch persists false', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      _wrap(const PerformanceToggleTile()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('observability_performance_enabled'), false);
  });

  testWidgets('shows speed icon', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      _wrap(const PerformanceToggleTile()),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.speed), findsOneWidget);
  });
}
