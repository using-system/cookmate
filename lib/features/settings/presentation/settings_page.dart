import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../chat/presentation/backend_picker_tile.dart';
import '../../chat/presentation/expert_picker_tile.dart';
import '../../chat/presentation/model_picker_tile.dart';
import '../../chat/presentation/reasoning_tile.dart';
import '../../l10n/presentation/language_picker_tile.dart';
import '../../recipe/presentation/dietary_restrictions_tile.dart';
import '../../recipe/presentation/level_picker_tile.dart';
import '../../recipe/presentation/portions_picker_tile.dart';
import '../../recipe/presentation/tm_version_picker_tile.dart';
import '../../recipe/presentation/unit_system_picker_tile.dart';
import '../../theme/presentation/theme_picker_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sectionStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(l10n.settingsSectionRecipe, style: sectionStyle),
          ),
          const TmVersionPickerTile(),
          const Divider(height: 1),
          const UnitSystemPickerTile(),
          const Divider(height: 1),
          const PortionsPickerTile(),
          const Divider(height: 1),
          const LevelPickerTile(),
          const Divider(height: 1),
          const DietaryRestrictionsTile(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(l10n.settingsSectionAi, style: sectionStyle),
          ),
          const ModelPickerTile(),
          const Divider(height: 1),
          const BackendPickerTile(),
          const Divider(height: 1),
          const ReasoningTile(),
          const Divider(height: 1),
          const ExpertPickerTile(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(l10n.settingsSectionGeneral, style: sectionStyle),
          ),
          const LanguagePickerTile(),
          const Divider(height: 1),
          const ThemePickerTile(),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
