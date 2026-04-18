import '../domain/cookidoo_credentials.dart';
import 'credentials_storage.dart';

class AuthRepository {
  AuthRepository(this._storage);

  final CredentialsStorage _storage;

  Future<CookidooCredentials?> loadCredentials() => _storage.read();

  Future<void> saveCredentials(CookidooCredentials credentials) =>
      _storage.write(credentials);

  Future<void> clearCredentials() => _storage.clear();
}
