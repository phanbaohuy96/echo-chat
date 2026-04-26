part of 'signup_screen.dart';

extension SignUpAction on _SignUpScreenState {
  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || username.isEmpty || password.isEmpty) {
      showSnackBar(
        context: context,
        message: l10n.nameUsernamePasswordRequired,
      );
      return;
    }

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
