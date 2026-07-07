import 'package:coffee_app/features/notifications/domain/entities/app_notification.dart';
import 'package:coffee_app/features/notifications/domain/repositories/notification_repository.dart';

class ShowLocalNotificationUseCase {
  final NotificationRepository _repository;

  const ShowLocalNotificationUseCase(this._repository);

  Future<void> call(AppNotification notification) {
    return _repository.showLocalNotification(notification);
  }
}
