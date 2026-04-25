import 'dart:async';
import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../../../../domain/entities/auth/response.dart';
import '../../../../../generated/assets.dart';
import '../../../../../l10n/localization_ext.dart';
import '../../../../base/base.dart';
import '../../../../extentions/extention.dart';
import '../../../chat/chat_coordinator.dart';
import '../bloc/signup_bloc.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  static String routeName = '/signup';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends StateBase<SignUpScreen> {
  @override
  SignupBloc get bloc => BlocProvider.of(context);

  @override
  bool get willHandleError => false;

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  late ThemeData _themeData;

  TextTheme get textTheme => _themeData.textTheme;

  late AppLocalizations trans;

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
    trans = translate(context);
    return BlocConsumer<SignupBloc, SignupState>(
      listener: (_, __) => hideLoading(),
      builder: (context, state) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: _buildBody(),
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

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(Assets.image.logo, height: 100, fit: BoxFit.fitHeight),
          const SizedBox(height: 20),
          Text(
            'Create EchoChat account'.hardcode,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            onSubmitted: (_) => _handleSignup(),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ThemeButton.primary(
              title: 'Sign up',
              onPressed: _handleSignup,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I already have an account'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || username.isEmpty || password.isEmpty) {
      showSnackBar(
        context: context,
        message: 'Name, username, and password are required.',
      );
      return;
    }

    showLoading();
    final completer = Completer<AuthResponse>();
    bloc.add(
      SignupSubmittedEvent(
        name: name,
        username: username,
        password: password,
        completer: completer,
      ),
    );
    final result = await completer.future;
    if (result is AuthSuccessResponse) {
      await context.openChat(
        pushBehavior: PushNamedAndRemoveUntilBehavior.removeAll(),
      );
      return;
    }
    showSnackBar(context: context, message: 'Sign up failed.');
  }
}
