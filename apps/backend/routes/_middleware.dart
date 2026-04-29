import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  return (context) async {
    if (context.request.method == HttpMethod.options) {
      return _withCors(Response());
    }
    return _withCors(await handler(context));
  };
}

Response _withCors(Response response) {
  return response.copyWith(
    headers: {
      ...response.headers,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
    },
  );
}
