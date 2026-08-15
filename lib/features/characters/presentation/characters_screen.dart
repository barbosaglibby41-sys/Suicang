import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/character_library.dart';
import '../../chat/application/chat_controller.dart';
import '../../../core/theme/suicang_theme.dart';
import '../../../core/storage/local_json_store.dart';
import '../data/character_card_parser.dart';
import '../data/character_card_exporter.dart';
import '../domain/character_card.dart';
import '../../../features/settings/data/preset_parser.dart';

class CharactersScreen extends ConsumerStatefulWidget {
  const CharactersScreen({super.key});

  @override
  ConsumerState<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends ConsumerState<CharactersScreen> {
  final _search = TextEditingController();
  String _filter = '全部';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final characters = ref.watch(characterLibraryProvider);
    final query = _search.text.trim().toLowerCase();
    final visible = characters.where((character) {
      final matchesQuery = query.isEmpty || character.name.toLowerCase().contains(query) || character.tagline.toLowerCase().contains(query);
      final matchesFilter = _filter == '全部' || character.tags.contains(_filter);
      return matchesQuery && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _CharactersHero(onImport: _showImportOptions)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SearchBar(controller: _search, onChanged: (_) => setState(() {})),
                const SizedBox(height: 16),
                _FilterRow(selected: _filter, onSelected: (value) => setState(() => _filter = value)),
                const SizedBox(height: 22),
                Row(children: [const Text('我的角色', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const Spacer(), Text('${visible.length} 张角色卡', style: const TextStyle(fontSize: 11, color: SuicangTheme.muted))]),
                const SizedBox(height: 12),
                LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth > 760 ? 3 : 2;
                  return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: visible.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .9), itemBuilder: (_, index) => _CharacterCard(character: visible[index], onTap: () => _openCard(visible[index])));
                }),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showImportOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('导入社区资源', style: TextStyle(fontWeight: FontWeight.w800))),
            ListTile(leading: const Icon(Icons.image_outlined), title: const Text('PNG 角色卡'), subtitle: const Text('读取 Tavern Card V1 / V2 元数据'), onTap: () { Navigator.pop(context); _pickCharacterFile(['png']); }),
            ListTile(leading: const Icon(Icons.data_object), title: const Text('JSON 角色卡'), subtitle: const Text('兼容 character card JSON 格式'), onTap: () { Navigator.pop(context); _pickCharacterFile(['json']); }),
            ListTile(leading: const Icon(Icons.menu_book_outlined), title: const Text('世界书 / Lorebook'), subtitle: const Text('导入 SillyTavern 世界书条目'), onTap: () { Navigator.pop(context); _pickWorldBook(); }),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCharacterFile(List<String> extensions) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: extensions, withData: true);
    if (!mounted || result == null || result.files.single.bytes == null) return;
    try {
      final file = result.files.single;
      final bytes = Uint8List.fromList(file.bytes!);
      final card = extensions.first == 'png' ? CharacterCardParser.fromPng(bytes, sourceName: file.name) : CharacterCardParser.fromJsonText(utf8.decode(bytes), sourceName: file.name);
      ref.read(characterLibraryProvider.notifier).upsert(card);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导入「${card.name}」角色卡')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败：$error')));
    }
  }

  Future<void> _pickWorldBook() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
    if (!mounted || result == null || result.files.single.bytes == null) return;
    try {
      final file = result.files.single;
      final book = PresetParser.fromJsonTextAsWorldBook(utf8.decode(file.bytes!), sourceName: file.name);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已读取世界书「${book.name}」，包含 ${book.entries.length} 个条目')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('世界书导入失败：$error')));
    }
  }

  void _openCard(CharacterCard character) {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => _CharacterDetail(card: character, onSave: (next) => ref.read(characterLibraryProvider.notifier).upsert(next), onDelete: () { ref.read(chatControllerProvider.notifier).purgeCharacterSessions(character.id); ref.read(characterLibraryProvider.notifier).remove(character.id); }));
  }
}

class _CharactersHero extends StatelessWidget {
  const _CharactersHero({required this.onImport});
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), decoration: const BoxDecoration(gradient: SuicangTheme.heroGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))), child: SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('角色工作台', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('导入社区角色，保留完整 SillyTavern 能力', style: TextStyle(color: Colors.white70, fontSize: 12))])), FilledButton.icon(onPressed: onImport, icon: const Icon(Icons.file_upload_outlined, size: 17), label: const Text('导入'), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: SuicangTheme.primary))]), const SizedBox(height: 20), Row(children: [_HeroStat(value: '12', label: '角色卡'), _HeroStat(value: '08', label: '最近使用'), _HeroStat(value: '04', label: '世界书')])])));
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10))]));
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextField(controller: controller, onChanged: onChanged, decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: '搜索角色名称、标签或来源', suffixIcon: controller.text.isEmpty ? null : IconButton(onPressed: () { controller.clear(); onChanged(''); }, icon: const Icon(Icons.close)), filled: true, fillColor: Theme.of(context).colorScheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: SuicangTheme.line))));
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['全部', '幻想', '科幻', '陪伴', '创作'].map((item) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(item), selected: item == selected, onSelected: (_) => onSelected(item))).toList()));
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.character, required this.onTap});
  final CharacterCard character;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Ink(decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: SuicangTheme.line)), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 92, width: double.infinity, decoration: BoxDecoration(gradient: SuicangTheme.brandGradient, borderRadius: BorderRadius.circular(16)), child: character.avatarData == null ? Center(child: Text(character.avatar, style: const TextStyle(fontSize: 44))) : ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(base64Decode(character.avatarData!), fit: BoxFit.cover))), const SizedBox(height: 12), Text(character.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(character.tagline, style: const TextStyle(fontSize: 11, color: SuicangTheme.muted)), const Spacer(), Text(character.source, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: SuicangTheme.primary, fontWeight: FontWeight.w700))])));
}

class _CharacterDetail extends StatefulWidget {
  const _CharacterDetail({required this.card, required this.onSave, required this.onDelete});
  final CharacterCard card;
  final ValueChanged<CharacterCard> onSave;
  final VoidCallback onDelete;

  @override
  State<_CharacterDetail> createState() => _CharacterDetailState();
}

class _CharacterDetailState extends State<_CharacterDetail> {
  late final _name = TextEditingController(text: widget.card.name);
  late final _tagline = TextEditingController(text: widget.card.tagline);
  late final _description = TextEditingController(text: widget.card.description);
  late final _personality = TextEditingController(text: widget.card.personality);
  late final _scenario = TextEditingController(text: widget.card.scenario);
  late final _firstMessage = TextEditingController(text: widget.card.firstMessage);
  late final _exampleMessages = TextEditingController(text: widget.card.exampleMessages);
  late final _systemPrompt = TextEditingController(text: widget.card.systemPrompt);
  late final _postHistory = TextEditingController(text: widget.card.postHistoryInstructions);
  late final _creatorNotes = TextEditingController(text: widget.card.creatorNotes);
  late final _greeting = TextEditingController();
  late List<String> _greetings = [...widget.card.alternateGreetings];
  late List<WorldBookEntry> _entries = [...?widget.card.characterBook?.entries];

  @override
  void dispose() { for (final controller in [_name, _tagline, _description, _personality, _scenario, _firstMessage, _exampleMessages, _systemPrompt, _postHistory, _creatorNotes, _greeting]) { controller.dispose(); } super.dispose(); }

  @override
  Widget build(BuildContext context) => SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _EditorHero(card: widget.card, onExport: _export),
        const SizedBox(height: 18),
        _EditorSection(icon: Icons.badge_outlined, title: '基础资料', subtitle: '角色在工作区中显示的身份信息', children: [_Field(controller: _name, label: '角色名称'), _Field(controller: _tagline, label: '副标题'), _Field(controller: _description, label: '角色描述', maxLines: 4)]),
        _EditorSection(icon: Icons.psychology_outlined, title: '角色行为', subtitle: '这些字段会进入生成上下文', children: [_Field(controller: _personality, label: 'Personality', maxLines: 3), _Field(controller: _scenario, label: 'Scenario', maxLines: 3), _Field(controller: _systemPrompt, label: 'System Prompt', maxLines: 4), _Field(controller: _postHistory, label: 'Post History Instructions', maxLines: 3), _Field(controller: _creatorNotes, label: 'Creator Notes', maxLines: 3)]),
        _EditorSection(icon: Icons.waving_hand_outlined, title: '开场体验', subtitle: '兼容 First Message、Example Messages 和 Alternate Greetings', children: [_Field(controller: _firstMessage, label: 'First Message', maxLines: 5), _Field(controller: _exampleMessages, label: 'Example Messages', maxLines: 5), _GreetingEditor(greetings: _greetings, controller: _greeting, onChanged: (value) => setState(() => _greetings = value))]),
        _EditorSection(icon: Icons.menu_book_outlined, title: 'Character Book', subtitle: '可按关键词注入的角色专属世界书', children: [Row(children: [Expanded(child: Text('${_entries.length} 个条目', style: const TextStyle(fontWeight: FontWeight.w700))), OutlinedButton.icon(onPressed: _addEntry, icon: const Icon(Icons.add, size: 16), label: const Text('添加'))]), if (_entries.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('暂无角色世界书条目', style: TextStyle(fontSize: 12, color: SuicangTheme.muted))), ReorderableListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _entries.length, onReorder: (oldIndex, newIndex) { setState(() { if (newIndex > oldIndex) newIndex -= 1; final entry = _entries.removeAt(oldIndex); _entries.insert(newIndex, entry); }); }, itemBuilder: (_, index) => _BookEntryEditor(key: ValueKey(_entries[index].id), entry: _entries[index], onChanged: (entry) => setState(() => _entries[index] = entry), onDelete: () => setState(() => _entries.removeAt(index)))]),
        const SizedBox(height: 6),
        Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () { widget.onDelete(); Navigator.pop(context); }, icon: const Icon(Icons.delete_outline), label: const Text('删除'))), const SizedBox(width: 10), Expanded(child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('保存')))]),
      ]));

  Future<void> _export() async {
    final json = CharacterCardExporter.toJsonText(widget.card);
    await Clipboard.setData(ClipboardData(text: json));
    final jsonFile = await LocalJsonStore.writeText('export_${widget.card.id}', json);
    var message = 'JSON 已复制，并保存到应用文档导出目录';
    try {
      final png = CharacterCardExporter.toPngCard(widget.card);
      await LocalJsonStore.writeBytes('export_${widget.card.id}', png, extension: 'png');
      message = 'JSON 与 PNG V2 角色卡已保存到应用文档导出目录';
    } on FormatException {
      message = 'JSON 已保存；该角色没有原始 PNG，无法生成 PNG V2';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _addEntry() => setState(() => _entries.add(WorldBookEntry(id: DateTime.now().microsecondsSinceEpoch.toString(), keys: const [], content: '')));

  void _save() {
    final book = _entries.isEmpty ? null : CharacterBook(name: widget.card.characterBook?.name ?? 'Character Book', entries: _entries);
    widget.onSave(widget.card.copyWith(name: _name.text.trim(), tagline: _tagline.text.trim(), description: _description.text.trim(), personality: _personality.text, scenario: _scenario.text, firstMessage: _firstMessage.text, exampleMessages: _exampleMessages.text, systemPrompt: _systemPrompt.text, postHistoryInstructions: _postHistory.text, creatorNotes: _creatorNotes.text, alternateGreetings: _greetings, characterBook: book, clearCharacterBook: _entries.isEmpty));
    Navigator.pop(context);
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, this.maxLines = 1});
  final TextEditingController controller;
  final String label;
  final int maxLines;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: controller, maxLines: maxLines, decoration: InputDecoration(labelText: label)));
}

class _BookEntryEditor extends StatefulWidget {
  const _BookEntryEditor({required this.entry, required this.onChanged, required this.onDelete});
  final WorldBookEntry entry;
  final ValueChanged<WorldBookEntry> onChanged;
  final VoidCallback onDelete;
  @override
  State<_BookEntryEditor> createState() => _BookEntryEditorState();
}

class _BookEntryEditorState extends State<_BookEntryEditor> {
  late final _keys = TextEditingController(text: widget.entry.keys.join(', '));
  late final _content = TextEditingController(text: widget.entry.content);

  WorldBookEntry _updated({List<String>? keys, String? content, bool? enabled, bool? constant, bool? selective, String? position}) => WorldBookEntry(id: widget.entry.id, keys: keys ?? widget.entry.keys, content: content ?? widget.entry.content, enabled: enabled ?? widget.entry.enabled, constant: constant ?? widget.entry.constant, selective: selective ?? widget.entry.selective, position: position ?? widget.entry.position);
  @override
  void dispose() { _keys.dispose(); _content.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(top: 8), child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [Row(children: [const Expanded(child: Text('世界书条目', style: TextStyle(fontWeight: FontWeight.w700))), Switch(value: widget.entry.enabled, onChanged: (value) => widget.onChanged(_updated(enabled: value))), IconButton(tooltip: '删除条目', onPressed: widget.onDelete, icon: const Icon(Icons.delete_outline, size: 18))]), TextField(controller: _keys, decoration: const InputDecoration(labelText: '关键词，用逗号分隔'), onChanged: (value) => widget.onChanged(_updated(keys: value.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList()))), const SizedBox(height: 8), TextField(controller: _content, maxLines: 3, decoration: const InputDecoration(labelText: '注入内容'), onChanged: (value) => widget.onChanged(_updated(content: value))), SwitchListTile(contentPadding: EdgeInsets.zero, dense: true, title: const Text('常驻注入', style: TextStyle(fontSize: 12)), subtitle: const Text('无论关键词是否命中都注入', style: TextStyle(fontSize: 10)), value: widget.entry.constant, onChanged: (value) => widget.onChanged(_updated(constant: value))), SwitchListTile(contentPadding: EdgeInsets.zero, dense: true, title: const Text('选择性触发', style: TextStyle(fontSize: 12)), value: widget.entry.selective, onChanged: (value) => widget.onChanged(_updated(selective: value))), DropdownButtonFormField<String>(value: widget.entry.position, decoration: const InputDecoration(labelText: '注入位置'), items: const [DropdownMenuItem(value: 'before_char', child: Text('角色定义之前')), DropdownMenuItem(value: 'after_char', child: Text('角色定义之后')), DropdownMenuItem(value: 'before_example_messages', child: Text('示例消息之前')), DropdownMenuItem(value: 'after_example_messages', child: Text('示例消息之后'))], onChanged: (value) { if (value != null) widget.onChanged(_updated(position: value)); })])));
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.content});
  final String title;
  final String content;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(content, style: const TextStyle(fontSize: 13, height: 1.5, color: SuicangTheme.muted))]));
}


class _EditorHero extends StatelessWidget {
  const _EditorHero({required this.card, required this.onExport});
  final CharacterCard card;
  final VoidCallback onExport;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: SuicangTheme.heroGradient, borderRadius: BorderRadius.circular(22)), child: Row(children: [Container(width: 58, height: 58, decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(18)), child: card.avatarData == null ? Center(child: Text(card.avatar, style: const TextStyle(fontSize: 31))) : ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.memory(base64Decode(card.avatarData!), fit: BoxFit.cover))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(card.name, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(card.source, style: const TextStyle(color: Colors.white70, fontSize: 11)), const SizedBox(height: 7), Row(children: [const Text('SillyTavern Card Compatible', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w700)), const Spacer(), IconButton(tooltip: '导出 JSON', onPressed: onExport, color: Colors.white, icon: const Icon(Icons.ios_share_outlined, size: 18))]))]));
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({required this.icon, required this.title, required this.subtitle, required this.children});
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.fromLTRB(15, 14, 15, 15), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: SuicangTheme.line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: SuicangTheme.soft, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 17, color: SuicangTheme.primary)), const SizedBox(width: 9), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)), Text(subtitle, style: const TextStyle(fontSize: 10, color: SuicangTheme.muted))])]), const SizedBox(height: 14), ...children]);
}

class _GreetingEditor extends StatelessWidget {
  const _GreetingEditor({required this.greetings, required this.controller, required this.onChanged});
  final List<String> greetings;
  final TextEditingController controller;
  final ValueChanged<List<String>> onChanged;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Expanded(child: Text('Alternate Greetings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))), Text('${greetings.length} 条', style: const TextStyle(fontSize: 10, color: SuicangTheme.muted))]), const SizedBox(height: 7), ReorderableListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: greetings.length, onReorder: (oldIndex, newIndex) { final next = [...greetings]; if (newIndex > oldIndex) newIndex -= 1; final item = next.removeAt(oldIndex); next.insert(newIndex, item); onChanged(next); }, itemBuilder: (_, index) => Container(key: ValueKey('greeting-$index-${greetings[index]}'), margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: SuicangTheme.soft, borderRadius: BorderRadius.circular(12)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.drag_indicator, size: 17, color: SuicangTheme.muted), const SizedBox(width: 6), Expanded(child: Text(greetings[index], maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.35))), IconButton(visualDensity: VisualDensity.compact, onPressed: () { final next = [...greetings]..removeAt(index); onChanged(next); }, icon: const Icon(Icons.close, size: 16))])), TextField(controller: controller, maxLines: 2, decoration: InputDecoration(labelText: '添加新的开场白', suffixIcon: IconButton(onPressed: () { if (controller.text.trim().isEmpty) return; onChanged([...greetings, controller.text.trim()]); controller.clear(); }, icon: const Icon(Icons.add_circle_outline)))]);
}
