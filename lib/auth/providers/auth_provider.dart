import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  bool _loading = false;
  bool _loggedIn = false;
  String? _token;
  String? _role;
  bool _isDisposed = false;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  bool get loading => _loading;
  bool get loggedIn => _loggedIn;
  String? get token => _token;
  String? get role => _role;

  bool get isAdmin => _role?.toLowerCase() == 'admin';
  bool get isBarista => _role?.toLowerCase() == 'barista';

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> initialize() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      await _authService.initialize();
      // Ensure NO auto-login on app restart by clearing session token and role
      await _authService.logout();
      _token = null;
      _role = null;
      _loggedIn = false;
    } catch (e) {
      debugPrint('AuthProvider initialize error: $e');
      _loggedIn = false;
      _token = null;
      _role = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String inputToken, String inputRole) async {
    if (_loading) return false;
    _loading = true;
    notifyListeners();
    try {
      final success = await _authService.saveUserData(inputToken, inputRole);
      if (success) {
        _token = inputToken;
        _role = inputRole;
        _loggedIn = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AuthProvider login error: $e');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String inputToken, String inputRole) async {
    if (_loading) return false;
    _loading = true;
    notifyListeners();
    try {
      final success = await _authService.saveUserData(inputToken, inputRole);
      if (success) {
        _token = inputToken;
        _role = inputRole;
        _loggedIn = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AuthProvider register error: $e');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      await _authService.logout();
      _token = null;
      _role = null;
      _loggedIn = false;
    } catch (e) {
      debugPrint('AuthProvider logout error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      _token = _authService.getToken();
      _role = _authService.getRole();
      _loggedIn = _authService.isLoggedIn();
    } catch (e) {
      debugPrint('AuthProvider refresh error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> setRole(String newRole) async {
    if (_loading) return false;
    _loading = true;
    notifyListeners();
    try {
      if (_loggedIn && _token != null) {
        final success = await _authService.saveUserData(_token!, newRole);
        if (success) {
          _role = newRole;
          return true;
        }
      } else {
        _role = newRole;
      }
      return true;
    } catch (e) {
      debugPrint('AuthProvider setRole error: $e');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
