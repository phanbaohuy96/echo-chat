import '../../entities/chat/chat_local_storage_summary.dart';

/// Coordinates local chat cache maintenance.
abstract class ChatStorageUsecase {
  /// Returns counts and date bounds for chat data cached on this device.
  Future<ChatLocalStorageSummary> getLocalStorageSummary();

  /// Clears cached chat peers, messages, and sync metadata on this device.
  Future<void> clearLocalStorage();
}
