import 'package:dart_frog/dart_frog.dart';

import '../../../lib/src/http/responses.dart';
import '../../../lib/src/services/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final result = authService.signup(
      name: body['name']?.toString() ?? '',
      username: body['username']?.toString() ?? '',
      password: body['password']?.toString() ?? '',
    );
    return Response.json(body: result.toJson());
  } on AuthException catch (error) {
    return errorJson(error.statusCode, error.message);
  } catch (_) {
    return invalidBody();
  }
}
