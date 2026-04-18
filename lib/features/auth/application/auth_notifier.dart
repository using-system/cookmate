import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/cookidoo_credentials.dart';
import '../providers.dart';

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repository = ref.read(authRepositoryProvider);
    final credentials = await repository.loadCredentials();
    return credentials != null;
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.saveCredentials(
        CookidooCredentials(email: email, password: password),
      );
      return true;
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.clearCredentials();
      return false;
    });
  }
}
