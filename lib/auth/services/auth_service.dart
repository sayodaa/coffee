import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthService {
  static const String _boxName = 'authBox';
  static const String _keyToken = 'token';
  static const String _keyRole = 'role';
  static const String _keyAdminPassword = 'adminPassword';
  static const String _defaultAdminPassword = '555555';

  Box? _box;

  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox(_boxName);
      } else {
        _box = Hive.box(_boxName);
      }

      if (_box != null && !_box!.containsKey(_keyAdminPassword)) {
        await _box!.put(_keyAdminPassword, _defaultAdminPassword);
      }
    } catch (e) {
      debugPrint('AuthService initialize error: $e');
    }
  }

  Box? get _openBox {
    if (_box != null) {
      return _box;
    }
    try {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
        return _box;
      }
    } catch (e) {
      debugPrint('AuthService openBox error: $e');
    }
    return null;
  }

  Future<bool> saveUserData(String token, String role) async {
    try {
      final box = _openBox;
      if (box == null) return false;
      await box.put(_keyToken, token);
      await box.put(_keyRole, role);
      return true;
    } catch (e) {
      debugPrint('AuthService saveUserData error: $e');
      return false;
    }
  }

  String? getToken() {
    try {
      final box = _openBox;
      return box?.get(_keyToken) as String?;
    } catch (e) {
      debugPrint('AuthService getToken error: $e');
      return null;
    }
  }

  String? getRole() {
    try {
      final box = _openBox;
      return box?.get(_keyRole) as String?;
    } catch (e) {
      debugPrint('AuthService getRole error: $e');
      return null;
    }
  }

  bool isLoggedIn() {
    try {
      final token = getToken();
      final role = getRole();
      return token != null &&
          token.isNotEmpty &&
          role != null &&
          role.isNotEmpty;
    } catch (e) {
      debugPrint('AuthService isLoggedIn error: $e');
      return false;
    }
  }

  bool verifyAdminPassword(String password) {
    try {
      final box = _openBox;
      if (box == null) return false;
      final stored = box.get(_keyAdminPassword) as String?;
      return (stored ?? _defaultAdminPassword) == password;
    } catch (e) {
      debugPrint('AuthService verifyAdminPassword error: $e');
      return false;
    }
  }

  Future<bool> changeAdminPassword(
      String oldPassword, String newPassword) async {
    try {
      if (!verifyAdminPassword(oldPassword)) {
        return false;
      }
      final box = _openBox;
      if (box == null) return false;
      await box.put(_keyAdminPassword, newPassword);
      return true;
    } catch (e) {
      debugPrint('AuthService changeAdminPassword error: $e');
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      final box = _openBox;
      if (box == null) return false;
      await box.delete(_keyToken);
      await box.delete(_keyRole);
      return true;
    } catch (e) {
      debugPrint('AuthService logout error: $e');
      return false;
    }
  }

  Future<bool> clearAll() async {
    try {
      final box = _openBox;
      if (box == null) return false;
      await box.clear();
      await box.put(_keyAdminPassword, _defaultAdminPassword);
      return true;
    } catch (e) {
      debugPrint('AuthService clearAll error: $e');
      return false;
    }
  }
}
