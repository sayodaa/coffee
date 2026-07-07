import 'package:coffee_app/features/settings/domain/entities/app_settings.dart';
import 'package:coffee_app/features/settings/domain/repositories/settings_repository.dart';

class GetSettingsUseCase {
  final SettingsRepository _repository;

  const GetSettingsUseCase(this._repository);

  Future<AppSettings> call() => _repository.getSettings();
}
