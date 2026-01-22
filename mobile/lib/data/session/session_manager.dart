// Coordinates logout and forced session resets across auth and sync layers.
// This exists to centralize side effects when a session becomes invalid.
// It fits in the app by handling 401 logouts and user-initiated sign out.
import 'dart:async';

import '../../core/storage/secure_storage.dart';
import '../db/app_database.dart';

class SessionManager {
  SessionManager(this._tokenStorage, this._database);

  final TokenStorage _tokenStorage;
  final AppDatabase _database;
  final StreamController<void> _logoutController =
      StreamController<void>.broadcast();

  Stream<void> get logoutStream => _logoutController.stream;

  Future<void> handleUnauthorized() async {
    await logout();
  }

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
    await _database.clearAll();
    _logoutController.add(null);
  }

  Future<void> dispose() async {
    await _logoutController.close();
  }
}
