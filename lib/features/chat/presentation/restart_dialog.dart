import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showRestartDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.settingsRestartRequiredTitle),
      content: Text(l10n.settingsRestartRequiredMessage),
      actions: [
        FilledButton(
          onPressed: () => SystemNavigator.pop(),
          child: Text(l10n.settingsRestartRequiredButton),
        ),
      ],
    ),
  );
}
