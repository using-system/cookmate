class CookidooAuthToken {
  const CookidooAuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory CookidooAuthToken.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expires_in'] as int? ?? 0;
    return CookidooAuthToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }
}
