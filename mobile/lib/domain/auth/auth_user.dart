// Domain model for the authenticated user returned by the API.
// This exists to keep auth data separate from transport-layer DTOs.
// It fits in the app by representing the signed-in session identity.
class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;
  final String displayName;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'User',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
      };
}
