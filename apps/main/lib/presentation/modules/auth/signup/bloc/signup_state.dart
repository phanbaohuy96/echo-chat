// ignore_for_file: unused_element, unused_element_parameter

part of 'signup_bloc.dart';

@freezed
abstract class _StateData with _$StateData {
  const factory _StateData() = __StateData;
}

abstract class SignupState {
  SignupState(this.data);

  final _StateData data;

  T copyWith<T extends SignupState>({_StateData? data}) {
    return _factories[T == SignupState ? runtimeType : T]!(data ?? this.data);
  }
}

class SignupInitial extends SignupState {
  SignupInitial({_StateData data = const _StateData()}) : super(data);
}

class SignupSuccess extends SignupState {
  SignupSuccess({_StateData data = const _StateData()}) : super(data);
}

final _factories = <Type, Function(_StateData data)>{
  SignupInitial: (data) => SignupInitial(data: data),
  SignupSuccess: (data) => SignupSuccess(data: data),
};
