import 'package:cookmate/features/auth/data/credentials_storage.dart';
import 'package:cookmate/features/auth/domain/cookidoo_credentials.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CredentialsStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    storage = CredentialsStorage(const FlutterSecureStorage());
  });

  test('read returns null when nothing is stored', () async {
    expect(await storage.read(), isNull);
  });

  test('write persists credentials that read returns', () async {
    const credentials = CookidooCredentials(
      email: 'chef@cookmate.app',
      password: 'thermomix-rules',
    );

    await storage.write(credentials);
    final loaded = await storage.read();

    expect(loaded, isNotNull);
    expect(loaded!.email, credentials.email);
    expect(loaded.password, credentials.password);
  });

  test('write overwrites previously stored credentials', () async {
    await storage.write(
      const CookidooCredentials(email: 'old@a.com', password: 'old'),
    );
    await storage.write(
      const CookidooCredentials(email: 'new@a.com', password: 'new'),
    );

    final loaded = await storage.read();

    expect(loaded!.email, 'new@a.com');
    expect(loaded.password, 'new');
  });

  test('clear removes stored credentials', () async {
    await storage.write(
      const CookidooCredentials(email: 'a@b.c', password: 'secret'),
    );

    await storage.clear();

    expect(await storage.read(), isNull);
  });
}
