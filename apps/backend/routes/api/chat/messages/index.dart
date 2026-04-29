import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/src/http/responses.dart';
import '../../../../lib/src/services/auth_service.dart';
import '../../../../lib/src/services/chat_service.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getConversation(context),
    HttpMethod.post => _sendMessage(context),
    _ => methodNotAllowed(),
  };
}

Future<Response> _getConversation(RequestContext context) async {
  try {
    final user = authService.authenticate(
      context.request.headers['authorization'],
    );
    final query = context.request.uri.queryParameters;
    final result = chatService.getConversation(
      user: user,
      peerUserId: query['peer_user_id'] ?? '',
      afterCreatedAt: _parseDateTime(query['after_created_at']),
      afterUpdatedAt: _parseDateTime(query['after_updated_at']),
      beforeCreatedAt: _parseDateTime(query['before_created_at']),
      limit: int.tryParse(query['limit'] ?? ''),
    );
    return Response.json(
      body: {
        'peer': result.peer.toPublicJson(),
        'messages': result.messages.map((message) => message.toJson()).toList(),
        'sync_metadata': result.syncMetadata,
      },
    );
  } on AuthException catch (error) {
    return errorJson(error.statusCode, error.message);
  } on ChatException catch (error) {
    return errorJson(error.statusCode, error.message);
  }
}

DateTime? _parseDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  final milliseconds = int.tryParse(value);
  if (milliseconds != null) {
    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }
  return DateTime.tryParse(value)?.toUtc();
}

Future<Response> _sendMessage(RequestContext context) async {
  try {
    final user = authService.authenticate(
      context.request.headers['authorization'],
    );
    final body = await context.request.json() as Map<String, dynamic>;
    final message = chatService.sendMessage(
      sender: user,
      recipientUserId: body['recipient_user_id']?.toString() ?? '',
      clientMessageId: body['client_message_id']?.toString() ?? '',
      message: body['message']?.toString() ?? '',
    );
    return Response.json(body: {'message': message.toJson()});
  } on AuthException catch (error) {
    return errorJson(error.statusCode, error.message);
  } on ChatException catch (error) {
    return errorJson(error.statusCode, error.message);
  } catch (_) {
    return invalidBody();
  }
}
