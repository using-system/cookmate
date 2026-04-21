import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/cookidoo_credentials.dart';

class CookidooCredentialsStorage {
  CookidooCredentialsStorage(this._prefs);

  static const _keyEmail = 'cookidoo_email';
  static const _keyPassword = 'cookidoo_password';

  final SharedPreferences _prefs;

  CookidooCredentials read() {
    return CookidooCredentials(
      email: _prefs.getString(_keyEmail) ?? '',
      password: _prefs.getString(_keyPassword) ?? '',
    );
  }

  Future<void> write(CookidooCredentials credentials) async {
    await _prefs.setString(_keyEmail, credentials.email);
    await _prefs.setString(_keyPassword, credentials.password);
  }
}
