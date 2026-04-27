import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../../../domain/entities/chat/chat_local_storage_summary.dart';
import 'views/storage_management_screen.dart';

extension StorageManagementCoordinator on BuildContext {
  /// Opens storage management and returns the refreshed summary after clearing.
  Future<ChatLocalStorageSummary?> openStorageManagement({
    PushBehavior pushBehavior = const PushNamedBehavior(),
  }) async {
    return pushBehavior.push(this, StorageManagementScreen.routeName);
  }
}
