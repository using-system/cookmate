class CookidooCredentials {
  const CookidooCredentials({required this.email, required this.password});

  final String email;
  final String password;

  bool get isEmpty => email.isEmpty || password.isEmpty;
}
