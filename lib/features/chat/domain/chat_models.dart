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
    this.alternatives = const [],
    this.activeAlternative = 0,
  });

  final String id;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;
  final String? parentId;
  final int? tokenCount;
  final List<String> alternatives;
  final int activeAlternative;

  ChatMessage copyWith({
    String? content,
    MessageStatus? status,
    int? tokenCount,
    List<String>? alternatives,
    int? activeAlternative,
  }) => ChatMessage(
    id: id,
    role: role,
    content: content ?? this.content,
    createdAt: createdAt,
    status: status ?? this.status,
    parentId: parentId,
    tokenCount: tokenCount ?? this.tokenCount,
    alternatives: alternatives ?? this.alternatives,
    activeAlternative: activeAlternative ?? this.activeAlternative,
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
