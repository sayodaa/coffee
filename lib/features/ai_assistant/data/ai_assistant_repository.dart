import 'package:coffee_app/features/ai_assistant/models/chat_message.dart';
import 'package:coffee_app/features/ai_assistant/models/conversation.dart';
import 'package:coffee_app/features/chat/data/datasources/gemini_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AiAssistantRepository {
  static const String _boxName = 'ai_conversations';
  late Box<Conversation> _conversationsBox;

  final GeminiService _aiService;

  // Constructor واحد فقط (الأساسي)
  AiAssistantRepository({GeminiService? aiService})
      : _aiService = aiService ?? GeminiService() {
    _conversationsBox = Hive.box<Conversation>(_boxName);
  }

  static const String _systemPrompt = '''You are an advanced Business Intelligence... (ضع الـ System Prompt كامل هنا)''';

  List<Conversation> getConversations() {
    final convos = _conversationsBox.values.toList();
    convos.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return convos;
  }

  Conversation? getConversation(String id) {
    return _conversationsBox.get(id);
  }

  Future<void> saveConversation(Conversation conversation) async {
    await _conversationsBox.put(conversation.id, conversation);
  }

  Future<void> deleteConversation(String id) async {
    await _conversationsBox.delete(id);
  }

  Future<Conversation> createConversation() async {
    final now = DateTime.now();
    final newConversation = Conversation(
      id: now.millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      createdAt: now,
      lastMessageAt: now,
      messages: [],
    );
    await saveConversation(newConversation);
    return newConversation;
  }

  Future<String> fetchBotResponse(List<ChatMessage> conversationMessages) async {
    final contextMessages = conversationMessages.length > 8
        ? conversationMessages.sublist(conversationMessages.length - 8)
        : conversationMessages;

    final combinedPrompt = [
      _systemPrompt,
      ...contextMessages.map((msg) => "${msg.isUser ? 'User' : 'Assistant'}: ${msg.text}")
    ].join('\n\n');

    try {
      final responseText = await _aiService.sendMessage(combinedPrompt);
      return responseText;
    } catch (e) {
      print('Error in fetchBotResponse: $e');
      throw Exception('Failed to get response from AI: $e');
    }
  }
}
