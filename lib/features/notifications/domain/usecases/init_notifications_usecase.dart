import 'package:coffee_app/features/notifications/domain/repositories/notification_repository.dart';

class InitNotificationsUseCase {
  final NotificationRepository _repository;

  const InitNotificationsUseCase(this._repository);

  Future<void> call() => _repository.requestPermissions();
}
