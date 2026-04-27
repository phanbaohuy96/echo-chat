import 'package:injectable/injectable.dart';

import '../../../data/repositories/chat/chat_local_repository.dart';
import '../../entities/chat/chat_local_storage_summary.dart';
import 'chat_storage_usecase.dart';

@Injectable(as: ChatStorageUsecase)
class ChatStorageInteractorImpl extends ChatStorageUsecase {
  ChatStorageInteractorImpl(this._localRepository);

  final ChatLocalRepository _localRepository;

  @override
  Future<ChatLocalStorageSummary> getLocalStorageSummary() {
    return _localRepository.getStorageSummary();
  }

  @override
  Future<void> clearLocalStorage() {
    return _localRepository.clearAllCachedData();
  }
}
