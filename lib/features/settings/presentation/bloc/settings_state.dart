part of 'settings_bloc.dart';

abstract class SettingsState {
  const SettingsState();
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final SettingsData data;

  const SettingsLoaded(this.data);
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);
}

class SettingsLoggedOut extends SettingsState {}