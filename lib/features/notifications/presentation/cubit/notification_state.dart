part of 'notification_cubit.dart';

enum NotificationStatus { initial, loading, ready, failure }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final String? message;

  const NotificationState._(this.status, {this.message});

  const NotificationState.initial() : this._(NotificationStatus.initial);

  const NotificationState.loading() : this._(NotificationStatus.loading);

  const NotificationState.ready() : this._(NotificationStatus.ready);

  const NotificationState.failure(String message)
      : this._(NotificationStatus.failure, message: message);

  @override
  List<Object?> get props => [status, message];
}
