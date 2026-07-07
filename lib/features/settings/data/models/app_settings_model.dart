import 'package:coffee_app/features/settings/domain/entities/app_settings.dart';
import 'package:flutter/material.dart';

class AppSettingsModel {
  static const String themeModeKey = 'settings.theme_mode';
  static const String languageCodeKey = 'settings.language_code';
  static const String notificationsEnabledKey = 'settings.notifications_enabled';
  static const String lowStockAlertsEnabledKey =
      'settings.low_stock_alerts_enabled';
  static const String autoRefreshReportsEnabledKey =
      'settings.auto_refresh_reports_enabled';
  static const String currencyCodeKey = 'settings.currency_code';
  static const String dataBackupEnabledKey = 'settings.data_backup_enabled';
  static const String saleCompletedNotificationsEnabledKey =
      'settings.sale_completed_notifications_enabled';
  static const String dailySalesSummaryEnabledKey =
      'settings.daily_sales_summary_enabled';
  static const String forecastAlertsEnabledKey =
      'settings.forecast_alerts_enabled';
  static const String shopNameKey = 'settings.shop_name';

  final AppSettings entity;

  const AppSettingsModel(this.entity);

  static ThemeMode _themeModeFromIndex(int? index) {
    if (index == null) return AppSettings.defaults().themeMode;
    if (index < 0 || index >= ThemeMode.values.length) {
      return AppSettings.defaults().themeMode;
    }
    return ThemeMode.values[index];
  }

  static int _themeModeToIndex(ThemeMode mode) => mode.index;

  static AppSettings fromPrimitives({
    required int? themeModeIndex,
    required String? languageCode,
    required bool? notificationsEnabled,
    required bool? lowStockAlertsEnabled,
    required bool? autoRefreshReportsEnabled,
    required String? currencyCode,
    required bool? dataBackupEnabled,
    required bool? saleCompletedNotificationsEnabled,
    required bool? dailySalesSummaryEnabled,
    required bool? forecastAlertsEnabled,
    required String? shopName,
  }) {
    final defaults = AppSettings.defaults();
    return AppSettings(
      themeMode: _themeModeFromIndex(themeModeIndex),
      languageCode: languageCode ?? defaults.languageCode,
      notificationsEnabled:
          notificationsEnabled ?? defaults.notificationsEnabled,
      lowStockAlertsEnabled:
          lowStockAlertsEnabled ?? defaults.lowStockAlertsEnabled,
      autoRefreshReportsEnabled:
          autoRefreshReportsEnabled ?? defaults.autoRefreshReportsEnabled,
      currencyCode: currencyCode ?? defaults.currencyCode,
      dataBackupEnabled: dataBackupEnabled ?? defaults.dataBackupEnabled,
      saleCompletedNotificationsEnabled: saleCompletedNotificationsEnabled ??
          defaults.saleCompletedNotificationsEnabled,
      dailySalesSummaryEnabled:
          dailySalesSummaryEnabled ?? defaults.dailySalesSummaryEnabled,
      forecastAlertsEnabled:
          forecastAlertsEnabled ?? defaults.forecastAlertsEnabled,
      shopName: shopName ?? defaults.shopName,
    );
  }

  static Map<String, Object> toPrimitives(AppSettings settings) {
    return <String, Object>{
      themeModeKey: _themeModeToIndex(settings.themeMode),
      languageCodeKey: settings.languageCode,
      notificationsEnabledKey: settings.notificationsEnabled,
      lowStockAlertsEnabledKey: settings.lowStockAlertsEnabled,
      autoRefreshReportsEnabledKey: settings.autoRefreshReportsEnabled,
      currencyCodeKey: settings.currencyCode,
      dataBackupEnabledKey: settings.dataBackupEnabled,
      saleCompletedNotificationsEnabledKey:
          settings.saleCompletedNotificationsEnabled,
      dailySalesSummaryEnabledKey: settings.dailySalesSummaryEnabled,
      forecastAlertsEnabledKey: settings.forecastAlertsEnabled,
      shopNameKey: settings.shopName,
    };
  }
}
