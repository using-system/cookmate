import 'package:cookmate/features/recipe/domain/recipe_config.dart';
import 'package:cookmate/features/recipe/presentation/dietary_restrictions_tile.dart';
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

  testWidgets('displays "None" subtitle when dietary restrictions are empty',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const DietaryRestrictionsTile()));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsDietaryRestrictionsTitle), findsOneWidget);
    expect(find.text(l10n.settingsDietaryRestrictionsNone), findsOneWidget);
  });

  testWidgets('displays restriction text when dietary restrictions are set',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    const restrictions = 'gluten-free, vegetarian';

    await tester.pumpWidget(
      _wrap(
        const DietaryRestrictionsTile(),
        overrides: [
          recipeConfigProvider.overrideWith(
            () => _FakeRecipeConfigNotifier(
              const RecipeConfig(dietaryRestrictions: restrictions),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(restrictions), findsOneWidget);
  });
}

class _FakeRecipeConfigNotifier extends RecipeConfigNotifier {
  _FakeRecipeConfigNotifier(this._config);
  final RecipeConfig _config;

  @override
  Future<RecipeConfig> build() async => _config;
}
