import 'dart:async';

import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../../domain/entities/auth/response.dart';
import '../../../../../domain/usecases/auth/auth_usecase.dart';
import '../../../../base/base.dart';

part 'signup_bloc.freezed.dart';
part 'signup_event.dart';
part 'signup_state.dart';

@Injectable()
class SignupBloc extends AppBlocBase<SignupEvent, SignupState> {
  SignupBloc(this._authUsecase)
    : super(SignupInitial(data: const _StateData())) {
    on<SignupSubmittedEvent>(_onSignupSubmittedEvent);
  }

  final AuthUsecase _authUsecase;

  Future<void> _onSignupSubmittedEvent(
    SignupSubmittedEvent event,
    Emitter<SignupState> emit,
  ) async {
    try {
      final result = await _authUsecase.signup(
        name: event.name,
        username: event.username,
        password: event.password,
      );
      emit(state.copyWith<SignupSuccess>());
      event.completer.complete(result);
    } catch (_) {
      event.completer.complete(AuthResponse(result: LoginResultType.failed));
    }
  }
}
