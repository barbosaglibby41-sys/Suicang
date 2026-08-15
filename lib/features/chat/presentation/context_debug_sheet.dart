import 'package:flutter/material.dart';
import '../../../core/theme/suicang_theme.dart';
import '../../settings/domain/preset_models.dart';

class ContextDebugSheet extends StatelessWidget {
  const ContextDebugSheet({required this.characterName, required this.preset, required this.worldBooks, super.key});
  final String characterName;
  final PromptPreset preset;
  final List<WorldBook> worldBooks;

  @override
  Widget build(BuildContext context) => SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 6, 20, 28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('当前上下文', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 5), const Text('发送请求前，Suicang 会把以下资源组合成模型上下文。', style: TextStyle(fontSize: 12, color: SuicangTheme.muted)), const SizedBox(height: 18), _ContextRow(icon: Icons.person_outline, title: '角色卡', value: characterName), _ContextRow(icon: Icons.tune_rounded, title: '预设', value: preset.name), _ContextRow(icon: Icons.menu_book_outlined, title: '世界书', value: '${worldBooks.length} 本，${worldBooks.fold<int>(0, (sum, book) => sum + book.entries.length)} 个条目'), _ContextRow(icon: Icons.badge_outlined, title: 'Persona', value: '已启用'), const SizedBox(height: 10), Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: SuicangTheme.soft, borderRadius: BorderRadius.circular(14)), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline, size: 18, color: SuicangTheme.primary), SizedBox(width: 9), Expanded(child: Text('世界书中的 constant 条目始终注入；其他条目会根据最近消息中的关键词触发。', style: TextStyle(fontSize: 12, height: 1.45)))]))])));
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon, color: SuicangTheme.primary), title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), trailing: Text(value, style: const TextStyle(fontSize: 12, color: SuicangTheme.muted)));
}
