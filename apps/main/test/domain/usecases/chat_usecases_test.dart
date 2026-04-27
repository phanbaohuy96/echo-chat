import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:flutter_core/domain/entities/chat/chat_conversation_sync.dart';
import 'package:flutter_core/domain/entities/chat/chat_local_storage_summary.dart';
import 'package:flutter_core/domain/entities/chat/local_chat_message.dart';
import 'package:flutter_core/domain/usecases/chat/chat_conversation_usecase.impl.dart';
import 'package:flutter_core/domain/usecases/chat/chat_outbox_usecase.impl.dart';
import 'package:flutter_core/domain/usecases/chat/chat_peers_usecase.impl.dart';
import 'package:flutter_core/domain/usecases/chat/chat_storage_usecase.impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../usecase_test_fakes.dart';

void main() {
  group(ChatPeersInteractorImpl, () {
    test('getCachedPeers reads cache and filters current user', () async {
      final localDataManager = TestLocalDataManager(
        userInfo: const UserModel(id: 'current-user'),
      );
      final repository = FakeChatLocalRepository()
        ..cachedPeers = const [
          UserModel(id: 'current-user', username: 'me'),
          UserModel(id: 'peer', username: 'peer'),
        ];
      final usecase = ChatPeersInteractorImpl(
        localDataManager,
        AppApiService(FakeRestApiRepository(), localDataManager),
        repository,
      );

      final peers = await usecase.getCachedPeers();

      expect(peers.map((peer) => peer.id), ['peer']);
    });

    test('syncPeers caches remote peers and filters current user', () async {
      final localDataManager = TestLocalDataManager(
        userInfo: const UserModel(id: 'current-user'),
      );
      final restApi = FakeRestApiRepository()
        ..chatUsersResponse = const ChatUsersResponse(
          users: [
            UserModel(id: 'current-user', username: 'me'),
            UserModel(id: 'peer', username: 'peer'),
          ],
        ).toJson();
      final repository = FakeChatLocalRepository();
      final usecase = ChatPeersInteractorImpl(
        localDataManager,
        AppApiService(restApi, localDataManager),
        repository,
      );

      final peers = await usecase.syncPeers();

      expect(repository.cachedPeerInput?.map((peer) => peer.id), [
        'current-user',
        'peer',
      ]);
      expect(peers.map((peer) => peer.id), ['peer']);
    });
  });

  group(ChatConversationInteractorImpl, () {
    test('getCachedConversation delegates to local cache with limit', () async {
      final localDataManager = TestLocalDataManager(
        userInfo: const UserModel(id: 'current-user'),
      );
      final repository = FakeChatLocalRepository()
        ..messages['older'] = localMessage(clientMessageId: 'older')
        ..messages['newer'] = localMessage(
          clientMessageId: 'newer',
          createdAt: DateTime(2026, 1, 2),
        );
      final usecase = ChatConversationInteractorImpl(
        localDataManager,
        AppApiService(FakeRestApiRepository(), localDataManager),
        repository,
      );

      final messages = await usecase.getCachedConversation('peer', limit: 1);

      expect(messages.single.clientMessageId, 'newer');
    });

    test(
      'refreshConversation falls back to cache without current user',
      () async {
        final localDataManager = TestLocalDataManager();
        final repository = FakeChatLocalRepository()
          ..messages['client-message'] = localMessage();
        final usecase = ChatConversationInteractorImpl(
          localDataManager,
          AppApiService(FakeRestApiRepository(), localDataManager),
          repository,
        );

        final messages = await usecase.refreshConversation('peer');

        expect(messages.single.clientMessageId, 'client-message');
        expect(repository.cacheRemoteConversationCount, 0);
      },
    );

    test(
      'refreshConversation fetches newer messages and updates cache',
      () async {
        final latest = DateTime.utc(2026, 1, 1);
        final remoteCreatedAt = DateTime.utc(2026, 1, 2);
        final localDataManager = TestLocalDataManager(
          userInfo: const UserModel(id: 'current-user'),
        );
        final restApi = FakeRestApiRepository()
          ..chatMessagesResponse = ChatConversationResponse(
            peer: const UserModel(id: 'peer'),
            messages: [
              messageDto(
                id: 'remote',
                clientMessageId: 'remote-client',
                senderUserId: 'peer',
                recipientUserId: 'current-user',
                createdAt: remoteCreatedAt,
              ),
            ],
            syncMetadata: ChatConversationSyncMetadataDto(
              latestMessageCreatedAt: remoteCreatedAt,
              oldestMessageCreatedAt: remoteCreatedAt,
            ),
          ).toJson();
        final repository = FakeChatLocalRepository()
          ..syncs['peer'] = ChatConversationSync(
            peerUserId: 'peer',
            latestMessageCreatedAt: latest,
          );
        final usecase = ChatConversationInteractorImpl(
          localDataManager,
          AppApiService(restApi, localDataManager),
          repository,
        );

        final messages = await usecase.refreshConversation('peer');

        expect(restApi.lastChatMessagesPeerUserId, 'peer');
        expect(restApi.lastAfterCreatedAt, latest.toUtc().toIso8601String());
        expect(repository.lastCachedRemoteCurrentUserId, 'current-user');
        expect(messages.single.clientMessageId, 'remote-client');
      },
    );

    test(
      'loadOlderMessages skips remote call when sync has no older page',
      () async {
        final localDataManager = TestLocalDataManager(
          userInfo: const UserModel(id: 'current-user'),
        );
        final repository = FakeChatLocalRepository()
          ..messages['client-message'] = localMessage()
          ..syncs['peer'] = const ChatConversationSync(
            peerUserId: 'peer',
            hasMoreOlder: false,
          );
        final usecase = ChatConversationInteractorImpl(
          localDataManager,
          AppApiService(FakeRestApiRepository(), localDataManager),
          repository,
        );

        final result = await usecase.loadOlderMessages('peer');

        expect(result.messages.single.clientMessageId, 'client-message');
        expect(result.hasMoreOlder, isFalse);
        expect(repository.cacheRemoteConversationCount, 0);
      },
    );

    test(
      'loadOlderMessages fetches older page and returns updated cache',
      () async {
        final oldest = DateTime.utc(2026, 1, 2);
        final older = DateTime.utc(2026, 1, 1);
        final localDataManager = TestLocalDataManager(
          userInfo: const UserModel(id: 'current-user'),
        );
        final restApi = FakeRestApiRepository()
          ..chatMessagesResponse = ChatConversationResponse(
            peer: const UserModel(id: 'peer'),
            messages: [
              messageDto(
                id: 'older',
                clientMessageId: 'older-client',
                senderUserId: 'peer',
                recipientUserId: 'current-user',
                createdAt: older,
              ),
            ],
            syncMetadata: ChatConversationSyncMetadataDto(
              latestMessageCreatedAt: oldest,
              oldestMessageCreatedAt: older,
            ),
          ).toJson();
        final repository = FakeChatLocalRepository()
          ..messages['client-message'] = localMessage(createdAt: oldest)
          ..syncs['peer'] = ChatConversationSync(
            peerUserId: 'peer',
            oldestMessageCreatedAt: oldest,
          );
        final usecase = ChatConversationInteractorImpl(
          localDataManager,
          AppApiService(restApi, localDataManager),
          repository,
        );

        final result = await usecase.loadOlderMessages('peer');

        expect(restApi.lastBeforeCreatedAt, oldest.toUtc().toIso8601String());
        expect(restApi.lastChatMessagesLimit, 20);
        expect(result.messages.map((message) => message.clientMessageId), [
          'older-client',
          'client-message',
        ]);
        expect(result.hasMoreOlder, isFalse);
      },
    );

    test('hasMoreOlderMessages defaults to true without metadata', () async {
      final localDataManager = TestLocalDataManager(
        userInfo: const UserModel(id: 'current-user'),
      );
      final usecase = ChatConversationInteractorImpl(
        localDataManager,
        AppApiService(FakeRestApiRepository(), localDataManager),
        FakeChatLocalRepository(),
      );

      await expectLater(
        usecase.hasMoreOlderMessages('peer'),
        completion(isTrue),
      );
    });
  });

  group(ChatOutboxInteractorImpl, () {
    test('enqueueMessage creates a pending local message', () async {
      final localDataManager = TestLocalDataManager(
        userInfo: const UserModel(id: 'current-user'),
      );
      final repository = FakeChatLocalRepository();
      final usecase = ChatOutboxInteractorImpl(
        localDataManager,
        AppApiService(FakeRestApiRepository(), localDataManager),
        repository,
      );

      final message = await usecase.enqueueMessage(
        recipientUserId: 'peer',
        clientMessageId: 'client-message',
        message: 'Hello',
        senderUserId: 'current-user',
      );

      expect(message.status, ChatMessageStatus.pending);
      expect(repository.messages['client-message'], message);
    });

    test(
      'sendQueuedMessage marks sent and returns conversation cache',
      () async {
        final localDataManager = TestLocalDataManager(
          userInfo: const UserModel(id: 'current-user'),
        );
        final restApi = FakeRestApiRepository()
          ..sendChatMessageResponse = SendMessageResponse(
            message: messageDto(clientMessageId: 'client-message'),
          ).toJson();
        final repository = FakeChatLocalRepository()
          ..messages['client-message'] = localMessage(
            clientMessageId: 'client-message',
            status: ChatMessageStatus.pending,
          );
        final usecase = ChatOutboxInteractorImpl(
          localDataManager,
          AppApiService(restApi, localDataManager),
          repository,
        );

        final messages = await usecase.sendQueuedMessage('client-message');

        expect(restApi.lastSendChatMessageBody, {
          'recipient_user_id': 'peer',
          'client_message_id': 'client-message',
          'message': 'Hello',
        });
        expect(repository.markSentCount, 1);
        expect(messages.single.status, ChatMessageStatus.sent);
      },
    );

    test('sendQueuedMessage marks failed when remote send fails', () async {
      final localDataManager = TestLocalDataManager(
        userInfo: const UserModel(id: 'current-user'),
      );
      final restApi = FakeRestApiRepository()
        ..sendChatMessageError = StateError('offline');
      final repository = FakeChatLocalRepository()
        ..messages['client-message'] = localMessage(
          clientMessageId: 'client-message',
          status: ChatMessageStatus.pending,
        );
      final usecase = ChatOutboxInteractorImpl(
        localDataManager,
        AppApiService(restApi, localDataManager),
        repository,
      );

      final messages = await usecase.sendQueuedMessage('client-message');

      expect(repository.markFailedCount, 1);
      expect(repository.lastMarkedFailedClientMessageId, 'client-message');
      expect(repository.lastMarkedFailedErrorMessage, contains('offline'));
      expect(messages.single.status, ChatMessageStatus.failed);
    });

    test('retryMessage marks pending before attempting delivery', () async {
      final localDataManager = TestLocalDataManager(
        userInfo: const UserModel(id: 'current-user'),
      );
      final repository = FakeChatLocalRepository()
        ..messages['client-message'] = localMessage(
          clientMessageId: 'client-message',
          status: ChatMessageStatus.failed,
          errorMessage: 'offline',
        );
      final usecase = ChatOutboxInteractorImpl(
        localDataManager,
        AppApiService(FakeRestApiRepository(), localDataManager),
        repository,
      );

      await usecase.retryMessage('client-message');

      expect(repository.markPendingCount, 1);
      expect(repository.markSentCount, 1);
    });

    test('syncOutbox sends pending messages for the requested peer', () async {
      final localDataManager = TestLocalDataManager(
        userInfo: const UserModel(id: 'current-user'),
      );
      final repository = FakeChatLocalRepository()
        ..messages['peer-message'] = localMessage(
          clientMessageId: 'peer-message',
          conversationPeerUserId: 'peer',
          status: ChatMessageStatus.pending,
        )
        ..messages['other-message'] = localMessage(
          clientMessageId: 'other-message',
          conversationPeerUserId: 'other',
          recipientUserId: 'other',
          status: ChatMessageStatus.pending,
        );
      final usecase = ChatOutboxInteractorImpl(
        localDataManager,
        AppApiService(FakeRestApiRepository(), localDataManager),
        repository,
      );

      await usecase.syncOutbox(peerUserId: 'peer');

      expect(repository.lastOutboxPeerUserId, 'peer');
      expect(repository.markSentCount, 1);
      expect(repository.lastMarkedSentClientMessageId, 'peer-message');
    });
  });

  group(ChatStorageInteractorImpl, () {
    test('getLocalStorageSummary delegates to repository', () async {
      const summary = ChatLocalStorageSummary(
        peerCount: 2,
        messageCount: 3,
        pendingMessageCount: 1,
        failedMessageCount: 0,
      );
      final repository = FakeChatLocalRepository()..storageSummary = summary;
      final usecase = ChatStorageInteractorImpl(repository);

      await expectLater(usecase.getLocalStorageSummary(), completion(summary));
    });

    test('clearLocalStorage clears cached chat data', () async {
      final repository = FakeChatLocalRepository();
      final usecase = ChatStorageInteractorImpl(repository);

      await usecase.clearLocalStorage();

      expect(repository.cleared, isTrue);
    });
  });
}
