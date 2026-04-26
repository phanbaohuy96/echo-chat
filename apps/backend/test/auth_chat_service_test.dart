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

    test('lists peers excluding the current user', () {
      final jane = authService.signup(
        name: 'Jane Doe',
        username: 'jane',
        password: 'secret123',
      );
      authService.signup(
        name: 'Bob Doe',
        username: 'bob',
        password: 'secret123',
      );

      final peers = chatService.listPeers(user: jane.user);

      expect(peers, hasLength(1));
      expect(peers.single.username, 'bob');
    });

    test('sends and fetches a direct message conversation', () {
      final jane = authService.signup(
        name: 'Jane Doe',
        username: 'jane',
        password: 'secret123',
      );
      final bob = authService.signup(
        name: 'Bob Doe',
        username: 'bob',
        password: 'secret123',
      );

      final sentMessage = chatService.sendMessage(
        sender: jane.user,
        recipientUserId: bob.user.id,
        clientMessageId: 'jane-1',
        message: 'Hello Bob',
      );
      chatService.sendMessage(
        sender: bob.user,
        recipientUserId: jane.user.id,
        clientMessageId: 'bob-1',
        message: 'Hi Jane',
      );

      final conversation = chatService.getConversation(
        user: jane.user,
        peerUserId: bob.user.id,
      );

      expect(conversation.peer.id, bob.user.id);
      expect(conversation.messages, hasLength(2));
      expect(conversation.messages.first.id, sentMessage.id);
      expect(conversation.messages.map((message) => message.message), [
        'Hello Bob',
        'Hi Jane',
      ]);
    });

    test('returns the latest page without a cursor', () {
      final jane = authService.signup(
        name: 'Jane Doe',
        username: 'jane',
        password: 'secret123',
      );
      final bob = authService.signup(
        name: 'Bob Doe',
        username: 'bob',
        password: 'secret123',
      );

      for (var i = 0; i < 5; i++) {
        chatService.sendMessage(
          sender: jane.user,
          recipientUserId: bob.user.id,
          clientMessageId: 'jane-$i',
          message: 'Message $i',
        );
      }

      final conversation = chatService.getConversation(
        user: jane.user,
        peerUserId: bob.user.id,
        limit: 2,
      );

      expect(conversation.messages.map((message) => message.message), [
        'Message 3',
        'Message 4',
      ]);
      expect(conversation.hasMoreOlder, isTrue);
      expect(
        conversation.latestMessageCreatedAt,
        conversation.messages.last.createdAt,
      );
      expect(
        conversation.oldestMessageCreatedAt,
        conversation.messages.first.createdAt,
      );
    });

    test('returns newer messages after a cursor', () {
      final jane = authService.signup(
        name: 'Jane Doe',
        username: 'jane',
        password: 'secret123',
      );
      final bob = authService.signup(
        name: 'Bob Doe',
        username: 'bob',
        password: 'secret123',
      );

      final firstMessage = chatService.sendMessage(
        sender: jane.user,
        recipientUserId: bob.user.id,
        clientMessageId: 'jane-1',
        message: 'Message 1',
      );
      chatService.sendMessage(
        sender: jane.user,
        recipientUserId: bob.user.id,
        clientMessageId: 'jane-2',
        message: 'Message 2',
      );
      chatService.sendMessage(
        sender: jane.user,
        recipientUserId: bob.user.id,
        clientMessageId: 'jane-3',
        message: 'Message 3',
      );

      final conversation = chatService.getConversation(
        user: jane.user,
        peerUserId: bob.user.id,
        afterCreatedAt: firstMessage.createdAt,
      );

      expect(conversation.messages.map((message) => message.message), [
        'Message 2',
        'Message 3',
      ]);
      expect(conversation.hasMoreOlder, isTrue);
    });

    test('returns older messages before a cursor', () {
      final jane = authService.signup(
        name: 'Jane Doe',
        username: 'jane',
        password: 'secret123',
      );
      final bob = authService.signup(
        name: 'Bob Doe',
        username: 'bob',
        password: 'secret123',
      );

      for (var i = 0; i < 5; i++) {
        chatService.sendMessage(
          sender: jane.user,
          recipientUserId: bob.user.id,
          clientMessageId: 'jane-$i',
          message: 'Message $i',
        );
      }
      final latestPage = chatService.getConversation(
        user: jane.user,
        peerUserId: bob.user.id,
        limit: 2,
      );

      final olderPage = chatService.getConversation(
        user: jane.user,
        peerUserId: bob.user.id,
        beforeCreatedAt: latestPage.messages.first.createdAt,
        limit: 2,
      );

      expect(olderPage.messages.map((message) => message.message), [
        'Message 1',
        'Message 2',
      ]);
      expect(olderPage.hasMoreOlder, isTrue);
    });

    test('returns capped delta metadata from the returned page', () {
      final jane = authService.signup(
        name: 'Jane Doe',
        username: 'jane',
        password: 'secret123',
      );
      final bob = authService.signup(
        name: 'Bob Doe',
        username: 'bob',
        password: 'secret123',
      );

      final firstMessage = chatService.sendMessage(
        sender: jane.user,
        recipientUserId: bob.user.id,
        clientMessageId: 'jane-0',
        message: 'Message 0',
      );
      for (var i = 1; i < 5; i++) {
        chatService.sendMessage(
          sender: jane.user,
          recipientUserId: bob.user.id,
          clientMessageId: 'jane-$i',
          message: 'Message $i',
        );
      }

      final deltaPage = chatService.getConversation(
        user: jane.user,
        peerUserId: bob.user.id,
        afterCreatedAt: firstMessage.createdAt,
        limit: 2,
      );

      expect(deltaPage.messages.map((message) => message.message), [
        'Message 1',
        'Message 2',
      ]);
      expect(
        deltaPage.latestMessageCreatedAt,
        deltaPage.messages.last.createdAt,
      );
    });

    test('returns the existing message for an idempotent retry', () {
      final jane = authService.signup(
        name: 'Jane Doe',
        username: 'jane',
        password: 'secret123',
      );
      final bob = authService.signup(
        name: 'Bob Doe',
        username: 'bob',
        password: 'secret123',
      );

      final firstMessage = chatService.sendMessage(
        sender: jane.user,
        recipientUserId: bob.user.id,
        clientMessageId: 'jane-1',
        message: 'Hello Bob',
      );
      final retriedMessage = chatService.sendMessage(
        sender: jane.user,
        recipientUserId: bob.user.id,
        clientMessageId: 'jane-1',
        message: 'Hello again',
      );
      final conversation = chatService.getConversation(
        user: jane.user,
        peerUserId: bob.user.id,
      );

      expect(retriedMessage.id, firstMessage.id);
      expect(retriedMessage.message, 'Hello Bob');
      expect(conversation.messages, hasLength(1));
    });

    test('rejects empty messages', () {
      final jane = authService.signup(
        name: 'Jane Doe',
        username: 'jane',
        password: 'secret123',
      );
      final bob = authService.signup(
        name: 'Bob Doe',
        username: 'bob',
        password: 'secret123',
      );

      expect(
        () => chatService.sendMessage(
          sender: jane.user,
          recipientUserId: bob.user.id,
          clientMessageId: 'jane-1',
          message: '   ',
        ),
        throwsA(
          isA<ChatException>().having(
            (error) => error.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });

    test('rejects missing client message ids', () {
      final jane = authService.signup(
        name: 'Jane Doe',
        username: 'jane',
        password: 'secret123',
      );
      final bob = authService.signup(
        name: 'Bob Doe',
        username: 'bob',
        password: 'secret123',
      );

      expect(
        () => chatService.sendMessage(
          sender: jane.user,
          recipientUserId: bob.user.id,
          clientMessageId: '   ',
          message: 'Hello Bob',
        ),
        throwsA(
          isA<ChatException>().having(
            (error) => error.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });

    test('rejects invalid recipients', () {
      final jane = authService.signup(
        name: 'Jane Doe',
        username: 'jane',
        password: 'secret123',
      );

      expect(
        () => chatService.sendMessage(
          sender: jane.user,
          recipientUserId: 'missing',
          clientMessageId: 'jane-1',
          message: 'Hello',
        ),
        throwsA(
          isA<ChatException>().having(
            (error) => error.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });

    test('rejects self sends', () {
      final jane = authService.signup(
        name: 'Jane Doe',
        username: 'jane',
        password: 'secret123',
      );

      expect(
        () => chatService.sendMessage(
          sender: jane.user,
          recipientUserId: jane.user.id,
          clientMessageId: 'jane-1',
          message: 'Note to self',
        ),
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
