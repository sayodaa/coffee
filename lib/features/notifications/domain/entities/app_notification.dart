import 'package:coffee_app/features/notifications/domain/entities/notification_type.dart';
import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.data,
  });

  @override
  List<Object?> get props => [id, type, title, body, createdAt, data];
}
