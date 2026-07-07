part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class LoadSettingsData extends SettingsEvent {}

class ToggleDarkMode extends SettingsEvent {
  final bool enabled;

  const ToggleDarkMode(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class ToggleLowStockAlerts extends SettingsEvent {
  final bool enabled;

  const ToggleLowStockAlerts(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class ToggleAutoBackup extends SettingsEvent {
  final bool enabled;

  const ToggleAutoBackup(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class LogoutRequested extends SettingsEvent {}