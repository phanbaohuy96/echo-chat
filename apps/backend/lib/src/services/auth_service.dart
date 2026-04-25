import 'package:uuid/uuid.dart';

import '../models/auth_result.dart';
import '../models/user.dart';
import '../store/demo_store.dart';

class AuthException implements Exception {
  const AuthException(this.statusCode, this.message);

  final int statusCode;
  final String message;
}

class AuthService {
  AuthService(this._store);

  static const _maxTokens = 200;

  final DemoStore _store;
  final _uuid = const Uuid();

  AuthResult signup({
    required String name,
    required String username,
    required String password,
  }) {
    final normalizedUsername = username.trim().toLowerCase();
    if (name.trim().isEmpty || normalizedUsername.isEmpty || password.isEmpty) {
      throw const AuthException(
        400,
        'Name, username, and password are required.',
      );
    }

    if (_store.userIdsByUsername.containsKey(normalizedUsername)) {
      throw const AuthException(409, 'Username already exists.');
    }

    final user = BackendUser(
      id: 'user_${_uuid.v4()}',
      name: name.trim(),
      username: normalizedUsername,
      password: password,
    );
    _store.usersById[user.id] = user;
    _store.userIdsByUsername[normalizedUsername] = user.id;

    return _issueToken(user);
  }

  AuthResult signin({required String username, required String password}) {
    final normalizedUsername = username.trim().toLowerCase();
    if (normalizedUsername.isEmpty || password.isEmpty) {
      throw const AuthException(400, 'Username and password are required.');
    }

    final userId = _store.userIdsByUsername[normalizedUsername];
    final user = userId == null ? null : _store.usersById[userId];
    if (user == null || user.password != password) {
      throw const AuthException(401, 'Invalid username or password.');
    }

    return _issueToken(user);
  }

  BackendUser authenticate(String? authorizationHeader) {
    final token = _extractBearerToken(authorizationHeader);
    final userId = token == null ? null : _store.userIdsByToken[token];
    final user = userId == null ? null : _store.usersById[userId];
    if (user == null) {
      throw const AuthException(401, 'Missing or invalid token.');
    }
    return user;
  }

  AuthResult _issueToken(BackendUser user) {
    final prefix = const String.fromEnvironment(
      'ECHOCHAT_TOKEN_PREFIX',
      defaultValue: 'echochat',
    );
    final token = '$prefix-${_uuid.v4()}';
    _store.userIdsByToken[token] = user.id;
    if (_store.userIdsByToken.length > _maxTokens) {
      _store.userIdsByToken.remove(_store.userIdsByToken.keys.first);
    }
    return AuthResult(token: token, user: user);
  }

  String? _extractBearerToken(String? authorizationHeader) {
    if (authorizationHeader == null) {
      return null;
    }
    final parts = authorizationHeader.split(' ');
    if (parts.length != 2 || parts.first.toLowerCase() != 'bearer') {
      return null;
    }
    return parts.last;
  }
}

final authService = AuthService(demoStore);
