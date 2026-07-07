import 'package:coffee_app/features/ai_assistant/cubit/ai_assistant_state.dart';
import 'package:coffee_app/features/ai_assistant/cubit/ai_history_cubit.dart';
import 'package:coffee_app/features/ai_assistant/data/ai_assistant_repository.dart';
import 'package:coffee_app/features/ai_assistant/models/chat_message.dart';
import 'package:coffee_app/features/ai_assistant/models/conversation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiAssistantCubit extends Cubit<AiAssistantState> {
  final AiAssistantRepository _repository;
  final AiHistoryCubit _historyCubit; // To notify history of updates

  AiAssistantCubit({
    required AiAssistantRepository repository,
    required AiHistoryCubit historyCubit,
  })  : _repository = repository,
        _historyCubit = historyCubit,
        super(AiAssistantInitial());

  Future<void> loadOrCreateConversation(String? conversationId) async {
    emit(AiAssistantLoading());
    try {
      Conversation conversation;
      if (conversationId != null) {
        conversation = _repository.getConversation(conversationId) ??
            await _repository.createConversation();
      } else {
        conversation = await _repository.createConversation();
        _historyCubit.updateHistory(); // New chat created
      }

      // Load welcome message if completely new
      if (conversation.messages.isEmpty) {
        final welcomeMsg = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text:
              "Hello! I'm your Inventory and Sales Assistant. How can I help?",
          isUser: false,
          timestamp: DateTime.now(),
        );
        conversation = conversation.copyWith(
          messages: [welcomeMsg],
          lastMessageAt: DateTime.now(),
        );
        await _repository.saveConversation(conversation);
        _historyCubit.updateHistory();
      }
      emit(AiAssistant(conversation: conversation));
    } catch (e) {
      // Handle error gracefully, possibly showing empty state or error message
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final currentState = state;
    if (currentState is! AiAssistant) return;

    var conversation = currentState.conversation;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Auto-generate title if it's the first real user message
    String newTitle = conversation.title;
    if (conversation.title == 'New Chat' && conversation.messages.length <= 1) {
      newTitle = text.length > 25 ? '${text.substring(0, 25)}...' : text;
    }

    // Optimistic UI update
    final updatedMessages = List<ChatMessage>.from(conversation.messages)
      ..add(userMessage);
    conversation = conversation.copyWith(
      messages: updatedMessages,
      lastMessageAt: DateTime.now(),
      title: newTitle,
    );

    emit(currentState.copyWith(
        conversation: conversation, isTyping: true, clearError: true));

    await _repository.saveConversation(conversation);
    _historyCubit.updateHistory();

    try {
      // Fetch bot response passing the entire thread
      final botResponseText =
          await _repository.fetchBotResponse(conversation.messages);

      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString() + "_bot",
        text: botResponseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (state is AiAssistant) {
        final currentLoaded = state as AiAssistant;
        var activeConversation = currentLoaded.conversation;

        final finalMessages =
            List<ChatMessage>.from(activeConversation.messages)
              ..add(botMessage);
        activeConversation = activeConversation.copyWith(
          messages: finalMessages,
          lastMessageAt: DateTime.now(),
        );

        await _repository.saveConversation(activeConversation);
        _historyCubit.updateHistory();

        emit(currentLoaded.copyWith(
            conversation: activeConversation, isTyping: false));
      }
    } 
    catch (e) {
      if (state is AiAssistant) {
        emit((state as AiAssistant).copyWith(
          isTyping: false,
          error: "Failed to get response. Please try sayed again. $e",
        ));
      }
    }
  }
}
