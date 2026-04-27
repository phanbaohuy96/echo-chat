part of 'settings_bloc.dart';

abstract class SettingsEvent {}

class SettingsStartedEvent extends SettingsEvent {}

class SettingsStorageClearedEvent extends SettingsEvent {
  SettingsStorageClearedEvent(this.summary);

  final ChatLocalStorageSummary summary;
}

class SettingsLogoutRequestedEvent extends SettingsEvent {
  SettingsLogoutRequestedEvent(this.completer);

  final Completer<void> completer;
}
