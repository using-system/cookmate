import 'package:cookmate/features/recipe/domain/recipe_config.dart';
import 'package:cookmate/features/recipe/presentation/portions_picker_tile.dart';
import 'package:cookmate/features/recipe/providers.dart';
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('en'),
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

  testWidgets('displays the Portions title and default portions value',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const PortionsPickerTile()));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsPortionsTitle), findsOneWidget);
    expect(
      find.text(l10n.settingsPortionsValue(RecipeConfig.defaultPortions)),
      findsOneWidget,
    );
  });

  testWidgets('displays a custom portions value from config', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      _wrap(
        const PortionsPickerTile(),
        overrides: [
          recipeConfigProvider.overrideWith(
            () => _FakeRecipeConfigNotifier(
              const RecipeConfig(portions: 6),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsPortionsValue(6)), findsOneWidget);
  });
}

class _FakeRecipeConfigNotifier extends RecipeConfigNotifier {
  _FakeRecipeConfigNotifier(this._config);
  final RecipeConfig _config;

  @override
  Future<RecipeConfig> build() async => _config;
}
