import 'package:dart_frog/dart_frog.dart';

import '../../../lib/src/http/responses.dart';
import '../../../lib/src/services/auth_service.dart';
import '../../../lib/src/services/chat_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  try {
    final user = authService.authenticate(
      context.request.headers['authorization'],
    );
    final users = chatService
        .listPeers(user: user)
        .map((peer) => peer.toPublicJson())
        .toList();
    return Response.json(body: {'users': users});
  } on AuthException catch (error) {
    return errorJson(error.statusCode, error.message);
  } on ChatException catch (error) {
    return errorJson(error.statusCode, error.message);
  }
}
