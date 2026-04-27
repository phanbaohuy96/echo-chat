import 'dart:async';

import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:injectable/injectable.dart';

import '../../../data/data_source/local/local_data_manager.dart';
import '../../entities/auth/response.dart';

part 'auth_usecase.impl.dart';

/// Coordinates authentication requests and local session persistence.
abstract class AuthUsecase {
  /// Signs in with [username] and [password], then stores the returned session.
  ///
  /// On success, the user token and profile are persisted locally before an
  /// [AuthSuccessResponse] is returned.
  Future<AuthResponse> signin({
    required String username,
    required String password,
  });

  /// Creates a new account, then stores the returned session.
  ///
  /// On success, the user token and profile are persisted locally before an
  /// [AuthSuccessResponse] is returned.
  Future<AuthResponse> signup({
    required String name,
    required String username,
    required String password,
  });

  /// Signs in by mapping [phoneNumber] to the username credential field.
  ///
  /// This is a compatibility entry point for phone-number login flows and has
  /// the same persistence behavior as [signin].
  Future<AuthResponse> loginWithPhoneNumberPassword({
    required String phoneNumber,
    required String password,
  });

  /// Restores a session from [token] and validates it with the backend.
  ///
  /// The token is stored before requesting the current user. On success, the
  /// user profile is persisted locally. If validation fails, the stored token
  /// is cleared and the original error is rethrown.
  Future<AuthResponse> authWithUserToken(UserToken token);
}
