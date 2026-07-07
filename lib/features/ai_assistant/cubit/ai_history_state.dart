import 'package:coffee_app/features/ai_assistant/models/conversation.dart';

abstract class AiHistoryState {}

class AiHistoryInitial extends AiHistoryState {}

class AiHistoryLoading extends AiHistoryState {}

class AiHistoryLoaded extends AiHistoryState {
  final List<Conversation> conversations;
  final String? error;

  AiHistoryLoaded({
    required this.conversations,
    this.error,
  });

  AiHistoryLoaded copyWith({
    List<Conversation>? conversations,
    String? error,
    bool clearError = false,
  }) {
    return AiHistoryLoaded(
      conversations: conversations ?? this.conversations,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
