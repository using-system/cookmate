import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/shared_preferences_provider.dart';
import '../data/cookidoo_client.dart';
import '../domain/models/cookidoo_credentials.dart';

const _keyEmail = 'cookidoo_email';
const _keyPassword = 'cookidoo_password';

class CookidooCredentialsTile extends ConsumerWidget {
  const CookidooCredentialsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefsAsync = ref.watch(sharedPreferencesProvider);
    final email = prefsAsync.valueOrNull?.getString(_keyEmail) ?? '';
    final subtitle =
        email.isNotEmpty ? email : l10n.settingsCookidooNotConfigured;

    return ListTile(
      leading: const Icon(Icons.cloud_outlined),
      title: const Text('Cookidoo'),
      subtitle: Text(subtitle),
      onTap: () async {
        final prefs = prefsAsync.valueOrNull;
        if (prefs == null) return;

        final currentPassword = prefs.getString(_keyPassword) ?? '';
        final emailController = TextEditingController(text: email);
        final passwordController =
            TextEditingController(text: currentPassword);

        final result = await showDialog<CookidooCredentials>(
          context: context,
          useRootNavigator: true,
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
                    ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.settingsCookidooPasswordTitle,
                    hintText: l10n.settingsCookidooPasswordHint,
                  ),
                  obscureText: true,
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
                  final locale = Localizations.localeOf(context);
                  final countryCode =
                      CookidooClient.countryCodeFromLocale(
                    '${locale.languageCode}-${locale.countryCode ?? locale.languageCode.toUpperCase()}',
                  );
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await CookidooClient().login(
                      testCreds,
                      countryCode: countryCode,
                    );
                    messenger.showSnackBar(SnackBar(
                        content:
                            Text(l10n.settingsCookidooTestSuccess)));
                  } catch (e) {
                    debugPrint('Cookidoo test login failed: $e');
                    messenger.showSnackBar(SnackBar(
                        content:
                            Text(l10n.settingsCookidooTestFailure)));
                  }
                },
                child: Text(l10n.settingsCookidooTest),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(ctx).pop(CookidooCredentials(
                  email: emailController.text.trim(),
                  password: passwordController.text,
                )),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
        emailController.dispose();
        passwordController.dispose();

        if (result != null) {
          await prefs.setString(_keyEmail, result.email);
          await prefs.setString(_keyPassword, result.password);
        }
      },
    );
  }
}
