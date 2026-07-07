import 'dart:async';

import 'package:coffee_app/features/settings/domain/entities/app_settings.dart';
import 'package:coffee_app/features/settings/domain/repositories/settings_repository.dart';

class WatchSettingsUseCase {
  final SettingsRepository _repository;

  const WatchSettingsUseCase(this._repository);

  Stream<AppSettings> call() => _repository.watchSettings();
}
