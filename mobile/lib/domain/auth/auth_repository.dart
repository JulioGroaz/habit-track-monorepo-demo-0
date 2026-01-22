// Contract for auth data operations so presentation stays decoupled from IO.
// This exists to define the app's authentication capabilities in one place.
// It fits in the app by enabling clean architecture boundaries for login/logout.
import 'auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> login({
    required String email,
    required String password,
  });

  Future<AuthUser> register({
    required String email,
    required String password,
  });

  Future<AuthUser> fetchProfile();

  Future<void> logout();

  Future<String?> readToken();
}
