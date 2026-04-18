import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatTitle)),
      body: Center(child: Text(l10n.chatPlaceholder)),
    );
  }
}
