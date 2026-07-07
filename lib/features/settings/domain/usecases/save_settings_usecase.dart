import 'package:coffee_app/features/settings/domain/entities/app_settings.dart';
import 'package:coffee_app/features/settings/domain/repositories/settings_repository.dart';

class SaveSettingsUseCase {
  final SettingsRepository _repository;

  const SaveSettingsUseCase(this._repository);

  Future<void> call(AppSettings settings) => _repository.saveSettings(settings);
}
