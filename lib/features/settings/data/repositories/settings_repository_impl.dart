import 'dart:async';

import 'package:coffee_app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:coffee_app/features/settings/domain/entities/app_settings.dart';
import 'package:coffee_app/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _local;
  final StreamController<AppSettings> _controller;

  AppSettings? _cached;

  SettingsRepositoryImpl({
    required SettingsLocalDataSource local,
  })  : _local = local,
        _controller = StreamController<AppSettings>.broadcast();

  AppSettings _ensureCached() {
    final cached = _cached;
    if (cached != null) return cached;
    final loaded = _local.readSettings();
    _cached = loaded;
    return loaded;
  }

  @override
  Future<AppSettings> getSettings() async {
    return _ensureCached();
  }

  @override
  Stream<AppSettings> watchSettings() async* {
    yield _ensureCached();
    yield* _controller.stream;
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _cached = settings;
    await _local.writeSettings(settings);
    _controller.add(settings);
  }

  @override
  Future<void> resetToDefaults() async {
    final defaults = AppSettings.defaults();
    _cached = defaults;
    await _local.clear();
    await _local.writeSettings(defaults);
    _controller.add(defaults);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
