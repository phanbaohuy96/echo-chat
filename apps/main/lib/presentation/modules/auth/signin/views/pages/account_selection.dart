import 'dart:async';
import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../../../../../domain/entities/auth/response.dart';
import '../../../../../../generated/assets.dart';
import '../../../../../../l10n/localization_ext.dart';
import '../../../../../base/base.dart';
import '../../../../../extentions/extention.dart';
import '../../../authentication_coordinator.dart';
import '../../bloc/signin_bloc.dart';
import '../signin_screen.dart';

class AccountSelection extends StatefulWidget {
  const AccountSelection({super.key});

  @override
  State<AccountSelection> createState() => _AccountSelectionState();
}

class _AccountSelectionState extends StateBase<AccountSelection> {
  @override
  SigninBloc get bloc => BlocProvider.of(context);

  @override
  bool get willHandleError => false;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  late ThemeData _themeData;

  TextTheme get textTheme => _themeData.textTheme;

  late AppLocalizations trans;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeData = context.theme;
    trans = translate(context);
    return BlocConsumer<SigninBloc, SigninState>(
      listener: _blocListener,
      builder: (context, state) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: _buildBody(context),
                ),
              ),
            ),
            resizeToAvoidBottomInset: true,
            bottomNavigationBar: Padding(
              padding: EdgeInsets.only(bottom: max(paddingBottom, 16)),
              child: Text(
                trans.poweredByVNS,
                style: textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(Assets.image.logo, height: 100, fit: BoxFit.fitHeight),
          const SizedBox(height: 20),
          Text('EchoChat'.hardcode, style: textTheme.titleMedium),
          const SizedBox(height: 30),
          TextField(
            key: const Key(SignInScreen.usernameKey),
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key(SignInScreen.passwordKey),
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ThemeButton.primary(
              title: trans.login,
              onPressed: _handleLogin,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.openSignUp(),
            child: const Text('Create an account'),
          ),
        ],
      ),
    );
  }
}

extension on _AccountSelectionState {
  void _blocListener(BuildContext context, SigninState state) {
    hideLoading();
  }

  Future _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      showSnackBar(
        context: context,
        message: 'Username and password are required.',
      );
      return;
    }

    showLoading();
    final completer = Completer<AuthResponse>();
    bloc.add(
      LoginEvent(username: username, password: password, completer: completer),
    );

    final result = await completer.future;

    switch (result.result) {
      case LoginResultType.failed:
        showSnackBar(context: context, message: trans.loginFailed);
        break;
      case LoginResultType.unsupportedRole:
        showSnackBar(
          context: context,
          message: trans.thisRoleIsNotSupportedYet,
        );
        break;
      default:
    }

    if (result is AuthSuccessResponse) {
      SigninScreenInherited.maybeOf(
        context,
      )?.state.loginSuccessCallback(result);
    }
  }
}
