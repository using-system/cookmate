import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cookidoo_client.dart';
import '../domain/models/cookidoo_credentials.dart';
import '../providers.dart';

class CookidooCredentialsTile extends ConsumerStatefulWidget {
  const CookidooCredentialsTile({super.key});

  @override
  ConsumerState<CookidooCredentialsTile> createState() =>
      _CookidooCredentialsTileState();
}

class _CookidooCredentialsTileState
    extends ConsumerState<CookidooCredentialsTile> {
  CookidooCredentials? _credentials;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final storage =
        await ref.read(cookidooCredentialsStorageProvider.future);
    if (!mounted) return;
    setState(() {
      _credentials = storage.read();
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subtitle = (_loaded && _credentials != null && !_credentials!.isEmpty)
        ? _credentials!.email
        : l10n.settingsCookidooNotConfigured;

    return ListTile(
      leading: const Icon(Icons.cloud_outlined),
      title: const Text('Cookidoo'),
      subtitle: Text(subtitle),
      onTap: () => _showCredentialsDialog(context),
    );
  }

  Future<void> _showCredentialsDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final emailController =
        TextEditingController(text: _credentials?.email ?? '');
    final passwordController =
        TextEditingController(text: _credentials?.password ?? '');

    final saved = await showDialog<CookidooCredentials>(
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
              debugPrint(
                  'Cookidoo test: countryCode=$countryCode, email=${testCreds.email}');
              try {
                await client.login(testCreds, countryCode: countryCode);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                      content: Text(l10n.settingsCookidooTestSuccess)),
                );
              } catch (e) {
                debugPrint('Cookidoo test login failed: $e');
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                      content: Text(l10n.settingsCookidooTestFailure)),
                );
              }
            },
            child: Text(l10n.settingsCookidooTest),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(CookidooCredentials(
                email: emailController.text.trim(),
                password: passwordController.text,
              ));
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );

    emailController.dispose();
    passwordController.dispose();

    // Save after the dialog is fully closed.
    if (saved == null) return;
    try {
      final storage =
          await ref.read(cookidooCredentialsStorageProvider.future);
      await storage.write(saved);
      if (mounted) {
        setState(() => _credentials = saved);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).settingsCookidooChangeFailureSnackbar),
          ),
        );
      }
    }
  }
}
