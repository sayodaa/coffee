import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppSettings extends Equatable {
  final ThemeMode themeMode;
  final String languageCode;
  final bool notificationsEnabled;
  final bool lowStockAlertsEnabled;
  final bool autoRefreshReportsEnabled;
  final String currencyCode;
  final bool dataBackupEnabled;
  final bool saleCompletedNotificationsEnabled;
  final bool dailySalesSummaryEnabled;
  final bool forecastAlertsEnabled;
  final String shopName;

  const AppSettings({
    required this.themeMode,
    required this.languageCode,
    required this.notificationsEnabled,
    required this.lowStockAlertsEnabled,
    required this.autoRefreshReportsEnabled,
    required this.currencyCode,
    required this.dataBackupEnabled,
    required this.saleCompletedNotificationsEnabled,
    required this.dailySalesSummaryEnabled,
    required this.forecastAlertsEnabled,
    this.shopName = 'Coffee Shop',
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      themeMode: ThemeMode.dark,
      languageCode: 'en',
      notificationsEnabled: true,
      lowStockAlertsEnabled: true,
      autoRefreshReportsEnabled: true,
      currencyCode: 'USD',
      dataBackupEnabled: false,
      saleCompletedNotificationsEnabled: false,
      dailySalesSummaryEnabled: false,
      forecastAlertsEnabled: false,
      shopName: 'Coffee Shop',
    );
  }

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool? notificationsEnabled,
    bool? lowStockAlertsEnabled,
    bool? autoRefreshReportsEnabled,
    String? currencyCode,
    bool? dataBackupEnabled,
    bool? saleCompletedNotificationsEnabled,
    bool? dailySalesSummaryEnabled,
    bool? forecastAlertsEnabled,
    String? shopName,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lowStockAlertsEnabled:
          lowStockAlertsEnabled ?? this.lowStockAlertsEnabled,
      autoRefreshReportsEnabled:
          autoRefreshReportsEnabled ?? this.autoRefreshReportsEnabled,
      currencyCode: currencyCode ?? this.currencyCode,
      dataBackupEnabled: dataBackupEnabled ?? this.dataBackupEnabled,
      saleCompletedNotificationsEnabled: saleCompletedNotificationsEnabled ??
          this.saleCompletedNotificationsEnabled,
      dailySalesSummaryEnabled:
          dailySalesSummaryEnabled ?? this.dailySalesSummaryEnabled,
      forecastAlertsEnabled: forecastAlertsEnabled ?? this.forecastAlertsEnabled,
      shopName: shopName ?? this.shopName,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        languageCode,
        notificationsEnabled,
        lowStockAlertsEnabled,
        autoRefreshReportsEnabled,
        currencyCode,
        dataBackupEnabled,
        saleCompletedNotificationsEnabled,
        dailySalesSummaryEnabled,
        forecastAlertsEnabled,
        shopName,
      ];
}
