import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/storage/local_json_store.dart';
import '../../characters/application/character_library.dart';
import '../../characters/domain/character_card.dart';
import '../domain/chat_models.dart';
import '../domain/chat_workspace.dart';
import '../domain/generation.dart';

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(ChatController.new);

class ChatState {
  const ChatState({required this.messages, required this.character, required this.sessions, this.persona = const UserPersona(), this.sessionId = 'luna-main', this.isGenerating = false, this.error, this.settings = const GenerationSettings(), this.swipeIndex = 0, this.swipeCount = 1});
  final List<ChatMessage> messages;
  final CharacterProfile character;
  final List<ChatSessionSummary> sessions;
  final UserPersona persona;
  final String sessionId;
  final bool isGenerating;
  final String? error;
  final GenerationSettings settings;
  final int swipeIndex;
  final int swipeCount;

  ChatState copyWith({List<ChatMessage>? messages, CharacterProfile? character, List<ChatSessionSummary>? sessions, UserPersona? persona, String? sessionId, bool? isGenerating, String? error, GenerationSettings? settings, int? swipeIndex, int? swipeCount, bool clearError = false}) => ChatState(
        messages: messages ?? this.messages,
        character: character ?? this.character,
        sessions: sessions ?? this.sessions,
        persona: persona ?? this.persona,
        sessionId: sessionId ?? this.sessionId,
        isGenerating: isGenerating ?? this.isGenerating,
        error: clearError ? null : error ?? this.error,
        settings: settings ?? this.settings,
        swipeIndex: swipeIndex ?? this.swipeIndex,
        swipeCount: swipeCount ?? this.swipeCount,
      );
}

class ChatController extends Notifier<ChatState> {
  final _uuid = const Uuid();
  late final CharacterProfile _luna = const CharacterProfile(id: 'luna', name: 'Luna', subtitle: '月光下的旅人', emoji: '🌙', description: '一位在旧城边缘旅行的神秘旅人。她相信每一盏灯都替某个人保留着回家的方向。');
  late final CharacterProfile _aria = const CharacterProfile(id: 'aria', name: 'Aria', subtitle: '星海观测者', emoji: '🦋', description: '来自远方观测站的记录员，习惯把每段相遇写进星图。');
  late final CharacterProfile _nova = const CharacterProfile(id: 'nova', name: 'Nova', subtitle: '温柔的实验助手', emoji: '🤖', description: '一台正在学习人类情绪的实验型助手。');

  List<ChatMessage> _lunaMessages() => [
        ChatMessage(id: _uuid.v4(), role: MessageRole.assistant, content: '夜色刚刚降临，月光像一层薄纱落在古城的屋檐上。Luna 靠在窗边，回头看向你。', createdAt: DateTime.now()),
        ChatMessage(id: _uuid.v4(), role: MessageRole.assistant, content: '“如果明天就要出发，你会带上什么？”她轻声问道，指尖轻轻敲着窗框。', createdAt: DateTime.now()),
        ChatMessage(id: _uuid.v4(), role: MessageRole.user, content: '我会带上一盏灯。不是为了照亮路，而是想让迷路的人知道，这里还有人在等他们。', createdAt: DateTime.now()),
      ];

  List<CharacterProfile> _characters() {
    final cards = ref.read(characterLibraryProvider);
    return cards.map(_profileFromCard).toList();
  }

  CharacterProfile _profileFromCard(CharacterCard card) => CharacterProfile(id: card.id, name: card.name, subtitle: card.tagline, emoji: card.avatar, avatarData: card.avatarData, description: card.description, card: card);

  CharacterProfile _characterById(String id) => _characters().firstWhere((character) => character.id == id, orElse: () => _luna);

  @override
  ChatState build() {
    _loadSessions();
    final messages = _lunaMessages();
    return ChatState(
      messages: messages,
      character: _characterById('luna'),
      sessions: [
        ChatSessionSummary(id: 'luna-main', characterId: 'luna', title: '月光下的旅人', updatedAt: DateTime.now(), preview: messages.last.content, messages: messages),
        ChatSessionSummary(id: 'luna-dawn', characterId: 'luna', title: '城门口的清晨', updatedAt: nullDate, preview: '我们在天亮前抵达了城门。', messages: const []),
        ChatSessionSummary(id: 'aria-stars', characterId: 'aria', title: '未完成的星图', updatedAt: nullDate, preview: 'Aria 还在等你补上最后一颗星。', messages: const []),
      ],
    );
  }

  static final nullDate = DateTime(2026, 8, 15, 21, 30);

  Future<void> _loadSessions() async {
    final json = await LocalJsonStore.read('chat_sessions');
    final raw = json?['sessions'];
    if (raw is! List || raw.isEmpty) return;
    final sessions = raw.whereType<Map>().map((item) => _sessionFromJson(Map<String, dynamic>.from(item))).toList();
    if (sessions.isEmpty) return;
    final current = sessions.first;
    state = state.copyWith(sessions: sessions, sessionId: current.id, character: _characterById(current.characterId), messages: current.messages, clearError: true);
  }

  void _persistSessions() {
    LocalJsonStore.write('chat_sessions', {'sessions': state.sessions.map(_sessionJson).toList()});
  }

  Map<String, dynamic> _sessionJson(ChatSessionSummary session) => {'id': session.id, 'characterId': session.characterId, 'title': session.title, 'updatedAt': session.updatedAt.toIso8601String(), 'preview': session.preview, 'messages': session.messages.map((message) => {'id': message.id, 'role': message.role.name, 'content': message.content, 'createdAt': message.createdAt.toIso8601String(), 'status': message.status.name}).toList()};

  ChatSessionSummary _sessionFromJson(Map<String, dynamic> value) => ChatSessionSummary(id: value['id'] as String? ?? _uuid.v4(), characterId: value['characterId'] as String? ?? 'luna', title: value['title'] as String? ?? '新会话', updatedAt: DateTime.tryParse(value['updatedAt'] as String? ?? '') ?? DateTime.now(), preview: value['preview'] as String? ?? '', messages: value['messages'] is List ? (value['messages'] as List).whereType<Map>().map((message) => ChatMessage(id: message['id'] as String? ?? _uuid.v4(), role: MessageRole.values.firstWhere((role) => role.name == message['role'], orElse: () => MessageRole.user), content: message['content'] as String? ?? '', createdAt: DateTime.tryParse(message['createdAt'] as String? ?? '') ?? DateTime.now(), status: MessageStatus.values.firstWhere((status) => status.name == message['status'], orElse: () => MessageStatus.complete))).toList() : const []);

  void selectSession(String id) {
    final session = state.sessions.firstWhere((item) => item.id == id);
    final messages = session.messages.isEmpty ? _lunaMessages() : session.messages;
    state = state.copyWith(sessionId: id, character: _characterById(session.characterId), messages: messages, swipeIndex: 0, swipeCount: 1, clearError: true);
    _persistSessions();
  }

  void selectCharacter(CharacterProfile character) {
    final greeting = character.card?.firstMessage.trim() ?? '';
    final messages = greeting.isEmpty ? state.messages : [ChatMessage(id: _uuid.v4(), role: MessageRole.assistant, content: greeting, createdAt: DateTime.now())];
    state = state.copyWith(character: character, messages: messages, swipeIndex: 0, swipeCount: 1, clearError: true);
  }
  void updatePersona(UserPersona persona) => state = state.copyWith(persona: persona);

  void selectGreeting(String greeting) {
    if (greeting.trim().isEmpty || state.messages.isEmpty) return;
    final firstAssistant = state.messages.indexWhere((message) => message.role == MessageRole.assistant);
    if (firstAssistant < 0) return;
    final messages = [...state.messages];
    messages[firstAssistant] = messages[firstAssistant].copyWith(content: greeting.trim());
    state = state.copyWith(messages: messages, swipeIndex: 0, swipeCount: 1);
  }

  void createSession({String? title}) {
    final id = _uuid.v4();
    final session = ChatSessionSummary(id: id, title: title?.trim().isNotEmpty == true ? title!.trim() : '新会话', updatedAt: DateTime.now(), preview: '还没有消息', messages: const []);
    state = state.copyWith(sessionId: id, sessions: [session, ...state.sessions], messages: const [], swipeIndex: 0, swipeCount: 1, clearError: true);
    _persistSessions();
  }

  void renameSession(String id, String title) {
    final clean = title.trim();
    if (clean.isEmpty) return;
    state = state.copyWith(sessions: state.sessions.map((session) => session.id == id ? session.copyWith(title: clean, updatedAt: DateTime.now()) : session).toList());
    _persistSessions();
  }

  void purgeCharacterSessions(String characterId) {
    final remaining = state.sessions.where((session) => session.characterId != characterId).toList();
    if (remaining.isEmpty) return;
    final currentRemoved = state.sessions.any((session) => session.id == state.sessionId && session.characterId == characterId);
    if (currentRemoved) {
      final next = remaining.first;
      state = state.copyWith(sessions: remaining, sessionId: next.id, character: _characterById(next.characterId), messages: next.messages, swipeIndex: 0, swipeCount: 1, clearError: true);
    } else {
      state = state.copyWith(sessions: remaining);
    }
    _persistSessions();
  }

  void deleteSession(String id) {
    if (state.sessions.length <= 1) return;
    final sessions = state.sessions.where((session) => session.id != id).toList();
    if (state.sessionId == id) {
      final next = sessions.first;
      state = state.copyWith(sessionId: next.id, sessions: sessions, messages: next.messages, swipeIndex: 0, swipeCount: 1);
      _persistSessions();
    } else {
      state = state.copyWith(sessions: sessions);
      _persistSessions();
    }
  }

  void _saveCurrentSession() {
    final updated = state.sessions.map((session) => session.id == state.sessionId ? session.copyWith(updatedAt: DateTime.now(), preview: state.messages.isEmpty ? '还没有消息' : state.messages.last.content, messages: state.messages) : session).toList();
    state = state.copyWith(sessions: updated);
  }

  void addUserMessage(String content) {
    final message = ChatMessage(id: _uuid.v4(), role: MessageRole.user, content: content, createdAt: DateTime.now());
    state = state.copyWith(messages: [...state.messages, message], swipeIndex: 0, swipeCount: 1, clearError: true);
    _saveCurrentSession();
  }

  void appendAssistantDelta(String delta) {
    if (state.messages.isNotEmpty && state.messages.last.role == MessageRole.assistant && state.messages.last.status == MessageStatus.streaming) {
      final last = state.messages.last;
      state = state.copyWith(messages: [...state.messages.take(state.messages.length - 1), last.copyWith(content: last.content + delta)]);
      _saveCurrentSession();
    } else {
      state = state.copyWith(messages: [...state.messages, ChatMessage(id: _uuid.v4(), role: MessageRole.assistant, content: delta, createdAt: DateTime.now(), status: MessageStatus.streaming)]);
      _saveCurrentSession();
    }
  }

  void finishAssistant() {
    if (state.messages.isEmpty || state.messages.last.role != MessageRole.assistant) return;
    final last = state.messages.last;
    state = state.copyWith(messages: [...state.messages.take(state.messages.length - 1), last.copyWith(status: MessageStatus.complete)], isGenerating: false, swipeIndex: 0, swipeCount: 1);
    _saveCurrentSession();
  }

  void swipeLastAssistant() {
    if (state.isGenerating || state.messages.isEmpty || state.messages.last.role != MessageRole.assistant) return;
    final current = state.messages.last;
    const alternatives = ['Luna 没有立刻回答。她把那盏灯接过去，掌心护住微弱的火光。“这样的话，天亮以前我们都不会走散。”', '她望向远处的城墙，轻轻点头。“那就出发吧。灯光会替我们记住来时的路。”'];
    final nextIndex = state.swipeCount % alternatives.length;
    state = state.copyWith(messages: [...state.messages.take(state.messages.length - 1), current.copyWith(content: alternatives[nextIndex], status: MessageStatus.complete)], swipeIndex: nextIndex + 1, swipeCount: state.swipeCount + 1);
  }

  void updateSettings(GenerationSettings settings) => state = state.copyWith(settings: settings);
  void setGenerating(bool value) => state = state.copyWith(isGenerating: value);
  void setError(String message) => state = state.copyWith(isGenerating: false, error: message);
}
