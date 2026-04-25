import 'package:core/core.dart';
import 'package:flutter/material.dart';

import 'conversation/views/chat_screen.dart';

extension ChatCoordinator on BuildContext {
  Future<bool?> openChat({
    PushBehavior pushBehavior = const PushNamedBehavior(),
  }) async {
    return pushBehavior.push(this, ChatScreen.routeName);
  }
}
