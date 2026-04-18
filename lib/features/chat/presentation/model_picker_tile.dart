import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_model_preference.dart';
import '../providers.dart';
import 'restart_dialog.dart';

class ModelPickerTile extends ConsumerWidget {
  const ModelPickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preferenceAsync = ref.watch(chatModelPreferenceProvider);
    final model =
        preferenceAsync.valueOrNull ?? ChatModelPreference.defaultModel;

    return ListTile(
      leading: const Icon(Icons.smart_toy_outlined),
      title: Text(l10n.settingsModelTitle),
      subtitle: Text(_modelLabel(l10n, model)),
      onTap: () => _openDialog(context, ref, model),
    );
  }

  Future<void> _openDialog(
    BuildContext context,
    WidgetRef ref,
    ChatModelPreference current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showDialog<ChatModelPreference>(
      context: context,
      builder: (dialogContext) {
        return RadioGroup<ChatModelPreference>(
          groupValue: current,
          onChanged: (value) {
            if (value != null) {
              Navigator.of(dialogContext).pop(value);
            }
          },
          child: SimpleDialog(
            title: Text(l10n.settingsModelDialogTitle),
            children: [
              for (final model in ChatModelPreference.values)
                _OptionTile(label: _modelLabel(l10n, model), value: model),
            ],
          ),
        );
      },
    );

    if (!context.mounted) return;
    if (selected == null) return;
    if (selected == current) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(chatModelPreferenceProvider.notifier)
          .setPreference(selected);
      if (context.mounted) {
        await showRestartDialog(context);
      }
    } catch (error, stack) {
      debugPrint('Failed to change model: $error\n$stack');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsModelChangeFailureSnackbar)),
      );
    }
  }

  String _modelLabel(AppLocalizations l10n, ChatModelPreference model) {
    return switch (model) {
      ChatModelPreference.gemma4E2B => l10n.settingsModelOptionE2B,
      ChatModelPreference.gemma4E4B => l10n.settingsModelOptionE4B,
    };
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.value});

  final String label;
  final ChatModelPreference value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ChatModelPreference>(
      title: Text(label),
      value: value,
    );
  }
}
