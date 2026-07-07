import 'package:coffee_app/features/chat/domain/entities/message.dart';

abstract class ChatRepository {
  Future<Message> sendMessage(String message);
}
