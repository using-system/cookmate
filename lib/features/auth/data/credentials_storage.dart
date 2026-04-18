import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/cookidoo_credentials.dart';

class CredentialsStorage {
  CredentialsStorage(this._storage);

  static const _credentialsKey = 'cookidoo_credentials';

  final FlutterSecureStorage _storage;

  Future<CookidooCredentials?> read() async {
    final raw = await _storage.read(key: _credentialsKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final email = map['email'] as String?;
    final password = map['password'] as String?;
    if (email == null || password == null) return null;
    return CookidooCredentials(email: email, password: password);
  }

  Future<void> write(CookidooCredentials credentials) async {
    final payload = jsonEncode({
      'email': credentials.email,
      'password': credentials.password,
    });
    await _storage.write(key: _credentialsKey, value: payload);
  }

  Future<void> clear() async {
    await _storage.delete(key: _credentialsKey);
  }
}
