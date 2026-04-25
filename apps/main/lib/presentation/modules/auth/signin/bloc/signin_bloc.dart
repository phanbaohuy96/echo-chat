import 'dart:async';

import 'package:core/core.dart';
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
    try {
      final result = await _authUsecase.signin(
        username: event.username,
        password: event.password,
      );
      emit(state.copyWith<LoginSuccess>());
      event.completer.complete(result);
    } catch (_) {
      event.completer.complete(AuthResponse(result: LoginResultType.failed));
    }
  }
}
