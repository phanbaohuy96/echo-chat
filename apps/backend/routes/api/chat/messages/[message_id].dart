import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/src/http/responses.dart';
import '../../../../lib/src/services/auth_service.dart';
import '../../../../lib/src/services/chat_service.dart';

Future<Response> onRequest(RequestContext context, String messageId) async {
  if (context.request.method != HttpMethod.delete) {
    return methodNotAllowed();
  }

  try {
    final user = authService.authenticate(
      context.request.headers['authorization'],
    );
    final message = chatService.deleteMessage(user: user, messageId: messageId);
    return Response.json(body: {'message': message.toJson()});
  } on AuthException catch (error) {
    return errorJson(error.statusCode, error.message);
  } on ChatException catch (error) {
    return errorJson(error.statusCode, error.message);
  }
}
