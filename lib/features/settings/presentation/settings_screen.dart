import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/suicang_theme.dart';
import '../../chat/data/openai_compatible_provider.dart';
import '../application/provider_config.dart';
import '../application/resource_library.dart';
import '../data/preset_parser.dart';
import '../data/preset_exporter.dart';
import '../../../core/storage/local_json_store.dart';
import '../domain/preset_models.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PromptPreset get _preset => ref.watch(resourceLibraryProvider).preset;
  List<WorldBook> get _books => ref.watch(resourceLibraryProvider).worldBooks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _SettingsHero(preset: _preset)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            sliver: SliverList(delegate: SliverChildListDelegate([
              _Section(title: '生成配置', icon: Icons.tune_rounded, children: [_PresetCard(preset: _preset, onImport: _pickPreset, onEdit: _showPresetEditor, onNodes: _showPresetNodes, onExport: _exportPreset)]),
              _Section(title: '世界书 / Lorebook', icon: Icons.menu_book_outlined, children: [_WorldBookCard(books: _books, onImport: _pickWorldBook, onOpen: _showWorldBook)]),
              _Section(title: '模型连接', icon: Icons.hub_outlined, children: [_ConnectionCard(config: ref.watch(providerConfigProvider), onTap: _showConnectionInfo)]),
              _Section(title: '兼容性', icon: Icons.swap_horiz_rounded, children: const [_CompatibilityCard()]),
            ])),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPreset() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
    if (!mounted || result == null || result.files.single.bytes == null) return;
    try {
      final file = result.files.single;
      final preset = PresetParser.fromJsonText(utf8.decode(file.bytes!), sourceName: file.name);
      ref.read(resourceLibraryProvider.notifier).setPreset(preset);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导入预设「${preset.name}」')));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('预设导入失败：$error')));
    }
  }

  void _showPresetEditor() {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => _PresetEditor(preset: _preset));
  }

  void _showPresetNodes() {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => _PresetNodesManager(preset: _preset));
  }

  Future<void> _exportPreset() async {
    final file = await LocalJsonStore.writeText('export_preset_${DateTime.now().millisecondsSinceEpoch}', PresetExporter.toJsonText(_preset));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('预设已导出：${file.path}')));
  }

  void _showWorldBook(WorldBook book) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _WorldBookManager(book: book),
    );
  }

  Future<void> _pickWorldBook() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
    if (!mounted || result == null || result.files.single.bytes == null) return;
    try {
      final file = result.files.single;
      final book = PresetParser.fromJsonTextAsWorldBook(utf8.decode(file.bytes!), sourceName: file.name);
      ref.read(resourceLibraryProvider.notifier).addWorldBook(book);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导入世界书「${book.name}」')));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('世界书导入失败：$error')));
    }
  }

  Future<void> _showConnectionInfo() async {
    final config = ref.read(providerConfigProvider);
    final baseUrl = TextEditingController(text: config.baseUrl);
    final model = TextEditingController(text: config.model);
    final apiKey = TextEditingController(text: config.apiKey);
    var enabled = config.enabled;
    var testing = false;
    String? testResult;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) => SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('模型连接', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('兼容 OpenAI / LM Studio / Ollama OpenAI API 格式。', style: TextStyle(fontSize: 12, color: SuicangTheme.muted)),
        const SizedBox(height: 16),
        TextField(controller: baseUrl, decoration: const InputDecoration(labelText: 'Base URL', hintText: 'https://api.example.com/v1', prefixIcon: Icon(Icons.link))),
        const SizedBox(height: 10),
        TextField(controller: model, decoration: const InputDecoration(labelText: '模型名称', hintText: 'gpt-4o-mini', prefixIcon: Icon(Icons.memory_outlined))),
        const SizedBox(height: 10),
        TextField(controller: apiKey, obscureText: true, decoration: const InputDecoration(labelText: 'API Key', prefixIcon: Icon(Icons.key_outlined))),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('启用真实模型'), subtitle: const Text('未启用时使用本地演示回复', style: TextStyle(fontSize: 11)), value: enabled, onChanged: (value) => setSheetState(() => enabled = value)),
        if (testResult != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(testResult!, style: TextStyle(fontSize: 12, color: testResult!.startsWith('连接成功') ? Colors.green : Theme.of(context).colorScheme.error))),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: testing ? null : () async { setSheetState(() { testing = true; testResult = null; }); try { final provider = OpenAiCompatibleProvider(baseUrl: baseUrl.text.trim(), apiKey: apiKey.text); final result = await provider.testConnection(model: model.text.trim()); if (context.mounted) setSheetState(() => testResult = result); } catch (error) { if (context.mounted) setSheetState(() => testResult = '连接失败：$error'); } finally { if (context.mounted) setSheetState(() => testing = false); } }, icon: testing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.network_check, size: 18), label: Text(testing ? '测试中' : '测试连接'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(onPressed: () { ref.read(providerConfigProvider.notifier).setConnection(baseUrl: baseUrl.text.trim(), model: model.text.trim(), apiKey: apiKey.text, enabled: enabled); Navigator.pop(sheetContext); }, child: const Text('保存连接'))),
        ]),
      ]))),
    );
    baseUrl.dispose();
    model.dispose();
    apiKey.dispose();
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.preset});
  final PromptPreset preset;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(20, 22, 20, 26), decoration: const BoxDecoration(gradient: SuicangTheme.heroGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))), child: SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('配置中心', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w800)), const SizedBox(height: 5), const Text('把 SillyTavern 的预设与世界书带到现代工作台', style: TextStyle(color: Colors.white70, fontSize: 12)), const SizedBox(height: 20), Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.auto_awesome, color: Colors.white), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('当前预设', style: TextStyle(color: Colors.white60, fontSize: 10)), Text(preset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),]),), Text(preset.model.isEmpty ? '未选择模型' : preset.model, style: const TextStyle(color: Colors.white70, fontSize: 11))]))])));
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 18, color: SuicangTheme.primary), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]), const SizedBox(height: 10), ...children]));
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({required this.preset, required this.onImport, required this.onEdit, required this.onNodes, required this.onExport});
  final PromptPreset preset;
  final VoidCallback onImport;
  final VoidCallback onEdit;
  final VoidCallback onNodes;
  final VoidCallback onExport;
  @override
  Widget build(BuildContext context) => _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: SuicangTheme.soft, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.tune, color: SuicangTheme.primary)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(preset.name, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text('${preset.model}  ·  Temperature ${preset.temperature.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: SuicangTheme.muted))])), IconButton(tooltip: '提示词节点', onPressed: onNodes, icon: const Icon(Icons.account_tree_outlined)), IconButton(tooltip: '导出预设', onPressed: onExport, icon: const Icon(Icons.file_download_outlined)), IconButton(tooltip: '编辑预设', onPressed: onEdit, icon: const Icon(Icons.edit_outlined)), IconButton(tooltip: '导入预设', onPressed: onImport, icon: const Icon(Icons.file_upload_outlined))]), const SizedBox(height: 13), Row(children: [_Metric(label: 'Top P', value: preset.topP.toStringAsFixed(2)), _Metric(label: '最大输出', value: '${preset.maxTokens}'), _Metric(label: '来源', value: preset.source)]))]));
}

class _PresetEditor extends ConsumerStatefulWidget {
  const _PresetEditor({required this.preset});
  final PromptPreset preset;
  @override
  ConsumerState<_PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<_PresetEditor> {
  late final TextEditingController name;
  late final TextEditingController model;
  late final TextEditingController temperature;
  late final TextEditingController topP;
  late final TextEditingController maxTokens;
  late final TextEditingController systemPrompt;

  @override
  void initState() {
    super.initState();
    final preset = widget.preset;
    name = TextEditingController(text: preset.name);
    model = TextEditingController(text: preset.model);
    temperature = TextEditingController(text: preset.temperature.toString());
    topP = TextEditingController(text: preset.topP.toString());
    maxTokens = TextEditingController(text: preset.maxTokens.toString());
    systemPrompt = TextEditingController(text: preset.systemPrompt);
  }

  @override
  void dispose() {
    name.dispose(); model.dispose(); temperature.dispose(); topP.dispose(); maxTokens.dispose(); systemPrompt.dispose();
    super.dispose();
  }

  double _number(TextEditingController controller, double fallback, double min, double max) {
    final value = double.tryParse(controller.text.trim()) ?? fallback;
    return value.clamp(min, max).toDouble();
  }

  int _integer(TextEditingController controller, int fallback, int min, int max) {
    final value = int.tryParse(controller.text.trim()) ?? fallback;
    return value.clamp(min, max);
  }

  void _save() {
    final current = widget.preset;
    final updated = PromptPreset(name: name.text.trim().isEmpty ? current.name : name.text.trim(), model: model.text.trim(), temperature: _number(temperature, current.temperature, 0, 2), topP: _number(topP, current.topP, 0, 1), maxTokens: _integer(maxTokens, current.maxTokens, 1, 32768), systemPrompt: systemPrompt.text, source: current.source, nodes: current.nodes, promptOrder: current.promptOrder, templates: current.templates, extensions: current.extensions);
    ref.read(resourceLibraryProvider.notifier).setPreset(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('编辑生成预设', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
    const SizedBox(height: 4),
    const Text('这些参数会作为当前预设参与聊天生成。', style: TextStyle(fontSize: 12, color: SuicangTheme.muted)),
    const SizedBox(height: 16),
    TextField(controller: name, decoration: const InputDecoration(labelText: '预设名称', prefixIcon: Icon(Icons.label_outline))),
    const SizedBox(height: 10),
    TextField(controller: model, decoration: const InputDecoration(labelText: '模型名称', hintText: '例如：gpt-4o-mini', prefixIcon: Icon(Icons.memory_outlined))),
    const SizedBox(height: 10),
    Row(children: [Expanded(child: TextField(controller: temperature, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Temperature'))), const SizedBox(width: 10), Expanded(child: TextField(controller: topP, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Top P')))]),
    const SizedBox(height: 10),
    TextField(controller: maxTokens, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '最大输出 Token', prefixIcon: Icon(Icons.numbers_outlined))),
    const SizedBox(height: 10),
    TextField(controller: systemPrompt, minLines: 5, maxLines: 12, decoration: const InputDecoration(labelText: 'System Prompt', alignLabelWithHint: true, hintText: '定义模型的整体行为、语气和输出规则')),
    const SizedBox(height: 16),
    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('保存预设'))),
  ]));
}

class _WorldBookCard extends StatelessWidget {
  const _WorldBookCard({required this.books, required this.onImport, required this.onOpen});
  final List<WorldBook> books;
  final VoidCallback onImport;
  final ValueChanged<WorldBook> onOpen;
  @override
  Widget build(BuildContext context) => _Panel(child: Column(children: [if (books.isEmpty) const Text('还没有导入世界书', style: TextStyle(color: SuicangTheme.muted)), ...books.map((book) => ListTile(onTap: () => onOpen(book), contentPadding: EdgeInsets.zero, leading: const Icon(Icons.menu_book_outlined, color: SuicangTheme.primary), title: Text(book.name, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${book.entries.length} 个条目  ·  ${book.source}', style: const TextStyle(fontSize: 11)), trailing: const Icon(Icons.chevron_right_rounded))), const Divider(height: 20), Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: onImport, icon: const Icon(Icons.add, size: 17), label: const Text('导入世界书')))]));
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.config, required this.onTap});
  final ProviderConfig config;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _Panel(child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(config.isReady ? Icons.cloud_done_outlined : Icons.cloud_outlined, color: config.isReady ? Colors.green : SuicangTheme.primary), title: const Text('OpenAI-compatible Provider', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(config.isReady ? '${config.model}  ·  已启用' : '尚未配置 API 连接', style: const TextStyle(fontSize: 11, color: SuicangTheme.muted)), trailing: const Icon(Icons.chevron_right_rounded), onTap: onTap));
}

class _CompatibilityCard extends StatelessWidget {
  const _CompatibilityCard();
  @override
  Widget build(BuildContext context) => _Panel(child: Column(children: const [_CompatRow(icon: Icons.image_outlined, title: '角色卡', detail: 'PNG V1 / V2 · JSON'), _CompatRow(icon: Icons.tune_rounded, title: '预设', detail: '采样参数与系统提示'), _CompatRow(icon: Icons.menu_book_outlined, title: '世界书', detail: 'Character Book · Lorebook'), _CompatRow(icon: Icons.extension_outlined, title: '插件', detail: '兼容层开发中')]));
}

class _CompatRow extends StatelessWidget {
  const _CompatRow({required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon, size: 20, color: SuicangTheme.muted), title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), trailing: Text(detail, style: const TextStyle(fontSize: 10, color: SuicangTheme.muted)));
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: SuicangTheme.muted)), const SizedBox(height: 3), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]));
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: SuicangTheme.line)), child: child);
}

class _WorldBookManager extends ConsumerWidget {
  const _WorldBookManager({required this.book});
  final WorldBook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(resourceLibraryProvider).worldBooks.firstWhere((item) => item.name == book.name, orElse: () => book);
    return SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(current.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('${current.entries.length} 个条目  ·  ${current.source}', style: const TextStyle(fontSize: 12, color: SuicangTheme.muted))])), IconButton(tooltip: '删除世界书', icon: const Icon(Icons.delete_outline), onPressed: () { ref.read(resourceLibraryProvider.notifier).removeWorldBook(current); Navigator.pop(context); })]),
      const SizedBox(height: 12),
      SizedBox(height: MediaQuery.sizeOf(context).height * .52, child: ReorderableListView.builder(itemCount: current.entries.length, onReorder: (oldIndex, newIndex) => ref.read(resourceLibraryProvider.notifier).reorderWorldBookEntry(current, oldIndex, newIndex), itemBuilder: (context, index) { final entry = current.entries[index]; return ListTile(key: ValueKey(entry.id), contentPadding: EdgeInsets.zero, leading: Icon(entry.enabled ? Icons.check_circle_outline : Icons.pause_circle_outline, color: entry.enabled ? Colors.green : SuicangTheme.muted), title: Text(entry.keys.isEmpty ? '无关键词条目' : entry.keys.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), subtitle: Text('${entry.position}${entry.constant ? '  ·  常驻' : ''}\n${entry.content}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Switch(value: entry.enabled, onChanged: (value) => ref.read(resourceLibraryProvider.notifier).updateWorldBookEntry(current, _copyEntry(entry, enabled: value))), IconButton(tooltip: '编辑条目', icon: const Icon(Icons.edit_outlined, size: 19), onPressed: () => _editEntry(context, ref, current, entry)), IconButton(tooltip: '删除条目', icon: const Icon(Icons.close, size: 18), onPressed: () => ref.read(resourceLibraryProvider.notifier).removeWorldBookEntry(current, entry))])); }))
    ]));
  }

  static WorldBookEntryModel _copyEntry(WorldBookEntryModel entry, {List<String>? keys, String? content, bool? enabled, bool? constant, String? position}) => WorldBookEntryModel(id: entry.id, keys: keys ?? entry.keys, content: content ?? entry.content, enabled: enabled ?? entry.enabled, constant: constant ?? entry.constant, selective: entry.selective, position: position ?? entry.position, extensions: entry.extensions);

  static Future<void> _editEntry(BuildContext context, WidgetRef ref, WorldBook book, WorldBookEntryModel entry) async {
    final keys = TextEditingController(text: entry.keys.join(', '));
    final content = TextEditingController(text: entry.content);
    var enabled = entry.enabled;
    var constant = entry.constant;
    var position = const {'before_char', 'after_char', 'before_example_messages', 'after_example_messages'}.contains(entry.position) ? entry.position : 'before_char';
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (sheetContext) => StatefulBuilder(builder: (context, setState) => SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('编辑世界书条目', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 14),
      TextField(controller: keys, decoration: const InputDecoration(labelText: '关键词', hintText: '例如：城堡, 王国, 夜晚')), const SizedBox(height: 10),
      TextField(controller: content, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: '注入内容')),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('启用条目'), value: enabled, onChanged: (value) => setState(() => enabled = value)),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('常驻注入'), subtitle: const Text('不需要关键词命中', style: TextStyle(fontSize: 11)), value: constant, onChanged: (value) => setState(() => constant = value)),
      DropdownButtonFormField<String>(value: position, decoration: const InputDecoration(labelText: '注入位置'), items: const [DropdownMenuItem(value: 'before_char', child: Text('角色定义前')), DropdownMenuItem(value: 'after_char', child: Text('角色定义后')), DropdownMenuItem(value: 'before_example_messages', child: Text('示例消息前')), DropdownMenuItem(value: 'after_example_messages', child: Text('示例消息后'))], onChanged: (value) { if (value != null) setState(() => position = value); }), const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final updated = _copyEntry(entry, keys: keys.text.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList(), content: content.text, enabled: enabled, constant: constant, position: position); ref.read(resourceLibraryProvider.notifier).updateWorldBookEntry(book, updated); Navigator.pop(sheetContext); }, child: const Text('保存条目')),
    ])))));
    keys.dispose();
    content.dispose();
  }
}

class _PresetNodesManager extends ConsumerWidget {
  const _PresetNodesManager({required this.preset});
  final PromptPreset preset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(resourceLibraryProvider).preset;
    final nodes = current.enabledNodes;
    return SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('提示词节点', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('${current.nodes.length} 个节点 · ${nodes.length} 个启用', style: const TextStyle(fontSize: 12, color: SuicangTheme.muted))])), const Icon(Icons.account_tree_outlined, color: SuicangTheme.primary)]),
      const SizedBox(height: 12),
      SizedBox(height: MediaQuery.sizeOf(context).height * .58, child: ListView.builder(itemCount: current.nodes.length, itemBuilder: (context, index) { final node = current.nodes[index]; return ListTile(contentPadding: EdgeInsets.zero, leading: Icon(node.enabled ? Icons.check_circle_outline : Icons.pause_circle_outline, color: node.enabled ? Colors.green : SuicangTheme.muted), title: Text(node.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)), subtitle: Text('${node.role} · depth ${node.injectionDepth} · order ${node.injectionOrder}\n${node.content}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)), trailing: Switch(value: node.enabled, onChanged: (value) { final updated = [...current.nodes]; updated[index] = node.copyWith(enabled: value); ref.read(resourceLibraryProvider.notifier).setPreset(PromptPreset(name: current.name, model: current.model, temperature: current.temperature, topP: current.topP, maxTokens: current.maxTokens, systemPrompt: current.systemPrompt, source: current.source, nodes: updated, promptOrder: current.promptOrder, templates: current.templates, extensions: current.extensions)); })); }))
    ])));
  }
}
