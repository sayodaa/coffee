import 'package:coffee_app/features/ai_assistant/cubit/ai_history_state.dart';
import 'package:coffee_app/features/ai_assistant/data/ai_assistant_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiHistoryCubit extends Cubit<AiHistoryState> {
  final AiAssistantRepository _repository;

  AiHistoryCubit({required AiAssistantRepository repository})
      : _repository = repository,
        super(AiHistoryLoading()) {
    loadConversations();
  }

  void loadConversations() {
    try {
      emit(AiHistoryLoading()); // Emit loading state first
      final conversations = _repository.getConversations();
      emit(AiHistoryLoaded(conversations: conversations));
    } catch (e) {
      if (state is AiHistoryLoaded) {
        emit((state as AiHistoryLoaded)
            .copyWith(error: "Failed to load history: $e"));
      } else {
        // If we're in Loading state, emit error state
        emit(AiHistoryLoaded(conversations: [], error: "Failed to load history: $e"));
      }
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      await _repository.deleteConversation(id);
      loadConversations(); // Reload the list
    } catch (e) {
      if (state is AiHistoryLoaded) {
        emit(
            (state as AiHistoryLoaded).copyWith(error: "Failed to delete: $e"));
      }
    }
  }

  void updateHistory() {
    // Utility to trigger UI refresh when a chat updates
    loadConversations();
  }
}
