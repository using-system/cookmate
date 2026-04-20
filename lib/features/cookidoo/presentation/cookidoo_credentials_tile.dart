import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/cookidoo_credentials.dart';
import '../providers.dart';

class CookidooCredentialsTile extends ConsumerWidget {
  const CookidooCredentialsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final credentials = ref.watch(cookidooCredentialsProvider).valueOrNull;
    final subtitle = (credentials != null && !credentials.isEmpty)
        ? credentials.email
        : l10n.settingsCookidooNotConfigured;

    return ListTile(
      leading: const Icon(Icons.cloud_outlined),
      title: const Text('Cookidoo'),
      subtitle: Text(subtitle),
      onTap: () => _showCredentialsDialog(context, ref, credentials),
    );
  }

  Future<void> _showCredentialsDialog(
    BuildContext context,
    WidgetRef ref,
    CookidooCredentials? current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final emailController =
        TextEditingController(text: current?.email ?? '');
    final passwordController =
        TextEditingController(text: current?.password ?? '');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cookidoo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: l10n.settingsCookidooEmailTitle,
                hintText: l10n.settingsCookidooEmailHint,
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: l10n.settingsCookidooPasswordTitle,
                hintText: l10n.settingsCookidooPasswordHint,
              ),
              obscureText: true,
              autofillHints: const [AutofillHints.password],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final repo = ref.read(cookidooRepositoryProvider);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final success = await repo.isAuthenticated();
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? l10n.settingsCookidooTestSuccess
                        : l10n.settingsCookidooTestFailure,
                  ),
                ),
              );
            },
            child: Text(l10n.settingsCookidooTest),
          ),
          TextButton(
            onPressed: () async {
              final credentials = CookidooCredentials(
                email: emailController.text.trim(),
                password: passwordController.text,
              );
              try {
                await ref
                    .read(cookidooCredentialsProvider.notifier)
                    .setCredentials(credentials);
                if (ctx.mounted) Navigator.of(ctx).pop();
              } catch (_) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          l10n.settingsCookidooChangeFailureSnackbar),
                    ),
                  );
                }
              }
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );

    emailController.dispose();
    passwordController.dispose();
  }
}
