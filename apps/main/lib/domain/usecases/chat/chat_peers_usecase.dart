import 'package:data_source/data_source.dart';

/// Coordinates the locally cached chat peer list and remote peer sync.
abstract class ChatPeersUsecase {
  /// Returns peers cached on this device without contacting the backend.
  ///
  /// The current signed-in user is filtered out when local user information is
  /// available. The returned list may be stale until [syncPeers] succeeds.
  Future<List<UserModel>> getCachedPeers();

  /// Fetches chat peers from the backend and stores them in the local cache.
  ///
  /// Returns the refreshed cached peers after filtering out the current user
  /// when local user information is available.
  Future<List<UserModel>> syncPeers();
}
