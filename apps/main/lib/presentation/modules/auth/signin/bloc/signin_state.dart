// ignore_for_file: unused_element, unused_element_parameter

part of 'signin_bloc.dart';

@freezed
sealed class _StateData with _$StateData {
  const factory _StateData() = __StateData;
}

abstract class SigninState {
  SigninState(this.data);

  final _StateData data;

  T copyWith<T extends SigninState>({_StateData? data}) {
    return _factories[T == SigninState ? runtimeType : T]!(data ?? this.data);
  }
}

class SigninInitial extends SigninState {
  SigninInitial({required _StateData data}) : super(data);
}

class LoginSuccess extends SigninState {
  LoginSuccess({required _StateData data}) : super(data);
}

final _factories = <Type, Function(_StateData data)>{
  SigninInitial: (data) => SigninInitial(data: data),
  LoginSuccess: (data) => LoginSuccess(data: data),
};
