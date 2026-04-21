import 'package:cookmate/features/cookidoo/data/cookidoo_credentials_storage.dart';
import 'package:cookmate/features/cookidoo/domain/models/cookidoo_credentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CookidooCredentialsStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    storage = CookidooCredentialsStorage(prefs);
  });

  test('read returns empty credentials when prefs are empty', () {
    final credentials = storage.read();
    expect(credentials.email, '');
    expect(credentials.password, '');
  });

  test('isEmpty is true when prefs are empty', () {
    expect(storage.read().isEmpty, isTrue);
  });

  test('write then read roundtrip preserves email and password', () async {
    const credentials = CookidooCredentials(
      email: 'chef@example.com',
      password: 's3cr3t!',
    );
    await storage.write(credentials);
    final result = storage.read();
    expect(result.email, credentials.email);
    expect(result.password, credentials.password);
  });

  test('write overwrites previous credentials', () async {
    const first = CookidooCredentials(email: 'old@example.com', password: 'oldpass');
    const second = CookidooCredentials(email: 'new@example.com', password: 'newpass');
    await storage.write(first);
    await storage.write(second);
    final result = storage.read();
    expect(result.email, 'new@example.com');
    expect(result.password, 'newpass');
  });

  test('isEmpty is false after writing valid credentials', () async {
    const credentials = CookidooCredentials(
      email: 'chef@example.com',
      password: 's3cr3t!',
    );
    await storage.write(credentials);
    expect(storage.read().isEmpty, isFalse);
  });
}
