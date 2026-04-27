part of 'storage_management_bloc.dart';

abstract class StorageManagementEvent {}

class StorageManagementStartedEvent extends StorageManagementEvent {}

class StorageManagementClearRequestedEvent extends StorageManagementEvent {
  StorageManagementClearRequestedEvent(this.completer);

  final Completer<ChatLocalStorageSummary> completer;
}
