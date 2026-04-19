import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/expert_config.dart';
import '../providers.dart';

class ExpertPickerTile extends ConsumerWidget {
  const ExpertPickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final configAsync = ref.watch(chatExpertConfigProvider);
    final config = configAsync.valueOrNull ?? const ExpertConfig();

    return ListTile(
      leading: const Icon(Icons.tune_outlined),
      title: Text(l10n.settingsExpertTitle),
      subtitle: Text(
        l10n.settingsExpertSubtitle(
          config.maxTokens,
          config.temperature.toStringAsFixed(2),
        ),
      ),
      onTap: () => _openDialog(context, ref, config),
    );
  }

  Future<void> _openDialog(
    BuildContext context,
    WidgetRef ref,
    ExpertConfig current,
  ) async {
    final result = await showDialog<ExpertConfig>(
      context: context,
      builder: (dialogContext) => _ExpertDialog(initial: current),
    );

    if (!context.mounted) return;
    if (result == null || result == current) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(chatExpertConfigProvider.notifier)
          .setConfig(result);
    } catch (error, stack) {
      debugPrint('Failed to save expert config: $error\n$stack');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsExpertChangeFailureSnackbar)),
      );
    }
  }
}

class _ExpertDialog extends StatefulWidget {
  const _ExpertDialog({required this.initial});

  final ExpertConfig initial;

  @override
  State<_ExpertDialog> createState() => _ExpertDialogState();
}

class _ExpertDialogState extends State<_ExpertDialog> {
  late int _maxTokens;
  late int _topK;
  late double _topP;
  late double _temperature;

  @override
  void initState() {
    super.initState();
    _maxTokens = widget.initial.maxTokens;
    _topK = widget.initial.topK;
    _topP = widget.initial.topP;
    _temperature = widget.initial.temperature;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.settingsExpertDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SliderRow(
              label: l10n.settingsExpertMaxTokens,
              value: _maxTokens.toDouble(),
              min: 4000,
              max: 30000,
              divisions: 26,
              displayValue: _maxTokens.toString(),
              onChanged: (v) => setState(() => _maxTokens = v.round()),
            ),
            _SliderRow(
              label: l10n.settingsExpertTopK,
              value: _topK.toDouble(),
              min: 5,
              max: 94,
              divisions: 89,
              displayValue: _topK.toString(),
              onChanged: (v) => setState(() => _topK = v.round()),
            ),
            _SliderRow(
              label: l10n.settingsExpertTopP,
              value: _topP,
              min: 0,
              max: 1,
              divisions: 100,
              displayValue: _topP.toStringAsFixed(2),
              onChanged: (v) =>
                  setState(() => _topP = double.parse(v.toStringAsFixed(2))),
            ),
            _SliderRow(
              label: l10n.settingsExpertTemperature,
              value: _temperature,
              min: 0,
              max: 2,
              divisions: 200,
              displayValue: _temperature.toStringAsFixed(2),
              onChanged: (v) => setState(
                  () => _temperature = double.parse(v.toStringAsFixed(2))),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            ExpertConfig(
              maxTokens: _maxTokens,
              topK: _topK,
              topP: _topP,
              temperature: _temperature,
            ),
          ),
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(displayValue, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
