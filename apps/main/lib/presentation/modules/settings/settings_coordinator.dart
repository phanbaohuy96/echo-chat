import 'package:core/core.dart';
import 'package:flutter/material.dart';

import 'settings_home/views/settings_screen.dart';

extension SettingsCoordinator on BuildContext {
  /// Opens settings and returns whether local chat storage was cleared.
  Future<bool?> openSettings({
    PushBehavior pushBehavior = const PushNamedBehavior(),
  }) async {
    return pushBehavior.push(this, SettingsScreen.routeName);
  }
}
