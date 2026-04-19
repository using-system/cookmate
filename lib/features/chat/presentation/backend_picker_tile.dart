import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_backend_preference.dart';
import '../providers.dart';

class BackendPickerTile extends ConsumerWidget {
  const BackendPickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preferenceAsync = ref.watch(chatBackendPreferenceProvider);
    final backend =
        preferenceAsync.valueOrNull ?? ChatBackendPreference.defaultBackend;

    return ListTile(
      leading: const Icon(Icons.memory_outlined),
      title: Text(l10n.settingsBackendTitle),
      subtitle: Text(_backendLabel(l10n, backend)),
      onTap: () => _openDialog(context, ref, backend),
    );
  }

  Future<void> _openDialog(
    BuildContext context,
    WidgetRef ref,
    ChatBackendPreference current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showDialog<ChatBackendPreference>(
      context: context,
      builder: (dialogContext) {
        return RadioGroup<ChatBackendPreference>(
          groupValue: current,
          onChanged: (value) {
            if (value != null) {
              Navigator.of(dialogContext).pop(value);
            }
          },
          child: SimpleDialog(
            title: Text(l10n.settingsBackendDialogTitle),
            children: [
              for (final backend in ChatBackendPreference.values)
                _OptionTile(
                    label: _backendLabel(l10n, backend), value: backend),
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
      final service = await ref.read(chatModelServiceProvider.future);
      await service.switchBackend(selected);
      ref.invalidate(chatBackendPreferenceProvider);
    } catch (error, stack) {
      debugPrint('Failed to change backend: $error\n$stack');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsBackendChangeFailureSnackbar)),
      );
    }
  }

  String _backendLabel(AppLocalizations l10n, ChatBackendPreference backend) {
    return switch (backend) {
      ChatBackendPreference.gpu => l10n.settingsBackendOptionGpu,
      ChatBackendPreference.cpu => l10n.settingsBackendOptionCpu,
    };
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.value});

  final String label;
  final ChatBackendPreference value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ChatBackendPreference>(
      title: Text(label),
      value: value,
    );
  }
}
