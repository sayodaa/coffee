import 'package:coffee_app/features/chat/domain/entities/message.dart';
import 'package:coffee_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:coffee_app/features/chat/presentation/bloc/chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repository;

  ChatCubit(this._repository) : super(const ChatState());

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    // Add user message immediately
    final userMessage = Message(
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<Message>.from(state.messages)
      ..add(userMessage);

    emit(state.copyWith(
      messages: updatedMessages,
      status: ChatStatus.loading,    ));

    try {
      final response = await _repository.sendMessage(text);

      final finalMessages = List<Message>.from(updatedMessages)..add(response);

      emit(state.copyWith(
        messages: finalMessages,
        status: ChatStatus.success,
      ));
    } catch (e) {
      // Strip "Exception: " prefix
      final errorMessage = e.toString().replaceAll('Exception: ', '');

      // Add error message as a bubble
      final errorBubble = Message(
        content: errorMessage,
        isUser: false,
        isError: true,
        timestamp: DateTime.now(),
      );

      final errorMessages = List<Message>.from(updatedMessages)
        ..add(errorBubble);

      emit(state.copyWith(
        messages: errorMessages,
        status: ChatStatus.failure,
        errorMessage: errorMessage,
      ));
    }
  }
}
