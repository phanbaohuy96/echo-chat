import 'package:dart_frog/dart_frog.dart';

import '../../../lib/src/http/responses.dart';
import '../../../lib/src/services/auth_service.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  try {
    final user = authService.authenticate(
      context.request.headers['authorization'],
    );
    return Response.json(body: {'user': user.toPublicJson()});
  } on AuthException catch (error) {
    return errorJson(error.statusCode, error.message);
  }
}
