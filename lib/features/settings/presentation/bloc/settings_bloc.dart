import 'package:coffee_app/features/settings/domain/settings_models.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsInitial()) {
    on<LoadSettingsData>(_onLoadSettingsData);
    on<ToggleDarkMode>(_onToggleDarkMode);
    on<ToggleLowStockAlerts>(_onToggleLowStockAlerts);
    on<ToggleAutoBackup>(_onToggleAutoBackup);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoadSettingsData(
    LoadSettingsData event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock data - in real app, this would come from repository
      final settingsData = SettingsData(
        userProfile: const UserProfile(
          name: 'John Manager',
          role: 'Bar Manager',
          email: 'john.manager@barstock.com',
        ),
        darkMode: true,
        lowStockAlerts: true,
        autoBackup: false,
        appVersion: '1.0.0',
      );

      emit(SettingsLoaded(settingsData));
    } catch (e) {
      emit(SettingsError('Failed to load settings'));
    }
  }

  void _onToggleDarkMode(
    ToggleDarkMode event,
    Emitter<SettingsState> emit,
  ) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final updatedData = currentState.data.copyWith(
        darkMode: event.enabled,
      );
      emit(SettingsLoaded(updatedData));
    }
  }

  void _onToggleLowStockAlerts(
    ToggleLowStockAlerts event,
    Emitter<SettingsState> emit,
  ) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final updatedData = currentState.data.copyWith(
        lowStockAlerts: event.enabled,
      );
      emit(SettingsLoaded(updatedData));
    }
  }

  void _onToggleAutoBackup(
    ToggleAutoBackup event,
    Emitter<SettingsState> emit,
  ) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final updatedData = currentState.data.copyWith(
        autoBackup: event.enabled,
      );
      emit(SettingsLoaded(updatedData));
    }
  }

  void _onLogoutRequested(
    LogoutRequested event,
    Emitter<SettingsState> emit,
  ) {
    // In a real app, this would handle logout logic
    emit(SettingsLoggedOut());
  }
}