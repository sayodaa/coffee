import 'package:coffee_app/features/chat/domain/entities/message.dart';
import 'package:equatable/equatable.dart';

enum ChatStatus { initial, loading, success, failure }

class ChatState extends Equatable {
  final List<Message> messages;
  final ChatStatus status;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.status = ChatStatus.initial,
    this.errorMessage,
  });

  ChatState copyWith({
    List<Message>? messages,
    ChatStatus? status,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      errorMessage: errorMessage, // Nullable intentionally
    );
  }

  @override
  List<Object?> get props => [messages, status, errorMessage];
}
