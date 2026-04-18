import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../chat/presentation/backend_picker_tile.dart';
import '../../chat/presentation/model_picker_tile.dart';
import '../../l10n/presentation/language_picker_tile.dart';
import '../../theme/presentation/theme_picker_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: const [
          ThemePickerTile(),
          Divider(height: 1),
          LanguagePickerTile(),
          Divider(height: 1),
          ModelPickerTile(),
          Divider(height: 1),
          BackendPickerTile(),
          Divider(height: 1),
        ],
      ),
    );
  }
}
