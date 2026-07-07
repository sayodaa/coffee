import 'dart:async';

import 'package:coffee_app/features/settings/domain/entities/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Stream<AppSettings> watchSettings();
  Future<void> saveSettings(AppSettings settings);
  Future<void> resetToDefaults();
}
