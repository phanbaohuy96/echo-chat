part of 'signup_screen.dart';

extension SignUpAction on _SignUpScreenState {
  Future<void> _handleSignup() async {
    if (_isSubmitting || _formKey.currentState?.validate() != true) {
      return;
    }
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    _setSubmitting(true);
    final completer = Completer<AuthResponse>();
    bloc.add(
      SignupSubmittedEvent(
        name: name,
        username: username,
        password: password,
        completer: completer,
      ),
    );
    AuthResponse result;
    try {
      result = await completer.future;
    } catch (_) {
      return;
    } finally {
      if (mounted) {
        _setSubmitting(false);
      }
    }
    if (result is AuthSuccessResponse) {
      await context.openChat(
        pushBehavior: PushNamedAndRemoveUntilBehavior.removeAll(),
      );
      return;
    }
    showSnackBar(context: context, message: l10n.signUpFailed);
  }
}
