// ignore_for_file: unused_element, unused_element_parameter

part of 'storage_management_bloc.dart';

@freezed
sealed class _StateData with _$StateData {
  const factory _StateData({
    ChatLocalStorageSummary? summary,
    @Default(false) bool isLoading,
    @Default(false) bool isClearing,
    @Default(false) bool storageCleared,
  }) = __StateData;

  factory _StateData.initial() => const _StateData();
}

abstract class StorageManagementState {
  StorageManagementState(this.data);

  final _StateData data;

  T copyWith<T extends StorageManagementState>({_StateData? data}) {
    return _factories[T == StorageManagementState ? runtimeType : T]!(
      data ?? this.data,
    );
  }

  ChatLocalStorageSummary? get summary => data.summary;

  bool get isLoading => data.isLoading;

  bool get isClearing => data.isClearing;

  bool get storageCleared => data.storageCleared;
}

class StorageManagementInitial extends StorageManagementState {
  StorageManagementInitial({required _StateData data}) : super(data);
}

class StorageManagementLoaded extends StorageManagementState {
  StorageManagementLoaded({required _StateData data}) : super(data);
}

final _factories = <Type, Function(_StateData data)>{
  StorageManagementInitial: (data) => StorageManagementInitial(data: data),
  StorageManagementLoaded: (data) => StorageManagementLoaded(data: data),
};
