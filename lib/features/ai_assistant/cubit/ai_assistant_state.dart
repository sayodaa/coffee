import 'package:coffee_app/features/ai_assistant/models/conversation.dart';

abstract class AiAssistantState {}

class AiAssistantInitial extends AiAssistantState {}

class AiAssistantLoading extends AiAssistantState {}

class AiAssistant extends AiAssistantState {
  final Conversation conversation;
  final bool isTyping;
  final String? error;

  AiAssistant({
    required this.conversation,
    this.isTyping = false,
    this.error,
  });

  AiAssistant copyWith({
    Conversation? conversation,
    bool? isTyping,
    String? error,
    bool clearError = false,
  }) {
    return AiAssistant(
      conversation: conversation ?? this.conversation,
      isTyping: isTyping ?? this.isTyping,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
