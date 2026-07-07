import 'package:coffee_app/features/reports/domain/report_models.dart';
import 'package:equatable/equatable.dart';

sealed class ReportsState extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  const ReportsState({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [startDate, endDate];
}

final class ReportsLoading extends ReportsState {
  final int requestId;

  const ReportsLoading({
    required super.startDate,
    required super.endDate,
    required this.requestId,
  });

  @override
  List<Object> get props => [...super.props, requestId];
}

final class ReportsLoaded extends ReportsState {
  final ReportData data;
  final int requestId;

  const ReportsLoaded({
    required super.startDate,
    required super.endDate,
    required this.data,
    required this.requestId,
  });

  @override
  List<Object> get props => [...super.props, data, requestId];
}

final class ReportsError extends ReportsState {
  final String message;
  final int requestId;

  const ReportsError({
    required super.startDate,
    required super.endDate,
    required this.message,
    required this.requestId,
  });

  @override
  List<Object> get props => [...super.props, message, requestId];
}
