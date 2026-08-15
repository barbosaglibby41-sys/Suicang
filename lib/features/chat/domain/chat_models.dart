enum MessageRole { system, user, assistant, tool }

enum MessageStatus { complete, streaming, failed }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = MessageStatus.complete,
    this.parentId,
    this.tokenCount,
  });

  final String id;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;
  final String? parentId;
  final int? tokenCount;

  ChatMessage copyWith({
    String? content,
    MessageStatus? status,
    int? tokenCount,
  }) =>
      ChatMessage(
        id: id,
        role: role,
        content: content ?? this.content,
        createdAt: createdAt,
        status: status ?? this.status,
        parentId: parentId,
        tokenCount: tokenCount ?? this.tokenCount,
      );
}

class ChatSession {
  const ChatSession({
    required this.id,
    required this.characterId,
    required this.title,
    required this.messages,
  });

  final String id;
  final String characterId;
  final String title;
  final List<ChatMessage> messages;
}
