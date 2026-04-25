import 'user.dart';

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final BackendUser user;

  Map<String, dynamic> toJson() {
    return {
      'token': {'access_token': token, 'token_type': 'Bearer'},
      'user': user.toPublicJson(),
    };
  }
}
