import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:coffee_app/features/settings/domain/entities/app_settings.dart';
import 'package:coffee_app/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:coffee_app/features/settings/domain/usecases/save_settings_usecase.dart';
import 'package:coffee_app/features/settings/domain/usecases/watch_settings_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetSettingsUseCase _getSettings;
  final WatchSettingsUseCase _watchSettings;
  final SaveSettingsUseCase _saveSettings;

  StreamSubscription<AppSettings>? _sub;

  SettingsCubit({
    required GetSettingsUseCase getSettings,
    required WatchSettingsUseCase watchSettings,
    required SaveSettingsUseCase saveSettings,
  })  : _getSettings = getSettings,
        _watchSettings = watchSettings,
        _saveSettings = saveSettings,
        super(const SettingsState.loading());

  Future<void> initialize() async {
    if (_sub != null) return;
    emit(const SettingsState.loading());

    try {
      final initial = await _getSettings();
      emit(SettingsState.loaded(initial));

      _sub = _watchSettings().skip(1).listen(
        (settings) {
          emit(SettingsState.loaded(settings));
        },
        onError: (e) {
          emit(SettingsState.failure(e.toString()));
        },
      );
    } catch (e) {
      emit(SettingsState.failure(e.toString()));
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final current = state.settingsOrNull;
    if (current == null) return;
    await _saveSettings(current.copyWith(themeMode: mode));
  }

  Future<void> setLanguageCode(String languageCode) async {
    final current = state.settingsOrNull;
    if (current == null) return;
    await _saveSettings(current.copyWith(languageCode: languageCode));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final current = state.settingsOrNull;
    if (current == null) return;
    await _saveSettings(current.copyWith(notificationsEnabled: enabled));
  }

  Future<void> setLowStockAlertsEnabled(bool enabled) async {
    final current = state.settingsOrNull;
    if (current == null) return;
    await _saveSettings(current.copyWith(lowStockAlertsEnabled: enabled));
  }

  Future<void> setAutoRefreshReportsEnabled(bool enabled) async {
    final current = state.settingsOrNull;
    if (current == null) return;
    await _saveSettings(current.copyWith(autoRefreshReportsEnabled: enabled));
  }

  Future<void> setCurrencyCode(String currencyCode) async {
    final current = state.settingsOrNull;
    if (current == null) return;
    await _saveSettings(current.copyWith(currencyCode: currencyCode));
  }

  Future<void> setDataBackupEnabled(bool enabled) async {
    final current = state.settingsOrNull;
    if (current == null) return;
    await _saveSettings(current.copyWith(dataBackupEnabled: enabled));
  }

  Future<void> setSaleCompletedNotificationsEnabled(bool enabled) async {
    final current = state.settingsOrNull;
    if (current == null) return;
    await _saveSettings(
      current.copyWith(saleCompletedNotificationsEnabled: enabled),
    );
  }

  Future<void> setDailySalesSummaryEnabled(bool enabled) async {
    final current = state.settingsOrNull;
    if (current == null) return;
    await _saveSettings(current.copyWith(dailySalesSummaryEnabled: enabled));
  }

  Future<void> setForecastAlertsEnabled(bool enabled) async {
    final current = state.settingsOrNull;
    if (current == null) return;
    await _saveSettings(current.copyWith(forecastAlertsEnabled: enabled));
  }

  Future<void> setShopName(String name) async {
    final current = state.settingsOrNull;
    if (current == null) return;
    await _saveSettings(current.copyWith(shopName: name.trim().isEmpty ? 'Coffee Shop' : name.trim()));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
