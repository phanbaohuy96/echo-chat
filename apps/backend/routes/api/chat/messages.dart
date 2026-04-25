import 'package:dart_frog/dart_frog.dart';

import '../../../lib/src/http/responses.dart';
import '../../../lib/src/services/auth_service.dart';
import '../../../lib/src/services/chat_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  try {
    final user = authService.authenticate(
      context.request.headers['authorization'],
    );
    final body = await context.request.json() as Map<String, dynamic>;
    final reply = chatService.sendMessage(
      user: user,
      message: body['message']?.toString() ?? '',
    );
    return Response.json(body: {'reply': reply});
  } on AuthException catch (error) {
    return errorJson(error.statusCode, error.message);
  } on ChatException catch (error) {
    return errorJson(error.statusCode, error.message);
  } catch (_) {
    return invalidBody();
  }
}
