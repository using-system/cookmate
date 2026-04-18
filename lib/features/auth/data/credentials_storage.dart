import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/cookidoo_credentials.dart';

class CredentialsStorage {
  CredentialsStorage(this._storage);

  static const _emailKey = 'cookidoo_email';
  static const _passwordKey = 'cookidoo_password';

  final FlutterSecureStorage _storage;

  Future<CookidooCredentials?> read() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null || password == null) return null;
    return CookidooCredentials(email: email, password: password);
  }

  Future<void> write(CookidooCredentials credentials) async {
    await _storage.write(key: _emailKey, value: credentials.email);
    await _storage.write(key: _passwordKey, value: credentials.password);
  }

  Future<void> clear() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }
}
