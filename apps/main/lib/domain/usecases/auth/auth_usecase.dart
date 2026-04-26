import 'dart:async';

import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:injectable/injectable.dart';

import '../../../data/data_source/local/local_data_manager.dart';
import '../../entities/auth/response.dart';

part 'auth_usecase.impl.dart';

abstract class AuthUsecase {
  Future<AuthResponse> signin({
    required String username,
    required String password,
  });

  Future<AuthResponse> signup({
    required String name,
    required String username,
    required String password,
  });

  Future<AuthResponse> loginWithPhoneNumberPassword({
    required String phoneNumber,
    required String password,
  });

  Future<AuthResponse> authWithUserToken(UserToken token);
}
