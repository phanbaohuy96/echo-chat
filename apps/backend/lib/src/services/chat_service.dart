import '../models/user.dart';
import '../store/demo_store.dart';

class ChatException implements Exception {
  const ChatException(this.statusCode, this.message);

  final int statusCode;
  final String message;
}

class ChatService {
  ChatService(this._store);

  static const _maxMessagesPerUser = 80;

  final DemoStore _store;

  String sendMessage({required BackendUser user, required String message}) {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) {
      throw const ChatException(400, 'Message is required.');
    }

    final reply = _replyFor(cleanMessage);
    final messages = _store.messagesByUserId.putIfAbsent(user.id, () => []);
    messages
      ..add({'role': 'user', 'content': cleanMessage})
      ..add({'role': 'assistant', 'content': reply});
    if (messages.length > _maxMessagesPerUser) {
      messages.removeRange(0, messages.length - _maxMessagesPerUser);
    }
    return reply;
  }

  String _replyFor(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('auth') || lower.contains('login')) {
      return 'EchoChat uses a Dart Frog backend for signup, signin, token validation, and chat business logic.';
    }
    if (lower.contains('flutter') || lower.contains('bloc')) {
      return 'The Flutter client follows the template: BLoC for state, routes through RouteGenerator, and API calls through AppApiService.';
    }
    if (lower.contains('env')) {
      return 'EchoChat keeps separate env files for frontend and backend so client config never carries server secrets.';
    }
    return 'Echo reply: $message';
  }
}

final chatService = ChatService(demoStore);
