import 'package:coffee_app/features/settings/domain/repositories/settings_repository.dart';

class ResetSettingsUseCase {
  final SettingsRepository _repository;

  const ResetSettingsUseCase(this._repository);

  Future<void> call() => _repository.resetToDefaults();
}
