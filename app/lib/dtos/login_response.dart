class LoginResponse {
  final String token;
  final String name;

  LoginResponse({
    required this.token,
    required this.name,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      name: json['name'] ?? '',
    );
  }
}