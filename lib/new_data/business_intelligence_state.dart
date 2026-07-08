import 'business_report.dart';

/// Base state for [BusinessIntelligenceCubit].
///
/// Kept as plain classes (no `equatable`) since that package isn't a
/// confirmed dependency of the host project — swap in `Equatable` here if
/// the app already uses it elsewhere and you want value-equality rebuild
/// skipping.
abstract class BusinessIntelligenceState {
  const BusinessIntelligenceState();
}

class BusinessIntelligenceLoading extends BusinessIntelligenceState {
  const BusinessIntelligenceLoading();
}

class BusinessIntelligenceLoaded extends BusinessIntelligenceState {
  final BusinessReport report;
  final DateTime generatedAt;

  const BusinessIntelligenceLoaded({
    required this.report,
    required this.generatedAt,
  });
}

class BusinessIntelligenceError extends BusinessIntelligenceState {
  final String message;

  const BusinessIntelligenceError(this.message);
}
