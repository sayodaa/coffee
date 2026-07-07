import 'package:shared_preferences/shared_preferences.dart';

class LowStockNotifiedLocalDataSource {
  static const String _key = 'notifications.low_stock_notified_ids';

  final SharedPreferences _prefs;

  const LowStockNotifiedLocalDataSource(this._prefs);

  Set<String> getNotifiedIds() {
    final list = _prefs.getStringList(_key) ?? const <String>[];
    return list.toSet();
  }

  Future<void> add(String productId) async {
    final current = getNotifiedIds();
    if (current.add(productId)) {
      await _prefs.setStringList(_key, current.toList());
    }
  }

  Future<void> remove(String productId) async {
    final current = getNotifiedIds();
    if (current.remove(productId)) {
      await _prefs.setStringList(_key, current.toList());
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
