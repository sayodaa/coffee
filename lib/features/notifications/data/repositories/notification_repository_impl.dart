import 'package:coffee_app/features/notifications/domain/entities/app_notification.dart';
import 'package:coffee_app/features/notifications/domain/repositories/notification_repository.dart';

import 'package:coffee_app/features/notifications/data/datasources/local_notifications_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final LocalNotificationsDataSource _local;

  const NotificationRepositoryImpl({
    required LocalNotificationsDataSource local,
  }) : _local = local;

  @override
  Future<void> requestPermissions() async {
    await _local.initialize();
  }

  @override
  Future<void> showLocalNotification(AppNotification notification) async {
    await _local.show(
      id: notification.id.hashCode,
      title: notification.title,
      body: notification.body,
      payload: '{}',
    );
  }
}
