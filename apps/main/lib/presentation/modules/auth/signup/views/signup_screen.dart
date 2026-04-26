import 'dart:async';
import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;
  var _isSubmitting = false;

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
          showBackButton: false,
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
        const SizedBox(height: 30),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(
                    labelText: l10n.name,
                    prefixIcon: const Icon(Iconsax.user_edit),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  decoration: InputDecoration(
                    labelText: l10n.username,
                    prefixIcon: const Icon(Iconsax.user),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: const Icon(Iconsax.lock),
                    suffixIcon: IconButton(
                      tooltip: l10n.password,
                      onPressed: _togglePasswordVisibility,
                      icon: Icon(
                        _obscurePassword ? Iconsax.eye : Iconsax.eye_slash,
                      ),
                    ),
                  ),
                  validator: _requiredValidator,
                  onFieldSubmitted: (_) => _handleSignup(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ThemeButton.primary(
            title: l10n.signUp,
            enable: !_isSubmitting,
            minimumSize: const Size.fromHeight(50),
            prefixIcon: _isSubmitting
                ? SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.themeColor.onPrimary,
                    ),
                  )
                : null,
            onPressed: _handleSignup,
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.alreadyHaveAccount),
        ),
      ],
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.nameUsernamePasswordRequired;
    }
    return null;
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _setSubmitting(bool value) {
    setState(() => _isSubmitting = value);
  }
}
