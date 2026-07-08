import 'package:flutter_bloc/flutter_bloc.dart';

import 'business_intelligence_state.dart';
import 'sales_repository.dart';
import 'sales_analytics_service.dart';

/// Loads sales data and drives the Business Intelligence dashboard.
///
/// All heavy lifting (parsing, aggregation, alert/insight generation) lives
/// in [SalesRepository] and [SalesAnalyticsService] — this cubit only wires
/// them together and exposes the result as UI state.
class BusinessIntelligenceCubit extends Cubit<BusinessIntelligenceState> {
  final SalesRepository repository;
  final SalesAnalyticsService analyticsService;

  BusinessIntelligenceCubit({
    required this.repository,
    this.analyticsService = const SalesAnalyticsService(),
  }) : super(const BusinessIntelligenceLoading());

  Future<void> load({bool forceRefresh = false}) async {
    emit(const BusinessIntelligenceLoading());
    try {
      final records =
          await repository.getSalesRecords(forceRefresh: forceRefresh);
      final report = analyticsService.analyze(records);
      emit(BusinessIntelligenceLoaded(
        report: report,
        generatedAt: DateTime.now(),
      ));
    } catch (e) {
      emit(BusinessIntelligenceError(
        'Could not load business analytics: $e',
      ));
    }
  }

  Future<void> refresh() => load(forceRefresh: true);
}
