class Message {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  const Message({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}
