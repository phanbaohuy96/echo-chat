import 'package:echochat_backend/src/services/auth_service.dart';
import 'package:echochat_backend/src/services/chat_service.dart';
import 'package:echochat_backend/src/store/demo_store.dart';
import 'package:test/test.dart';

void main() {
  group('AuthService', () {
    late DemoStore store;
    late AuthService authService;

    setUp(() {
      store = DemoStore();
      authService = AuthService(store);
    });

    test('signs up and authenticates a user', () {
      final result = authService.signup(
        name: 'Jane Doe',
        username: 'Jane',
        password: 'secret123',
      );

      expect(result.user.name, 'Jane Doe');
      expect(result.user.username, 'jane');
      expect(result.token, isNotEmpty);

      final user = authService.authenticate('Bearer ${result.token}');
      expect(user.id, result.user.id);
    });

    test('rejects duplicate usernames', () {
      authService.signup(
        name: 'Jane Doe',
        username: 'jane',
        password: 'secret123',
      );

      expect(
        () => authService.signup(
          name: 'Jane Two',
          username: 'JANE',
          password: 'secret456',
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.statusCode,
            'statusCode',
            409,
          ),
        ),
      );
    });

    test('rejects invalid signin credentials', () {
      expect(
        () => authService.signin(username: 'missing', password: 'bad'),
        throwsA(
          isA<AuthException>().having(
            (error) => error.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });
  });

  group('ChatService', () {
    late DemoStore store;
    late AuthService authService;
    late ChatService chatService;

    setUp(() {
      store = DemoStore();
      authService = AuthService(store);
      chatService = ChatService(store);
    });

    test('returns a demo reply and stores the exchange', () {
      final auth = authService.signup(
        name: 'Jane Doe',
        username: 'jane',
        password: 'secret123',
      );

      final reply = chatService.sendMessage(
        user: auth.user,
        message: 'How does Flutter BLoC work?',
      );

      expect(reply, contains('BLoC'));
      expect(store.messagesByUserId[auth.user.id], hasLength(2));
    });

    test('rejects empty messages', () {
      final auth = authService.signup(
        name: 'Jane Doe',
        username: 'jane',
        password: 'secret123',
      );

      expect(
        () => chatService.sendMessage(user: auth.user, message: '   '),
        throwsA(
          isA<ChatException>().having(
            (error) => error.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });
  });
}
