import 'dart:async';

import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../../domain/entities/chat/chat_local_storage_summary.dart';
import '../../../../../domain/usecases/chat/chat_storage_usecase.dart';
import '../../../../base/base.dart';

part 'storage_management_bloc.freezed.dart';
part 'storage_management_event.dart';
part 'storage_management_state.dart';

@Injectable()
class StorageManagementBloc
    extends AppBlocBase<StorageManagementEvent, StorageManagementState> {
  StorageManagementBloc(this._chatStorageUsecase)
    : super(StorageManagementInitial(data: _StateData.initial())) {
    on<StorageManagementStartedEvent>(_onStarted);
    on<StorageManagementClearRequestedEvent>(_onClearRequested);
  }

  final ChatStorageUsecase _chatStorageUsecase;

  Future<void> _onStarted(
    StorageManagementStartedEvent event,
    Emitter<StorageManagementState> emit,
  ) async {
    emit(state.copyWith(data: state.data.copyWith(isLoading: true)));
    try {
      final summary = await _chatStorageUsecase.getLocalStorageSummary();
      emit(
        state.copyWith<StorageManagementLoaded>(
          data: state.data.copyWith(summary: summary, isLoading: false),
        ),
      );
    } catch (_) {
      emit(state.copyWith(data: state.data.copyWith(isLoading: false)));
      rethrow;
    }
  }

  Future<void> _onClearRequested(
    StorageManagementClearRequestedEvent event,
    Emitter<StorageManagementState> emit,
  ) async {
    emit(state.copyWith(data: state.data.copyWith(isClearing: true)));
    try {
      await _chatStorageUsecase.clearLocalStorage();
      final summary = await _chatStorageUsecase.getLocalStorageSummary();
      emit(
        state.copyWith<StorageManagementLoaded>(
          data: state.data.copyWith(
            summary: summary,
            storageCleared: true,
            isClearing: false,
          ),
        ),
      );
      event.completer.complete(summary);
    } catch (error, stackTrace) {
      emit(state.copyWith(data: state.data.copyWith(isClearing: false)));
      event.completer.completeError(error, stackTrace);
      rethrow;
    }
  }
}
