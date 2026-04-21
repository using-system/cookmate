import 'package:cookmate/features/cookidoo/domain/models/cookidoo_auth_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CookidooAuthToken.fromJson', () {
    test('parses access_token, refresh_token and expires_in', () {
      final json = {
        'access_token': 'my_access',
        'refresh_token': 'my_refresh',
        'expires_in': 3600,
      };

      final token = CookidooAuthToken.fromJson(json);

      expect(token.accessToken, 'my_access');
      expect(token.refreshToken, 'my_refresh');
      // expiresAt should be approximately now + 3600 seconds.
      final expectedExpiry = DateTime.now().add(const Duration(seconds: 3600));
      expect(
        token.expiresAt.difference(expectedExpiry).abs().inSeconds,
        lessThan(5),
      );
    });

    test('defaults expires_in to 0 when missing', () {
      final json = {
        'access_token': 'tok',
        'refresh_token': 'ref',
      };

      final before = DateTime.now();
      final token = CookidooAuthToken.fromJson(json);
      final after = DateTime.now();

      expect(
        token.expiresAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        token.expiresAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });

  group('CookidooAuthToken.isExpired', () {
    test('returns false for a token that expires in the future', () {
      final token = CookidooAuthToken(
        accessToken: 'tok',
        refreshToken: 'ref',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(token.isExpired, isFalse);
    });

    test('returns true for a token that expired in the past', () {
      final token = CookidooAuthToken(
        accessToken: 'tok',
        refreshToken: 'ref',
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );

      expect(token.isExpired, isTrue);
    });
  });
}
