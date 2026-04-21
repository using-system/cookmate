import 'dart:convert';

import 'package:cookmate/features/cookidoo/data/cookidoo_client.dart';
import 'package:cookmate/features/cookidoo/data/cookidoo_repository_impl.dart';
import 'package:cookmate/features/cookidoo/domain/models/cookidoo_credentials.dart';
import 'package:cookmate/features/cookidoo/domain/models/cookidoo_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('CookidooRepositoryImpl.searchRecipes', () {
    test('delegates to client with locale-derived lang and countryCode', () async {
      final mockClient = MockClient((request) async {
        // Verify the URL contains the expected lang and country code segments.
        // The repository uses the full locale string as lang ('fr-FR')
        // and the country portion lowercased as the subdomain ('fr').
        expect(request.url.host, contains('fr.tmmobile'));
        expect(request.url.path, contains('/fr-FR/search'));
        expect(request.url.queryParameters['query'], 'pasta');
        expect(request.url.queryParameters['limit'], '3');

        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'r1',
                'title': 'Pasta',
                'rating': 4.0,
                'numberOfRatings': 10,
                'totalTime': 1800,
                'image': '',
              },
            ],
          }),
          200,
        );
      });

      final repo = CookidooRepositoryImpl(
        client: CookidooClient(httpClient: mockClient),
        locale: 'fr-FR',
        credentialsReader: () => null,
      );

      final results = await repo.searchRecipes('pasta', limit: 3);

      expect(results, hasLength(1));
      expect(results[0].title, 'Pasta');
    });
  });

  group('CookidooRepositoryImpl.getRecipeDetail', () {
    test('throws CookidooAuthException when credentials are null', () {
      final repo = CookidooRepositoryImpl(
        client: CookidooClient(),
        locale: 'en-US',
        credentialsReader: () => null,
      );

      expect(
        () => repo.getRecipeDetail('r123'),
        throwsA(isA<CookidooAuthException>()),
      );
    });

    test('throws CookidooAuthException when credentials are empty', () {
      final repo = CookidooRepositoryImpl(
        client: CookidooClient(),
        locale: 'en-US',
        credentialsReader: () =>
            const CookidooCredentials(email: '', password: ''),
      );

      expect(
        () => repo.getRecipeDetail('r123'),
        throwsA(isA<CookidooAuthException>()),
      );
    });

    test('throws CookidooAuthException when email is empty', () {
      final repo = CookidooRepositoryImpl(
        client: CookidooClient(),
        locale: 'en-US',
        credentialsReader: () =>
            const CookidooCredentials(email: '', password: 'secret'),
      );

      expect(
        () => repo.getRecipeDetail('r123'),
        throwsA(isA<CookidooAuthException>()),
      );
    });
  });

  group('CookidooRepositoryImpl.isAuthenticated', () {
    test('returns false when credentials are null', () async {
      final repo = CookidooRepositoryImpl(
        client: CookidooClient(),
        locale: 'en-US',
        credentialsReader: () => null,
      );

      expect(await repo.isAuthenticated(), isFalse);
    });

    test('returns false when credentials are empty', () async {
      final repo = CookidooRepositoryImpl(
        client: CookidooClient(),
        locale: 'en-US',
        credentialsReader: () =>
            const CookidooCredentials(email: '', password: ''),
      );

      expect(await repo.isAuthenticated(), isFalse);
    });

    test('returns false when login fails with CookidooAuthException', () async {
      final mockClient = MockClient((_) async => http.Response('Unauthorized', 401));

      final repo = CookidooRepositoryImpl(
        client: CookidooClient(httpClient: mockClient),
        locale: 'en-US',
        credentialsReader: () =>
            const CookidooCredentials(email: 'a@b.com', password: 'pw'),
      );

      expect(await repo.isAuthenticated(), isFalse);
    });

    test('returns true when login succeeds', () async {
      final mockClient = MockClient((_) async => http.Response(
            jsonEncode({
              'access_token': 'tok',
              'refresh_token': 'ref',
              'expires_in': 3600,
            }),
            200,
          ));

      final repo = CookidooRepositoryImpl(
        client: CookidooClient(httpClient: mockClient),
        locale: 'en-US',
        credentialsReader: () =>
            const CookidooCredentials(email: 'a@b.com', password: 'pw'),
      );

      expect(await repo.isAuthenticated(), isTrue);
    });
  });
}
