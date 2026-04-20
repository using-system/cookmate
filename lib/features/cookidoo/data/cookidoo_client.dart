import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../domain/models/cookidoo_auth_token.dart';
import '../domain/models/cookidoo_credentials.dart';
import '../domain/models/cookidoo_exceptions.dart';
import '../domain/models/cookidoo_recipe_detail.dart';
import '../domain/models/cookidoo_recipe_overview.dart';

class CookidooClient {
  CookidooClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _basicAuth =
      'Basic a3VwZmVyd2Vyay1jbGllbnQtbndvdDpMczUwT04xd295U3FzMWRDZEpnZQ==';
  static const _clientId = 'kupferwerk-client-nwot';

  CookidooAuthToken? _token;

  String _baseUrl(String countryCode) =>
      'https://$countryCode.tmmobile.vorwerk-digital.com';

  static String countryCodeFromLocale(String locale) {
    final parts = locale.split('-');
    if (parts.length < 2) return parts.first.toLowerCase();
    final country = parts.last.toLowerCase();
    return switch (country) {
      'gb' => 'gb',
      _ => country,
    };
  }

  Future<CookidooAuthToken> login(
    CookidooCredentials credentials, {
    required String countryCode,
  }) async {
    final url =
        Uri.parse('${_baseUrl(countryCode)}/ciam/auth/token');
    final response = await _http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': _basicAuth,
      },
      body:
          'grant_type=password&username=${Uri.encodeComponent(credentials.email)}'
          '&password=${Uri.encodeComponent(credentials.password)}',
    );

    if (response.statusCode != 200) {
      debugPrint('Cookidoo login: POST $url → ${response.statusCode}');
      debugPrint('Cookidoo login response: ${response.body}');
      throw CookidooAuthException(
        'Login failed (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    _token = CookidooAuthToken.fromJson(json);
    return _token!;
  }

  Future<void> _refreshToken({required String countryCode}) async {
    if (_token == null) {
      throw const CookidooAuthException('No token to refresh');
    }

    final url =
        Uri.parse('${_baseUrl(countryCode)}/ciam/auth/token');
    final response = await _http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': _basicAuth,
      },
      body:
          'grant_type=refresh_token&refresh_token=${_token!.refreshToken}'
          '&client_id=$_clientId',
    );

    if (response.statusCode != 200) {
      _token = null;
      throw CookidooAuthException(
        'Token refresh failed (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    _token = CookidooAuthToken.fromJson(json);
  }

  Future<void> _ensureAuth(
    CookidooCredentials credentials, {
    required String countryCode,
  }) async {
    if (_token == null) {
      await login(credentials, countryCode: countryCode);
    } else if (_token!.isExpired) {
      try {
        await _refreshToken(countryCode: countryCode);
      } catch (_) {
        await login(credentials, countryCode: countryCode);
      }
    }
  }

  Future<List<CookidooRecipeOverview>> searchRecipes(
    String query, {
    required String lang,
    required String countryCode,
    int limit = 5,
  }) async {
    final url = Uri.parse(
      '${_baseUrl(countryCode)}/search/api/$lang/search'
      '?query=${Uri.encodeComponent(query)}&context=recipes&limit=$limit',
    );

    final response = await _http.get(url, headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw CookidooNetworkException(
        'Search failed (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>? ?? [];
    return data
        .map((e) =>
            CookidooRecipeOverview.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CookidooRecipeDetail> getRecipeDetail(
    String recipeId, {
    required String lang,
    required String countryCode,
    required CookidooCredentials credentials,
  }) async {
    await _ensureAuth(credentials, countryCode: countryCode);

    final url = Uri.parse(
      '${_baseUrl(countryCode)}/recipes/recipe/$lang/$recipeId',
    );

    final response = await _http.get(url, headers: {
      'Accept': 'application/vnd.vorwerk.recipe.embedded.hal+json',
      'Authorization': 'Bearer ${_token!.accessToken}',
    });

    if (response.statusCode == 404) {
      throw CookidooNotFoundException(recipeId);
    }
    if (response.statusCode == 401) {
      _token = null;
      throw const CookidooAuthException('Session expired');
    }
    if (response.statusCode != 200) {
      throw CookidooNetworkException(
        'Recipe detail failed (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return CookidooRecipeDetail.fromJson(json);
  }

  void dispose() {
    _http.close();
  }
}
