import 'package:flutter/material.dart';
import '../../../core/theme/suicang_theme.dart';
import '../data/context_builder.dart';
import '../domain/chat_models.dart';
import '../domain/chat_workspace.dart';
import '../domain/generation.dart';
import '../../settings/domain/preset_models.dart';

class ContextDebugSheet extends StatelessWidget {
  const ContextDebugSheet({required this.character, required this.persona, required this.history, required this.settings, required this.preset, required this.worldBooks, super.key});
  final CharacterProfile character;
  final UserPersona persona;
  final List<ChatMessage> history;
  final GenerationSettings settings;
  final PromptPreset preset;
  final List<WorldBook> worldBooks;

  @override
  Widget build(BuildContext context) {
    final inspection = ChatContextBuilder.inspect(character: character, persona: persona, history: history, preset: preset, worldBooks: worldBooks);
    return SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 6, 20, 28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('当前上下文', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 5),
      const Text('这里显示本轮实际命中的资源，和发送给模型的上下文使用同一套规则。', style: TextStyle(fontSize: 12, color: SuicangTheme.muted)),
      const SizedBox(height: 18),
      _ContextRow(icon: Icons.person_outline, title: '角色卡', value: character.name),
      _ContextRow(icon: Icons.tune_rounded, title: '预设', value: preset.name),
      _ContextRow(icon: Icons.menu_book_outlined, title: '命中条目', value: '${inspection.entries.length} 个'),
      _ContextRow(icon: Icons.badge_outlined, title: 'Persona', value: persona.name),
      const SizedBox(height: 14),
      if (inspection.entries.isEmpty) const _EmptyHit() else ...inspection.entries.map((entry) => _HitEntry(entry: entry)),
      const SizedBox(height: 14),
      ExpansionTile(title: const Text('查看最终 System Prompt', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), children: [Container(width: double.infinity, padding: const EdgeInsets.all(12), color: Theme.of(context).colorScheme.surfaceContainerHighest, child: SelectableText(inspection.systemPrompt, style: const TextStyle(fontSize: 11, height: 1.45)))]),
    ])));
  }
}

class _HitEntry extends StatelessWidget {
  const _HitEntry({required this.entry});
  final ContextEntry entry;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: SuicangTheme.line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(entry.source, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))), if (entry.constant) const _Badge(text: '常驻'), _Badge(text: entry.position)]), const SizedBox(height: 7), Text(entry.content, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.4)), if (entry.keys.isNotEmpty) ...[const SizedBox(height: 7), Text('关键词：${entry.keys.join('、')}', style: const TextStyle(fontSize: 10, color: SuicangTheme.muted))]]));
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(left: 5), padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: SuicangTheme.soft, borderRadius: BorderRadius.circular(7)), child: Text(text, style: const TextStyle(fontSize: 9, color: SuicangTheme.primary, fontWeight: FontWeight.w700)));
}

class _EmptyHit extends StatelessWidget {
  const _EmptyHit();
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: SuicangTheme.soft, borderRadius: BorderRadius.circular(14)), child: const Text('本轮没有命中可注入的世界书条目。常驻条目和关键词命中条目会显示在这里。', style: TextStyle(fontSize: 12, height: 1.4)));
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon, color: SuicangTheme.primary), title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), trailing: Text(value, style: const TextStyle(fontSize: 12, color: SuicangTheme.muted)));
}
