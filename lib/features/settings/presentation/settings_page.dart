import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers.dart';
import '../../l10n/presentation/language_picker_tile.dart';
import '../../theme/presentation/theme_picker_tile.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authStateProvider);
    final isBusy = auth.isLoading;

    ref.listen(authStateProvider, (previous, next) {
      if (next.hasError) {
        debugPrint('Logout failed: ${next.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsLogoutFailureSnackbar)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          const ThemePickerTile(),
          const Divider(height: 1),
          const LanguagePickerTile(),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Center(
            child: FilledButton.tonal(
              onPressed: isBusy
                  ? null
                  : () => ref.read(authStateProvider.notifier).logout(),
              child: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.settingsLogoutButton),
            ),
          ),
        ],
      ),
    );
  }
}
