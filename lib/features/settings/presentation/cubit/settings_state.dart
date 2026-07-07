part of 'settings_cubit.dart';

enum SettingsStatus { loading, loaded, failure }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final AppSettings? settings;
  final String? message;

  const SettingsState._({
    required this.status,
    this.settings,
    this.message,
  });

  const SettingsState.loading() : this._(status: SettingsStatus.loading);

  const SettingsState.loaded(AppSettings settings)
      : this._(status: SettingsStatus.loaded, settings: settings);

  const SettingsState.failure(String message)
      : this._(status: SettingsStatus.failure, message: message);

  AppSettings? get settingsOrNull => settings;

  @override
  List<Object?> get props => [status, settings, message];
}
