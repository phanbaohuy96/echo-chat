import 'dart:async';

import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../../data/data_source/local/local_data_manager.dart';
import '../../../../../domain/entities/chat/chat_local_storage_summary.dart';
import '../../../../../domain/usecases/chat/chat_storage_usecase.dart';
import '../../../../base/base.dart';

part 'settings_bloc.freezed.dart';
part 'settings_event.dart';
part 'settings_state.dart';

@Injectable()
class SettingsBloc extends AppBlocBase<SettingsEvent, SettingsState> {
  SettingsBloc(LocalDataManager localDataManager, this._chatStorageUsecase)
    : super(
        SettingsInitial(data: _StateData.initial(localDataManager.userInfo)),
      ) {
    on<SettingsStartedEvent>(_onStarted);
    on<SettingsStorageClearedEvent>(_onStorageCleared);
    on<SettingsLogoutRequestedEvent>(_onLogoutRequested);
  }

  final ChatStorageUsecase _chatStorageUsecase;

  Future<void> _onStarted(
    SettingsStartedEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final summary = await _chatStorageUsecase.getLocalStorageSummary();
    emit(
      state.copyWith<SettingsLoaded>(
        data: state.data.copyWith(storageSummary: summary),
      ),
    );
  }

  void _onStorageCleared(
    SettingsStorageClearedEvent event,
    Emitter<SettingsState> emit,
  ) {
    emit(
      state.copyWith<SettingsLoaded>(
        data: state.data.copyWith(
          storageSummary: event.summary,
          storageCleared: true,
        ),
      ),
    );
  }

  Future<void> _onLogoutRequested(
    SettingsLogoutRequestedEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _chatStorageUsecase.clearLocalStorage();
      emit(
        state.copyWith<SettingsLoaded>(
          data: state.data.copyWith(storageCleared: true),
        ),
      );
      event.completer.complete();
    } catch (error, stackTrace) {
      event.completer.completeError(error, stackTrace);
      rethrow;
    }
  }
}
