import 'package:cookmate/features/cookidoo/domain/models/cookidoo_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CookidooAuthException', () {
    test('toString includes class name and message', () {
      const exception = CookidooAuthException('Login failed (401)');

      expect(
        exception.toString(),
        'CookidooAuthException: Login failed (401)',
      );
    });
  });

  group('CookidooNotFoundException', () {
    test('toString includes class name and recipe id', () {
      const exception = CookidooNotFoundException('r145192');

      expect(exception.toString(), 'CookidooNotFoundException: r145192');
    });
  });

  group('CookidooNetworkException', () {
    test('toString includes class name and message', () {
      const exception = CookidooNetworkException('Search failed (503)');

      expect(
        exception.toString(),
        'CookidooNetworkException: Search failed (503)',
      );
    });
  });
}
