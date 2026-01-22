// Secure token storage wrapper so auth secrets stay off disk and out of logs.
// This exists to isolate secure storage usage behind a simple interface.
// It fits in the app by backing auth persistence and ApiClient token injection.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'auth_token';

  Future<void> writeToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() {
    return _storage.delete(key: _tokenKey);
  }
}
