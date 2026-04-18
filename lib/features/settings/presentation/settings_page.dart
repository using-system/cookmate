import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isBusy = auth.isLoading;

    ref.listen(authStateProvider, (previous, next) {
      if (next.hasError) {
        debugPrint('Logout failed: ${next.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible de se déconnecter. Réessayez dans un instant.',
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: Center(
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
              : const Text('Se déconnecter'),
        ),
      ),
    );
  }
}
