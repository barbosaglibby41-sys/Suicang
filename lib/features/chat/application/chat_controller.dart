import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/chat_models.dart';
import '../domain/generation.dart';

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(ChatController.new);

class ChatState {
  const ChatState({required this.messages, this.isGenerating = false, this.error});
  final List<ChatMessage> messages;
  final bool isGenerating;
  final String? error;

  ChatState copyWith({List<ChatMessage>? messages, bool? isGenerating, String? error, bool clearError = false}) => ChatState(messages: messages ?? this.messages, isGenerating: isGenerating ?? this.isGenerating, error: clearError ? null : error ?? this.error);
}

class ChatController extends Notifier<ChatState> {
  final _uuid = const Uuid();
  @override
  ChatState build() => ChatState(messages: [
    ChatMessage(id: _uuid.v4(), role: MessageRole.assistant, content: '夜色刚刚降临，月光像一层薄纱落在古城的屋檐上。Luna 靠在窗边，回头看向你。', createdAt: DateTime.now()),
    ChatMessage(id: _uuid.v4(), role: MessageRole.assistant, content: '“如果明天就要出发，你会带上什么？”她轻声问道，指尖轻轻敲着窗框。', createdAt: DateTime.now()),
    ChatMessage(id: _uuid.v4(), role: MessageRole.user, content: '我会带上一盏灯。不是为了照亮路，而是想让迷路的人知道，这里还有人在等他们。', createdAt: DateTime.now()),
  ]);

  void addUserMessage(String content) {
    final message = ChatMessage(id: _uuid.v4(), role: MessageRole.user, content: content, createdAt: DateTime.now());
    state = state.copyWith(messages: [...state.messages, message], clearError: true);
  }

  void appendAssistantDelta(String delta) {
    if (state.messages.isNotEmpty && state.messages.last.role == MessageRole.assistant && state.messages.last.status == MessageStatus.streaming) {
      final last = state.messages.last;
      state = state.copyWith(messages: [...state.messages.take(state.messages.length - 1), last.copyWith(content: last.content + delta)]);
    } else {
      state = state.copyWith(messages: [...state.messages, ChatMessage(id: _uuid.v4(), role: MessageRole.assistant, content: delta, createdAt: DateTime.now(), status: MessageStatus.streaming)]);
    }
  }

  void finishAssistant() {
    if (state.messages.isEmpty || state.messages.last.role != MessageRole.assistant) return;
    final last = state.messages.last;
    state = state.copyWith(messages: [...state.messages.take(state.messages.length - 1), last.copyWith(status: MessageStatus.complete)], isGenerating: false);
  }

  void setGenerating(bool value) => state = state.copyWith(isGenerating: value);
  void setError(String message) => state = state.copyWith(isGenerating: false, error: message);
}
