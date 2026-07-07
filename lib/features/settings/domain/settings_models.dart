class UserProfile {
  final String name;
  final String role;
  final String email;

  const UserProfile({
    required this.name,
    required this.role,
    required this.email,
  });
}

class SettingsData {
  final UserProfile userProfile;
  final bool darkMode;
  final bool lowStockAlerts;
  final bool autoBackup;
  final String appVersion;

  const SettingsData({
    required this.userProfile,
    required this.darkMode,
    required this.lowStockAlerts,
    required this.autoBackup,
    required this.appVersion,
  });

  SettingsData copyWith({
    UserProfile? userProfile,
    bool? darkMode,
    bool? lowStockAlerts,
    bool? autoBackup,
    String? appVersion,
  }) {
    return SettingsData(
      userProfile: userProfile ?? this.userProfile,
      darkMode: darkMode ?? this.darkMode,
      lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
      autoBackup: autoBackup ?? this.autoBackup,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}