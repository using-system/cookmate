import 'package:cookmate/features/cookidoo/domain/models/cookidoo_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CookidooCredentials.isEmpty', () {
    test('returns false when both email and password are non-empty', () {
      const creds = CookidooCredentials(
        email: 'user@example.com',
        password: 'secret',
      );

      expect(creds.isEmpty, isFalse);
    });

    test('returns true when email is empty', () {
      const creds = CookidooCredentials(email: '', password: 'secret');

      expect(creds.isEmpty, isTrue);
    });

    test('returns true when password is empty', () {
      const creds = CookidooCredentials(
        email: 'user@example.com',
        password: '',
      );

      expect(creds.isEmpty, isTrue);
    });

    test('returns true when both email and password are empty', () {
      const creds = CookidooCredentials(email: '', password: '');

      expect(creds.isEmpty, isTrue);
    });
  });
}
