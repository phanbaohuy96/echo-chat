part of 'storage_management_screen.dart';

extension StorageManagementAction on _StorageManagementScreenState {
  void _close() {
    Navigator.of(
      context,
    ).pop(bloc.state.storageCleared ? bloc.state.summary : null);
  }

  Future<void> _confirmClearLocalStorage() async {
    final confirmed = await showNoticeConfirmDialog(
      context: context,
      title: l10n.clearLocalStorage,
      message: l10n.clearLocalStorageMessage,
      leftBtn: l10n.cancel,
      rightBtn: l10n.clearLocalStorage,
      styleRightBtn: TextStyle(color: context.themeColor.error),
    );
    if (!confirmed) {
      return;
    }

    final completer = Completer<ChatLocalStorageSummary>();
    bloc.add(StorageManagementClearRequestedEvent(completer));
    await completer.future;
    if (!mounted) {
      return;
    }
    showSnackBar(context: context, message: l10n.localStorageCleared);
  }
}
