import 'dart:async';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../../domain/entities/auth/response.dart';
import '../../../../../domain/usecases/auth/auth_usecase.dart';
import '../../../../base/base.dart';

part 'signin_bloc.freezed.dart';
part 'signin_event.dart';
part 'signin_state.dart';

@Injectable()
class SigninBloc extends AppBlocBase<SigninEvent, SigninState> {
  final AuthUsecase _authUsecase;

  SigninBloc(this._authUsecase)
    : super(SigninInitial(data: const _StateData())) {
    on<LoginEvent>(_onLoginEvent);
  }

  Future<void> _onLoginEvent(
    LoginEvent event,
    Emitter<SigninState> emit,
  ) async {
    showLoading();
    try {
      final result = await _authUsecase.signin(
        username: event.username,
        password: event.password,
      );
      emit(state.copyWith<LoginSuccess>());
      event.completer.complete(result);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        event.completer.complete(AuthResponse(result: LoginResultType.failed));
        return;
      }
      event.completer.completeError(error, error.stackTrace);
      rethrow;
    } finally {
      hideLoading();
    }
  }
}
