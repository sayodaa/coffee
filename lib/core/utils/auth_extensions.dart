import 'package:coffee_app/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Extension methods for AuthProvider to provide role-based access control.
extension AuthProviderX on AuthProvider {
  /// Checks if the current user has the specified role.
  /// Case-insensitive comparison.
  bool hasRole(String role) {
    final currentRole = this.role?.toLowerCase();
    return currentRole == role.toLowerCase();
  }

  /// Checks if the current user has any of the specified roles.
  bool hasAnyRole(List<String> roles) {
    final currentRole = this.role?.toLowerCase();
    return roles.any((role) => currentRole == role.toLowerCase());
  }

  /// Checks if the current user is an admin.
  bool get isAdmin => hasRole('admin');

  /// Checks if the current user is a worker.
  bool get isWorker => hasRole('worker');

  /// Checks if the current user is a cashier.
  bool get isCashier => hasRole('cashier');

  /// Checks if the current user is a barista.
  bool get isBarista => hasRole('barista');
}

/// Extension on BuildContext to easily access AuthProvider role checks.
extension AuthContextX on BuildContext {
  /// Gets the AuthProvider from context.
  AuthProvider get authProvider => read<AuthProvider>();

  /// Checks if the current user has the specified role.
  bool hasRole(String role) => authProvider.hasRole(role);

  /// Checks if the current user has any of the specified roles.
  bool hasAnyRole(List<String> roles) => authProvider.hasAnyRole(roles);

  /// Checks if the current user is an admin.
  bool get isAdmin => authProvider.isAdmin;

  /// Checks if the current user is a worker.
  bool get isWorker => authProvider.isWorker;

  /// Checks if the current user is a cashier.
  bool get isCashier => authProvider.isCashier;

  /// Checks if the current user is a barista.
  bool get isBarista => authProvider.isBarista;
}
