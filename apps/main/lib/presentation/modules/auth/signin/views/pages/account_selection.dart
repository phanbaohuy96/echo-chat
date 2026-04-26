import 'dart:async';
import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../../../../../domain/entities/auth/response.dart';
import '../../../../../../l10n/localization_ext.dart';
import '../../../../../base/base.dart';
import '../../../auth_form_shell.dart';
import '../../../authentication_coordinator.dart';
import '../../bloc/signin_bloc.dart';
import '../signin_screen.dart';

part 'account_selection.action.dart';

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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeData = context.theme;
    return BlocBuilder<SigninBloc, SigninState>(
      builder: (context, state) {
        return ScreenForm(
          resizeToAvoidBottomInset: true,
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(bottom: max(paddingBottom, 16)),
            child: Text(
              l10n.poweredByEchoChat,
              style: textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
          ),
          child: AuthFormShell(child: _buildBody()),
        );
      },
    );
  }

  Widget _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuthBrandHeader(title: l10n.appName),
        const SizedBox(height: 32),
        TextField(
          key: const Key(SignInScreen.usernameKey),
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.username,
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key(SignInScreen.passwordKey),
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.password,
            prefixIcon: const Icon(Icons.lock_outline),
          ),
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ThemeButton.primary(
            title: l10n.login,
            onPressed: _handleLogin,
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.openSignUp(),
          child: Text(l10n.createAccount),
        ),
      ],
    );
  }
}
