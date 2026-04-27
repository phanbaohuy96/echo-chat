import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:injectable/injectable.dart';

import '../../../data/data_source/local/local_data_manager.dart';
import '../../../data/repositories/chat/chat_local_repository.dart';
import 'chat_peers_usecase.dart';

@Injectable(as: ChatPeersUsecase)
class ChatPeersInteractorImpl extends ChatPeersUsecase {
  ChatPeersInteractorImpl(
    this._localDataManager,
    this._appApiService,
    this._localRepository,
  );

  final LocalDataManager _localDataManager;
  final AppApiService _appApiService;
  final ChatLocalRepository _localRepository;

  @override
  Future<List<UserModel>> getCachedPeers() async {
    return _withoutCurrentUser(await _localRepository.getCachedPeers());
  }

  @override
  Future<List<UserModel>> syncPeers() async {
    final response = ChatUsersResponse.fromJson(
      await _appApiService.getChatUsers(),
    );
    await _localRepository.cachePeers(response.users);
    return _withoutCurrentUser(await _localRepository.getCachedPeers());
  }

  List<UserModel> _withoutCurrentUser(List<UserModel> peers) {
    final currentUserId = _localDataManager.userInfo?.id;
    if (currentUserId == null) {
      return peers;
    }
    return peers.where((peer) => peer.id != currentUserId).toList();
  }
}
