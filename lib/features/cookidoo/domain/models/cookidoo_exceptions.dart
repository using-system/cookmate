class CookidooAuthException implements Exception {
  const CookidooAuthException(this.message);
  final String message;

  @override
  String toString() => 'CookidooAuthException: $message';
}

class CookidooNotFoundException implements Exception {
  const CookidooNotFoundException(this.recipeId);
  final String recipeId;

  @override
  String toString() => 'CookidooNotFoundException: $recipeId';
}

class CookidooNetworkException implements Exception {
  const CookidooNetworkException(this.message);
  final String message;

  @override
  String toString() => 'CookidooNetworkException: $message';
}
