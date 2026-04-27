import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared_preferences_provider.dart';
import '../l10n/providers.dart';
import 'data/cookidoo_client.dart';
import 'data/cookidoo_credentials_storage.dart';
import 'data/cookidoo_repository_impl.dart';
import 'domain/cookidoo_repository.dart';
import 'domain/models/cookidoo_credentials.dart';

final cookidooCredentialsStorageProvider =
    FutureProvider<CookidooCredentialsStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return CookidooCredentialsStorage(prefs);
});

class CookidooCredentialsNotifier extends AsyncNotifier<CookidooCredentials> {
  @override
  Future<CookidooCredentials> build() async {
    final storage =
        await ref.watch(cookidooCredentialsStorageProvider.future);
    return storage.read();
  }

  Future<void> setCredentials(CookidooCredentials credentials) async {
    final storage =
        await ref.read(cookidooCredentialsStorageProvider.future);
    state = const AsyncValue<CookidooCredentials>.loading()
        .copyWithPrevious(state);
    try {
      await storage.write(credentials);
      state = AsyncValue.data(credentials);
    } catch (error, stack) {
      state = AsyncValue<CookidooCredentials>.error(error, stack)
          .copyWithPrevious(state);
      rethrow;
    }
  }
}

final cookidooCredentialsProvider =
    AsyncNotifierProvider<CookidooCredentialsNotifier, CookidooCredentials>(
  CookidooCredentialsNotifier.new,
);

final cookidooClientProvider = Provider<CookidooClient>((ref) {
  final client = CookidooClient();
  ref.onDispose(client.dispose);
  return client;
});

final cookidooRepositoryProvider = Provider<CookidooRepository>((ref) {
  final client = ref.watch(cookidooClientProvider);
  final effectiveLocale = ref.watch(effectiveLocaleProvider);
  final locale = effectiveLocale ??
      WidgetsBinding.instance.platformDispatcher.locale;
  final lang =
      '${locale.languageCode}-${locale.countryCode ?? locale.languageCode.toUpperCase()}';

  return CookidooRepositoryImpl(
    client: client,
    locale: lang,
    // Read credentials lazily and asynchronously so the provider resolves
    // even when accessed before the credentials Future completes.
    credentialsReader: () async {
      final storage =
          await ref.read(cookidooCredentialsStorageProvider.future);
      return storage.read();
    },
  );
});
