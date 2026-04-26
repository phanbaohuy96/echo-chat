import 'dart:async';
import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../../../../domain/entities/auth/response.dart';
import '../../../../../l10n/localization_ext.dart';
import '../../../../base/base.dart';
import '../../../chat/chat_coordinator.dart';
import '../../auth_form_shell.dart';
import '../bloc/signup_bloc.dart';

part 'signup.action.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  static String routeName = '/signup';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends StateBase<SignUpScreen> {
  @override
  SignupBloc get bloc => BlocProvider.of(context);

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  late ThemeData _themeData;

  TextTheme get textTheme => _themeData.textTheme;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeData = context.theme;
    return BlocBuilder<SignupBloc, SignupState>(
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
        AuthBrandHeader(title: l10n.createEchoChatAccount),
        const SizedBox(height: 32),
        TextField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.name,
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.username,
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.password,
            prefixIcon: const Icon(Icons.lock_outline),
          ),
          onSubmitted: (_) => _handleSignup(),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ThemeButton.primary(
            title: l10n.signUp,
            onPressed: _handleSignup,
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.alreadyHaveAccount),
        ),
      ],
    );
  }
}
