import 'package:coffee_app/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationRepository {
  Future<void> requestPermissions();
  Future<void> showLocalNotification(AppNotification notification);
}
