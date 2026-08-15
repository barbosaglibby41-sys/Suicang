import 'chat_models.dart';
import '../../characters/domain/character_card.dart';

class CharacterProfile {
  const CharacterProfile({required this.id, required this.name, required this.subtitle, required this.emoji, required this.description, this.avatarData, this.card});

  final String id;
  final String name;
  final String subtitle;
  final String emoji;
  final String? avatarData;
  final String description;
  final CharacterCard? card;
}

class UserPersona {
  const UserPersona({this.name = '旅行者', this.description = '一个带着灯穿过旧城的人。'});

  final String name;
  final String description;

  UserPersona copyWith({String? name, String? description}) => UserPersona(name: name ?? this.name, description: description ?? this.description);
}

class ChatSessionSummary {
  const ChatSessionSummary({required this.id, required this.title, required this.updatedAt, required this.preview, required this.messages, this.characterId = 'luna'});

  final String id;
  final String characterId;
  final String title;
  final DateTime updatedAt;
  final String preview;
  final List<ChatMessage> messages;

  ChatSessionSummary copyWith({String? title, DateTime? updatedAt, String? preview, List<ChatMessage>? messages, String? characterId}) => ChatSessionSummary(id: id, title: title ?? this.title, updatedAt: updatedAt ?? this.updatedAt, preview: preview ?? this.preview, messages: messages ?? this.messages, characterId: characterId ?? this.characterId);
}
