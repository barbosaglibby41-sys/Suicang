import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/suicang_theme.dart';
import '../application/chat_controller.dart';
import '../domain/chat_models.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() { _input.dispose(); _scroll.dispose(); super.dispose(); }

  void _send() {
    final text = _input.text.trim();
    final controller = ref.read(chatControllerProvider.notifier);
    if (text.isEmpty || ref.read(chatControllerProvider).isGenerating) return;
    controller.addUserMessage(text);
    _input.clear();
    controller.setGenerating(true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      controller.appendAssistantDelta('Luna 的眼睛亮了起来。\\n\\n“那我会记住这盏灯。”她笑了笑，推开门，清晨的风从门外涌入。');
      controller.finishAssistant();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatControllerProvider);
    return Column(children: [
      const _ChatHeader(),
      Expanded(child: ListView.builder(controller: _scroll, padding: const EdgeInsets.fromLTRB(16, 18, 16, 18), itemCount: chat.messages.length + (chat.isGenerating ? 1 : 0), itemBuilder: (_, i) => i < chat.messages.length ? _MessageTile(message: chat.messages[i]) : const _TypingTile())),
      _Composer(controller: _input, generating: chat.isGenerating, onSend: _send),
    ]);
  }
}

class _ChatHeader extends StatelessWidget { const _ChatHeader(); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(14, 9, 14, 10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: const Border(bottom: BorderSide(color: SuicangTheme.line))), child: Row(children: [IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back_ios_new, size: 18)), Container(width: 43, height: 43, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFC9B1FF), Color(0xFFF1C5D6)]), borderRadius: BorderRadius.circular(15)), child: const Center(child: Text('🌙', style: TextStyle(fontSize: 23)))), const SizedBox(width: 10), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Luna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), SizedBox(height: 3), Row(children: [Icon(Icons.circle, size: 7, color: Color(0xFF4BC48A)), SizedBox(width: 5), Text('月光下的旅人  ·  Claude', style: TextStyle(fontSize: 10, color: SuicangTheme.muted))])])), IconButton(onPressed: () {}, icon: const Icon(Icons.tune_rounded)), IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz))])); }

class _MessageTile extends StatelessWidget { const _MessageTile({required this.message}); final ChatMessage message; @override Widget build(BuildContext context) { final user = message.role == MessageRole.user; return Padding(padding: const EdgeInsets.only(bottom: 18), child: Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: user ? MainAxisAlignment.end : MainAxisAlignment.start, children: [if (!user) const _Avatar(), if (!user) const SizedBox(width: 9), Flexible(child: Column(crossAxisAlignment: user ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [Container(constraints: const BoxConstraints(maxWidth: 310), padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13), decoration: BoxDecoration(color: user ? SuicangTheme.primary : Theme.of(context).colorScheme.surface, gradient: user ? SuicangTheme.brandGradient : null, borderRadius: BorderRadius.only(topLeft: const Radius.circular(19), topRight: const Radius.circular(19), bottomLeft: Radius.circular(user ? 19 : 5), bottomRight: Radius.circular(user ? 5 : 19)), border: user ? null : Border.all(color: SuicangTheme.line), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.025), blurRadius: 10, offset: const Offset(0, 3))]), child: Text(message.content, style: TextStyle(color: user ? Colors.white : SuicangTheme.ink, height: 1.48, fontSize: 14))), const SizedBox(height: 5), Row(mainAxisSize: MainAxisSize.min, children: [Text('现在', style: const TextStyle(fontSize: 9, color: SuicangTheme.muted)), if (!user) ...[const SizedBox(width: 9), const Icon(Icons.refresh_rounded, size: 13, color: SuicangTheme.muted), const SizedBox(width: 8), const Icon(Icons.more_horiz, size: 14, color: SuicangTheme.muted)]])]))])); } }
class _Avatar extends StatelessWidget { const _Avatar(); @override Widget build(BuildContext context) => Container(width: 31, height: 31, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFC9B1FF), Color(0xFFF1C5D6)]), borderRadius: BorderRadius.circular(11)), child: const Center(child: Text('🌙', style: TextStyle(fontSize: 17)))); }
class _TypingTile extends StatelessWidget { const _TypingTile(); @override Widget build(BuildContext context) => const Row(children: [_Avatar(), SizedBox(width: 9), _TypingBubble()]); }
class _TypingBubble extends StatelessWidget { const _TypingBubble(); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: SuicangTheme.line), borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(5))), child: const SizedBox(width: 35, child: Text('•••', style: TextStyle(color: SuicangTheme.primary, fontWeight: FontWeight.bold, letterSpacing: 4)))); }

class _Composer extends StatelessWidget { const _Composer({required this.controller, required this.generating, required this.onSend}); final TextEditingController controller; final bool generating; final VoidCallback onSend; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(12, 9, 12, 10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: const Border(top: BorderSide(color: SuicangTheme.line))), child: Column(children: [Row(children: [IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline, color: SuicangTheme.muted)), const Text('角色扮演', style: TextStyle(fontSize: 11, color: SuicangTheme.muted)), const Spacer(), IconButton(onPressed: () {}, icon: const Icon(Icons.auto_awesome, size: 18, color: SuicangTheme.primary)), IconButton(onPressed: () {}, icon: const Icon(Icons.tune, size: 18, color: SuicangTheme.muted))]), Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 5, textInputAction: TextInputAction.newline, decoration: InputDecoration(hintText: generating ? 'Luna 正在思考…' : '写下你的回复…', filled: true, fillColor: SuicangTheme.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12)))), const SizedBox(width: 8), IconButton(onPressed: generating ? null : onSend, style: IconButton.styleFrom(backgroundColor: generating ? SuicangTheme.line : SuicangTheme.primary, foregroundColor: Colors.white, fixedSize: const Size(45, 45)), icon: Icon(generating ? Icons.stop_rounded : Icons.arrow_upward_rounded))]) ])); }
