import 'package:coffee_app/features/chat/data/datasources/gemini_service.dart';
import 'package:coffee_app/features/chat/domain/entities/message.dart';
import 'package:coffee_app/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final GeminiService _service;

  ChatRepositoryImpl(this._service);
  @override
  Future<Message> sendMessage(String text) async {
    try {
      final response = await _service.sendMessage(text);

      print('REPOSITORY RESPONSE = $response');

      return Message(
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('REPOSITORY ERROR = $e');
      throw Exception(e.toString());
    }
  }
}
