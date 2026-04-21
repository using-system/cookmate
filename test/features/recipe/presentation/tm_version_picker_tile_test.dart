import 'package:cookmate/features/recipe/domain/recipe_config.dart';
import 'package:cookmate/features/recipe/domain/tm_version.dart';
import 'package:cookmate/features/recipe/presentation/tm_version_picker_tile.dart';
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

  testWidgets('displays the TM Version title and default TM6 subtitle',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const TmVersionPickerTile()));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsTmVersionTitle), findsOneWidget);
    expect(find.text(l10n.settingsTmVersionOptionTm6), findsOneWidget);
  });

  testWidgets('displays TM5 subtitle when config has tm5', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      _wrap(
        const TmVersionPickerTile(),
        overrides: [
          recipeConfigProvider.overrideWith(
            () => _FakeRecipeConfigNotifier(
              const RecipeConfig(tmVersion: TmVersion.tm5),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsTmVersionOptionTm5), findsOneWidget);
  });

  testWidgets('tapping the tile opens the version picker dialog',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const TmVersionPickerTile()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsTmVersionDialogTitle), findsOneWidget);
  });
}

class _FakeRecipeConfigNotifier extends RecipeConfigNotifier {
  _FakeRecipeConfigNotifier(this._config);
  final RecipeConfig _config;

  @override
  Future<RecipeConfig> build() async => _config;
}
