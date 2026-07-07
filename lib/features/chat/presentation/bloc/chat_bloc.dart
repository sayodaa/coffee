// import 'package:coffee_app/features/chat/domain/entities/message.dart';
// import 'package:coffee_app/features/chat/domain/repositories/chat_repository.dart';
// import 'package:coffee_app/features/chat/presentation/bloc/chat_event.dart';
// import 'package:coffee_app/features/chat/presentation/bloc/chat_state.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class ChatBloc extends Bloc<ChatEvent, ChatState> {
//   final ChatRepository _repository;

//   ChatBloc(this._repository) : super(const ChatState()) {
//     on<SendMessage>(_onSendMessage);
//   }

//   Future<void> _onSendMessage(
//     SendMessage event,
//     Emitter<ChatState> emit,
//   ) async {
//     if (event.text.isEmpty) return;

//     // Add user message immediately
//     final userMessage = Message(
//       content: event.text,
//       isUser: true,
//       timestamp: DateTime.now(),
//     );

//     final updatedMessages = List<Message>.from(state.messages)
//       ..add(userMessage);

//     emit(state.copyWith(
//       messages: updatedMessages,
//       status: ChatStatus.loading,
//     ));

//     try {
//       final response = await _repository.sendMessage(event.text);

//       final finalMessages = List<Message>.from(updatedMessages)..add(response);

//       emit(state.copyWith(
//         messages: finalMessages,
//         status: ChatStatus.success,
//       ));
//     } catch (e) {
//       emit(state.copyWith(
//         status: ChatStatus.failure,
//         errorMessage: e.toString(),
//       ));
//     }
//   }
// }
