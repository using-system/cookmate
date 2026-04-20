import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cookidoo_client.dart';
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
              final testCreds = CookidooCredentials(
                email: emailController.text.trim(),
                password: passwordController.text,
              );
              final client = ref.read(cookidooClientProvider);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final countryCode = CookidooClient.countryCodeFromLocale(
                '${Localizations.localeOf(context).languageCode}-${Localizations.localeOf(context).countryCode ?? Localizations.localeOf(context).languageCode.toUpperCase()}',
              );
              debugPrint('Cookidoo test: countryCode=$countryCode, email=${testCreds.email}');
              try {
                await client.login(testCreds, countryCode: countryCode);
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(l10n.settingsCookidooTestSuccess)),
                );
              } catch (e) {
                debugPrint('Cookidoo test login failed: $e');
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(l10n.settingsCookidooTestFailure)),
                );
              }
            },
            child: Text(l10n.settingsCookidooTest),
          ),
          TextButton(
            onPressed: () async {
              final credentials = CookidooCredentials(
                email: emailController.text.trim(),
                password: passwordController.text,
              );
              Navigator.of(ctx).pop();
              // Write directly to storage to avoid triggering provider
              // rebuilds while the dialog route is still animating out.
              try {
                final storage = await ref
                    .read(cookidooCredentialsStorageProvider.future);
                await storage.write(credentials);
                // Refresh the provider after the dialog is fully gone.
                ref.invalidate(cookidooCredentialsProvider);
              } catch (_) {
                if (context.mounted) {
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
