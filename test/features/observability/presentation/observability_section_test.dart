import 'package:cookmate/features/observability/presentation/crashlytics_toggle_tile.dart';
import 'package:cookmate/features/observability/presentation/observability_section.dart';
import 'package:cookmate/features/observability/providers.dart';
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotifier extends CrashlyticsPreferenceNotifier {
  @override
  Future<bool> build() async => false;

  @override
  Future<void> setPreference(bool enabled) async {
    state = AsyncValue.data(enabled);
  }
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      crashlyticsPreferenceProvider.overrideWith(() => _FakeNotifier()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('contains CrashlyticsToggleTile', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const ObservabilitySection()));
    await tester.pumpAndSettle();

    expect(find.byType(CrashlyticsToggleTile), findsOneWidget);
  });

  testWidgets('contains a Divider', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const ObservabilitySection()));
    await tester.pumpAndSettle();

    expect(find.byType(Divider), findsOneWidget);
  });
}
