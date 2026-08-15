import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/suicang_theme.dart';
import '../data/context_builder.dart';
import '../data/openai_compatible_provider.dart';
import '../../settings/application/provider_config.dart';
import '../../settings/application/resource_library.dart';
import '../../characters/application/character_library.dart';
import '../application/chat_controller.dart';
import '../domain/chat_models.dart';
import '../domain/generation.dart';
import '../domain/chat_workspace.dart';
import 'generation_sheet.dart';
import 'workspace_sheet.dart';
import 'context_debug_sheet.dart';
import 'generation_error.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _openWorkspace() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => WorkspaceSheet(
        state: ref.read(chatControllerProvider),
        characters: ref.read(characterLibraryProvider),
        onSessionSelected: (id) {
          ref.read(chatControllerProvider.notifier).selectSession(id);
          Navigator.pop(context);
        },
        onCharacterSelected: (character) => ref.read(chatControllerProvider.notifier).selectCharacter(character),
        onPersonaChanged: (persona) => ref.read(chatControllerProvider.notifier).updatePersona(persona),
        onGreetingSelected: (greeting) => ref.read(chatControllerProvider.notifier).selectGreeting(greeting),
        onNewSession: () { ref.read(chatControllerProvider.notifier).createSession(); Navigator.pop(context); },
        onRenameSession: (id, title) => ref.read(chatControllerProvider.notifier).renameSession(id, title),
        onDeleteSession: (id) => ref.read(chatControllerProvider.notifier).deleteSession(id),
      ),
    );
  }

  void _openGenerationSettings() {
    final settings = ref.read(chatControllerProvider).settings;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => GenerationSheet(
        settings: settings,
        onChanged: (next) => ref.read(chatControllerProvider.notifier).updateSettings(next),
      ),
    );
  }

  void _openContextDebug(ChatState chat) {
    final resources = ref.read(resourceLibraryProvider);
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => ContextDebugSheet(characterName: chat.character.name, preset: resources.preset, worldBooks: resources.worldBooks));
  }

  Future<void> _send({String? retryText}) async {
    final text = (retryText ?? _input.text).trim();
    final chat = ref.read(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);
    if (text.isEmpty || chat.isGenerating) return;
    if (retryText == null) {
      controller.addUserMessage(text);
      _input.clear();
    }
    controller.setGenerating(true);
    final requestChat = ref.read(chatControllerProvider);

    final providerConfig = ref.read(providerConfigProvider);
    final resources = ref.read(resourceLibraryProvider);
    if (!providerConfig.isReady) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      controller.appendAssistantDelta('Luna 的眼睛亮了起来。\n\n“那我会记住这盏灯。”她笑了笑，推开门，清晨的风从门外涌入。');
      controller.finishAssistant();
      return;
    }

    final request = ChatContextBuilder.build(character: requestChat.character, persona: requestChat.persona, history: requestChat.messages, settings: requestChat.settings.copyWith(model: providerConfig.model), preset: resources.preset, worldBooks: resources.worldBooks);
    final provider = OpenAiCompatibleProvider(baseUrl: providerConfig.baseUrl, apiKey: providerConfig.apiKey);
    try {
      await for (final event in provider.generate(request)) {
        if (!mounted) return;
        if (event is TextDelta) controller.appendAssistantDelta(event.text);
        if (event is GenerationCompleted) controller.finishAssistant();
        if (event is GenerationFailed) controller.setError(event.message);
      }
      if (ref.read(chatControllerProvider).isGenerating) controller.finishAssistant();
    } catch (error) {
      controller.setError('生成失败：$error');
    }
  }

  String? _lastUserText(List<ChatMessage> messages) {
    for (final message in messages.reversed) {
      if (message.role == MessageRole.user) return message.content;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);
    final lastAssistantIndex = chat.messages.lastIndexWhere((message) => message.role == MessageRole.assistant);
    final messageItems = <Widget>[
      const _DateDivider(),
      for (var index = 0; index < chat.messages.length; index++)
        _MessageTile(
          message: chat.messages[index],
          avatar: chat.character.emoji,
          avatarData: chat.character.avatarData,
          swipeIndex: index == lastAssistantIndex ? chat.swipeIndex : 0,
          swipeCount: index == lastAssistantIndex ? chat.swipeCount : 1,
          onSwipe: index == lastAssistantIndex ? controller.swipeLastAssistant : null,
        ),
      if (chat.isGenerating) const _TypingTile() else if (chat.error != null) GenerationErrorCard(message: chat.error!, onRetry: () => _send(retryText: _lastUserText(chat.messages))) else const _ConversationEnd(),
      const SizedBox(height: 8),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _ChatHeader(character: chat.character, onSettings: _openGenerationSettings, onWorkspace: _openWorkspace, onContext: () => _openContextDebug(chat)),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth > 900 ? 760.0 : double.infinity;
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: maxWidth,
                    child: ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                      children: messageItems,
                    ),
                  ),
                );
              },
            ),
          ),
          _Composer(controller: _input, generating: chat.isGenerating, onSend: _send),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.character, required this.onSettings, required this.onWorkspace, required this.onContext});
  final CharacterProfile character;
  final VoidCallback onSettings;
  final VoidCallback onWorkspace;
  final VoidCallback onContext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = scheme.surface;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: '返回',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          _CharacterAvatar(size: 43, emoji: character.emoji, avatarData: character.avatarData),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(character.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle, size: 7, color: Color(0xFF4BC48A)),
                    SizedBox(width: 5),
                    Text(character.subtitle, style: TextStyle(fontSize: 10, color: SuicangTheme.muted)),
                    Text('  ·  Claude', style: TextStyle(fontSize: 10, color: SuicangTheme.muted)),
                  ],
                ),
              ],
            ),
          ),
          _HeaderIcon(icon: Icons.visibility_outlined, tooltip: '查看上下文', onPressed: onContext),
          _HeaderIcon(icon: Icons.tune_rounded, tooltip: '生成设置', onPressed: onSettings),
          _HeaderIcon(icon: Icons.more_horiz, tooltip: '会话与角色', onPressed: onWorkspace),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: SuicangTheme.muted),
      );
}

class _DateDivider extends StatelessWidget {
  const _DateDivider();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            const Expanded(child: Divider(color: SuicangTheme.line)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('今晚  ·  22:18', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: SuicangTheme.muted)),
            ),
            const Expanded(child: Divider(color: SuicangTheme.line)),
          ],
        ),
      );
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message, required this.avatar, this.avatarData, this.swipeIndex = 0, this.swipeCount = 1, this.onSwipe});
  final ChatMessage message;
  final String avatar;
  final String? avatarData;
  final int swipeIndex;
  final int swipeCount;
  final VoidCallback? onSwipe;

  @override
  Widget build(BuildContext context) {
    final user = message.role == MessageRole.user;
    final scheme = Theme.of(context).colorScheme;
    final surface = scheme.surface;
    final bubbleText = scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: user ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!user) ...[_CharacterAvatar(size: 31, emoji: ref.read(chatControllerProvider).character.emoji, avatarData: ref.read(chatControllerProvider).character.avatarData), const SizedBox(width: 9)],
          Flexible(
            child: Column(
              crossAxisAlignment: user ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: user ? SuicangTheme.primary : surface,
                    gradient: user ? SuicangTheme.brandGradient : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(19),
                      topRight: const Radius.circular(19),
                      bottomLeft: Radius.circular(user ? 19 : 5),
                      bottomRight: Radius.circular(user ? 5 : 19),
                    ),
                    border: user ? null : Border.all(color: scheme.outlineVariant),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.025), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: SelectableText(
                    message.content,
                    style: TextStyle(color: user ? Colors.white : bubbleText, height: 1.52, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('刚刚', style: const TextStyle(fontSize: 9, color: SuicangTheme.muted)),
                    if (!user) ...[
                      const SizedBox(width: 10),
                      if (onSwipe != null) ...[
                        _MessageAction(icon: Icons.chevron_left_rounded, tooltip: '上一条', onPressed: onSwipe),
                        Text('${swipeIndex + 1}/$swipeCount', style: const TextStyle(fontSize: 10, color: SuicangTheme.muted)),
                        _MessageAction(icon: Icons.chevron_right_rounded, tooltip: '下一条', onPressed: onSwipe),
                      ],
                      _MessageAction(icon: Icons.copy_outlined, tooltip: '复制'),
                      _MessageAction(icon: Icons.refresh_rounded, tooltip: '重新生成', onPressed: onSwipe),
                      _MessageAction(icon: Icons.more_horiz, tooltip: '更多'),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageAction extends StatelessWidget {
  const _MessageAction({required this.icon, required this.tooltip, this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onPressed ?? () {},
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        constraints: const BoxConstraints(minWidth: 24, minHeight: 22),
        icon: Icon(icon, size: 14, color: SuicangTheme.muted),
      );
}

class _CharacterAvatar extends StatelessWidget {
  const _CharacterAvatar({required this.size, this.emoji = '🌙', this.avatarData});
  final double size;
  final String emoji;
  final String? avatarData;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFC9B1FF), Color(0xFFF1C5D6)]),
          borderRadius: BorderRadius.circular(size * .32),
        ),
        child: avatarData == null ? Center(child: Text(emoji, style: TextStyle(fontSize: size * .42))) : ClipRRect(borderRadius: BorderRadius.circular(size * .32), child: Image.memory(base64Decode(avatarData!), fit: BoxFit.cover)),
      );
}

class _TypingTile extends StatelessWidget {
  const _TypingTile();

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CharacterAvatar(size: 31),
          const SizedBox(width: 9),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 18, 13),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: SuicangTheme.line),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(5)),
            ),
            child: const Row(children: [Text('Luna 正在思考', style: TextStyle(fontSize: 11, color: SuicangTheme.muted)), SizedBox(width: 8), _PulseDots()]),
          ),
        ],
      );
}

class _PulseDots extends StatelessWidget {
  const _PulseDots();

  @override
  Widget build(BuildContext context) => const Text('•••', style: TextStyle(color: SuicangTheme.primary, fontWeight: FontWeight.bold, letterSpacing: 2));
}

class _ConversationEnd extends StatelessWidget {
  const _ConversationEnd();

  @override
  Widget build(BuildContext context) => Center(
        child: Text('已同步到当前会话', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: SuicangTheme.muted)),
      );
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.generating, required this.onSend});
  final TextEditingController controller;
  final bool generating;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = scheme.surface;
    final fieldFill = scheme.surfaceContainerHighest;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(color: surface, border: Border(top: BorderSide(color: scheme.outlineVariant))),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              height: 32,
              child: Row(
                children: [
                  const _ModeChip(icon: Icons.auto_awesome, label: '角色扮演'),
                  const SizedBox(width: 8),
                  _ToolButton(icon: Icons.attach_file_rounded, tooltip: '添加附件'),
                  _ToolButton(icon: Icons.image_outlined, tooltip: '添加图片'),
                  const Spacer(),
                  const Text('上下文  4.2k', style: TextStyle(fontSize: 10, color: SuicangTheme.muted)),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: generating ? 'Luna 正在思考…' : '写下你的回复…',
                      hintStyle: const TextStyle(fontSize: 13, color: SuicangTheme.muted),
                      filled: true,
                      fillColor: fieldFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: generating ? '停止生成' : '发送',
                  onPressed: generating ? () {} : onSend,
                  style: IconButton.styleFrom(backgroundColor: generating ? SuicangTheme.line : SuicangTheme.primary, foregroundColor: Colors.white, fixedSize: const Size(46, 46)),
                  icon: Icon(generating ? Icons.stop_rounded : Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: SuicangTheme.soft, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: SuicangTheme.primary), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 10, color: SuicangTheme.primary, fontWeight: FontWeight.w700))]),
      );
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.tooltip});
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: () {},
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 18, color: SuicangTheme.muted),
      );
}
