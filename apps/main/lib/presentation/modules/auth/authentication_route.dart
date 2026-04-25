import 'package:core/core.dart';

import '../../../di/di.dart';
import 'signin/bloc/signin_bloc.dart';
import 'signin/views/signin_screen.dart';
import 'signup/bloc/signup_bloc.dart';
import 'signup/views/signup_screen.dart';

class AuthenticationRoute extends IRoute {
  @override
  List<CustomRouter> routers() {
    return [
      CustomRouter(
        path: SignInScreen.routeName,
        builder: (context, uri, extra) {
          return BlocProvider<SigninBloc>(
            create: (context) => injector.get(),
            child: const SignInScreen(),
          );
        },
      ),
      CustomRouter(
        path: SignUpScreen.routeName,
        builder: (context, uri, extra) {
          return BlocProvider<SignupBloc>(
            create: (context) => injector.get(),
            child: const SignUpScreen(),
          );
        },
      ),
    ];
  }
}
