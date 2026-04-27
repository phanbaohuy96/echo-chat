// ignore_for_file: unused_element, unused_element_parameter

part of 'settings_bloc.dart';

@freezed
sealed class _StateData with _$StateData {
  const factory _StateData({
    UserModel? user,
    ChatLocalStorageSummary? storageSummary,
    @Default(false) bool storageCleared,
  }) = __StateData;

  factory _StateData.initial(UserModel? user) => _StateData(user: user);
}

abstract class SettingsState {
  SettingsState(this.data);

  final _StateData data;

  T copyWith<T extends SettingsState>({_StateData? data}) {
    return _factories[T == SettingsState ? runtimeType : T]!(data ?? this.data);
  }

  UserModel? get user => data.user;

  ChatLocalStorageSummary? get storageSummary => data.storageSummary;

  bool get storageCleared => data.storageCleared;
}

class SettingsInitial extends SettingsState {
  SettingsInitial({required _StateData data}) : super(data);
}

class SettingsLoaded extends SettingsState {
  SettingsLoaded({required _StateData data}) : super(data);
}

final _factories = <Type, Function(_StateData data)>{
  SettingsInitial: (data) => SettingsInitial(data: data),
  SettingsLoaded: (data) => SettingsLoaded(data: data),
};
