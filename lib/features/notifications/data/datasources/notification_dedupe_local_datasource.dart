import 'package:shared_preferences/shared_preferences.dart';

class NotificationDedupeLocalDataSource {
  static const String _prefix = 'notifications.processed.';

  final SharedPreferences _prefs;

  const NotificationDedupeLocalDataSource(this._prefs);

  Future<bool> isProcessed(String id) async {
    return _prefs.getBool('$_prefix$id') ?? false;
  }

  Future<void> markProcessed(String id) async {
    await _prefs.setBool('$_prefix$id', true);
  }
}
