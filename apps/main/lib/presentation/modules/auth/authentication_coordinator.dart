import 'package:core/core.dart';
import 'package:flutter/material.dart';

import 'signin/views/signin_screen.dart';
import 'signup/views/signup_screen.dart';

extension AuthenticationCoordinator on BuildContext {
  Future<bool?> openSignIn({
    PushBehavior pushBehavior = const PushNamedBehavior(),
  }) async {
    return pushBehavior.push(this, SignInScreen.routeName);
  }

  Future<bool?> openSignUp({
    PushBehavior pushBehavior = const PushNamedBehavior(),
  }) async {
    return pushBehavior.push(this, SignUpScreen.routeName);
  }
}
