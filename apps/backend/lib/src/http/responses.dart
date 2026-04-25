import 'package:dart_frog/dart_frog.dart';

Response methodNotAllowed() => Response(statusCode: 405);

Response errorJson(int statusCode, String message) {
  return Response.json(statusCode: statusCode, body: {'message': message});
}

Response invalidBody() => errorJson(400, 'Invalid request body.');
