part of 'settings_screen.dart';

extension SettingsAction on _SettingsScreenState {
  void _close() {
    Navigator.of(context).pop(bloc.state.storageCleared);
  }

  void _changeLanguage(bool isViLanguage) {
    context.read<AppGlobalBloc>().changeLocale(
      isViLanguage ? AppLocale.vi : AppLocale.en,
    );
  }

  Future<void> _openStorageManagement() async {
    final summary = await context.openStorageManagement();
    if (summary != null) {
      bloc.add(SettingsStorageClearedEvent(summary));
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showNoticeConfirmDialog(
      context: context,
      title: l10n.logout,
      message: l10n.logoutConfirmation,
      leftBtn: l10n.cancel,
      rightBtn: l10n.logout,
      styleRightBtn: TextStyle(color: context.themeColor.error),
    );
    if (!confirmed) {
      return;
    }
    showLoading();
    try {
      final completer = Completer<void>();
      bloc.add(SettingsLogoutRequestedEvent(completer));
      await completer.future;
      await doLogout();
      if (!mounted) {
        return;
      }
      await context.openSignIn(
        pushBehavior: PushNamedAndRemoveUntilBehavior.removeAll(),
      );
    } finally {
      hideLoading();
    }
  }
}
