part of 'account_selection.dart';

extension AccountSelectionAction on _AccountSelectionState {
  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      showSnackBar(context: context, message: l10n.usernamePasswordRequired);
      return;
    }

    final completer = Completer<AuthResponse>();
    bloc.add(
      LoginEvent(username: username, password: password, completer: completer),
    );

    AuthResponse result;
    try {
      result = await completer.future;
    } catch (_) {
      return;
    }

    switch (result.result) {
      case LoginResultType.failed:
        showSnackBar(context: context, message: l10n.loginFailed);
        break;
      case LoginResultType.unsupportedRole:
        showSnackBar(context: context, message: l10n.thisRoleIsNotSupportedYet);
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
