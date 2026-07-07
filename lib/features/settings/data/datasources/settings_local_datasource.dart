import 'package:coffee_app/features/settings/data/models/app_settings_model.dart';
import 'package:coffee_app/features/settings/domain/entities/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsLocalDataSource {
  final SharedPreferences _prefs;

  const SettingsLocalDataSource(this._prefs);

  AppSettings readSettings() {
    return AppSettingsModel.fromPrimitives(
      themeModeIndex: _prefs.getInt(AppSettingsModel.themeModeKey),
      languageCode: _prefs.getString(AppSettingsModel.languageCodeKey),
      notificationsEnabled:
          _prefs.getBool(AppSettingsModel.notificationsEnabledKey),
      lowStockAlertsEnabled:
          _prefs.getBool(AppSettingsModel.lowStockAlertsEnabledKey),
      autoRefreshReportsEnabled:
          _prefs.getBool(AppSettingsModel.autoRefreshReportsEnabledKey),
      currencyCode: _prefs.getString(AppSettingsModel.currencyCodeKey),
      dataBackupEnabled:
          _prefs.getBool(AppSettingsModel.dataBackupEnabledKey),
      saleCompletedNotificationsEnabled:
          _prefs.getBool(AppSettingsModel.saleCompletedNotificationsEnabledKey),
      dailySalesSummaryEnabled:
          _prefs.getBool(AppSettingsModel.dailySalesSummaryEnabledKey),
      forecastAlertsEnabled:
          _prefs.getBool(AppSettingsModel.forecastAlertsEnabledKey),
      shopName: _prefs.getString(AppSettingsModel.shopNameKey),
    );
  }

  Future<void> writeSettings(AppSettings settings) async {
    final map = AppSettingsModel.toPrimitives(settings);

    await _prefs.setInt(
      AppSettingsModel.themeModeKey,
      map[AppSettingsModel.themeModeKey]! as int,
    );

    await _prefs.setString(
      AppSettingsModel.languageCodeKey,
      map[AppSettingsModel.languageCodeKey]! as String,
    );

    await _prefs.setBool(
      AppSettingsModel.notificationsEnabledKey,
      map[AppSettingsModel.notificationsEnabledKey]! as bool,
    );

    await _prefs.setBool(
      AppSettingsModel.lowStockAlertsEnabledKey,
      map[AppSettingsModel.lowStockAlertsEnabledKey]! as bool,
    );

    await _prefs.setBool(
      AppSettingsModel.autoRefreshReportsEnabledKey,
      map[AppSettingsModel.autoRefreshReportsEnabledKey]! as bool,
    );

    await _prefs.setString(
      AppSettingsModel.currencyCodeKey,
      map[AppSettingsModel.currencyCodeKey]! as String,
    );

    await _prefs.setBool(
      AppSettingsModel.dataBackupEnabledKey,
      map[AppSettingsModel.dataBackupEnabledKey]! as bool,
    );

    await _prefs.setBool(
      AppSettingsModel.saleCompletedNotificationsEnabledKey,
      map[AppSettingsModel.saleCompletedNotificationsEnabledKey]! as bool,
    );

    await _prefs.setBool(
      AppSettingsModel.dailySalesSummaryEnabledKey,
      map[AppSettingsModel.dailySalesSummaryEnabledKey]! as bool,
    );

    await _prefs.setBool(
      AppSettingsModel.forecastAlertsEnabledKey,
      map[AppSettingsModel.forecastAlertsEnabledKey]! as bool,
    );

    await _prefs.setString(
      AppSettingsModel.shopNameKey,
      map[AppSettingsModel.shopNameKey]! as String,
    );
  }

  Future<void> clear() async {
    await _prefs.remove(AppSettingsModel.themeModeKey);
    await _prefs.remove(AppSettingsModel.languageCodeKey);
    await _prefs.remove(AppSettingsModel.notificationsEnabledKey);
    await _prefs.remove(AppSettingsModel.lowStockAlertsEnabledKey);
    await _prefs.remove(AppSettingsModel.autoRefreshReportsEnabledKey);
    await _prefs.remove(AppSettingsModel.currencyCodeKey);
    await _prefs.remove(AppSettingsModel.dataBackupEnabledKey);
    await _prefs.remove(AppSettingsModel.saleCompletedNotificationsEnabledKey);
    await _prefs.remove(AppSettingsModel.dailySalesSummaryEnabledKey);
    await _prefs.remove(AppSettingsModel.forecastAlertsEnabledKey);
    await _prefs.remove(AppSettingsModel.shopNameKey);
  }
}
