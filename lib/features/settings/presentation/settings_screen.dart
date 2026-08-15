import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/suicang_theme.dart';
import '../../chat/data/openai_compatible_provider.dart';
import '../application/provider_config.dart';
import '../application/resource_library.dart';
import '../data/preset_parser.dart';
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
            sliver: SliverList(
                delegate: SliverChildListDelegate([
              _Section(title: '生成配置', icon: Icons.tune_rounded, children: [
                _PresetCard(preset: _preset, onImport: _pickPreset)
              ]),
              _Section(
                  title: '世界书 / Lorebook',
                  icon: Icons.menu_book_outlined,
                  children: [
                    _WorldBookCard(books: _books, onImport: _pickWorldBook)
                  ]),
              _Section(title: '模型连接', icon: Icons.hub_outlined, children: [
                _ConnectionCard(
                    config: ref.watch(providerConfigProvider),
                    onTap: _showConnectionInfo)
              ]),
              _Section(
                  title: '兼容性',
                  icon: Icons.swap_horiz_rounded,
                  children: const [_CompatibilityCard()]),
            ])),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPreset() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json'], withData: true);
    if (!mounted || result == null || result.files.single.bytes == null) return;
    try {
      final file = result.files.single;
      final preset = PresetParser.fromJsonText(utf8.decode(file.bytes!),
          sourceName: file.name);
      ref.read(resourceLibraryProvider.notifier).setPreset(preset);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('已导入预设「${preset.name}」')));
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('预设导入失败：$error')));
    }
  }

  Future<void> _pickWorldBook() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json'], withData: true);
    if (!mounted || result == null || result.files.single.bytes == null) return;
    try {
      final file = result.files.single;
      final book = PresetParser.fromJsonTextAsWorldBook(
          utf8.decode(file.bytes!),
          sourceName: file.name);
      ref.read(resourceLibraryProvider.notifier).addWorldBook(book);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('已导入世界书「${book.name}」')));
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('世界书导入失败：$error')));
    }
  }

  void _showConnectionInfo() {
    final config = ref.read(providerConfigProvider);
    final baseUrl = TextEditingController(text: config.baseUrl);
    final model = TextEditingController(text: config.model);
    final apiKey = TextEditingController(text: config.apiKey);
    var enabled = config.enabled;
    var testing = false;
    String? testResult;
    final sheet = showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 28),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('模型连接',
                            style: TextStyle(
                                fontSize: 21, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        const Text(
                            '兼容 OpenAI / LM Studio / Ollama OpenAI API 格式。',
                            style: TextStyle(
                                fontSize: 12, color: SuicangTheme.muted)),
                        const SizedBox(height: 16),
                        TextField(
                            controller: baseUrl,
                            decoration: const InputDecoration(
                                labelText: 'Base URL',
                                hintText: 'https://api.example.com/v1',
                                prefixIcon: Icon(Icons.link))),
                        const SizedBox(height: 10),
                        TextField(
                            controller: model,
                            decoration: const InputDecoration(
                                labelText: '模型名称',
                                hintText: 'gpt-4o-mini',
                                prefixIcon: Icon(Icons.memory_outlined))),
                        const SizedBox(height: 10),
                        TextField(
                            controller: apiKey,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'API Key',
                                prefixIcon: Icon(Icons.key_outlined))),
                        SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('启用真实模型'),
                            subtitle: const Text('未启用时使用本地演示回复',
                                style: TextStyle(fontSize: 11)),
                            value: enabled,
                            onChanged: (value) =>
                                setSheetState(() => enabled = value)),
                        if (testResult != null)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(testResult!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: testResult!.startsWith('连接成功')
                                          ? Colors.green
                                          : Theme.of(context)
                                              .colorScheme
                                              .error))),
                        Row(children: [
                          Expanded(
                              child: OutlinedButton.icon(
                                  onPressed: testing
                                      ? null
                                      : () async {
                                          setSheetState(() {
                                            testing = true;
                                            testResult = null;
                                          });
                                          try {
                                            final provider =
                                                OpenAiCompatibleProvider(
                                                    baseUrl:
                                                        baseUrl.text.trim(),
                                                    apiKey: apiKey.text);
                                            final result =
                                                await provider.testConnection(
                                                    model: model.text.trim());
                                            if (context.mounted)
                                              setSheetState(
                                                  () => testResult = result);
                                          } catch (error) {
                                            if (context.mounted)
                                              setSheetState(() =>
                                                  testResult = '连接失败：$error');
                                          } finally {
                                            if (context.mounted)
                                              setSheetState(
                                                  () => testing = false);
                                          }
                                        },
                                  icon: testing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.network_check,
                                          size: 18),
                                  label: Text(testing ? '测试中' : '测试连接'))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: FilledButton(
                                  onPressed: () {
                                    ref
                                        .read(providerConfigProvider.notifier)
                                        .setConnection(
                                            baseUrl: baseUrl.text.trim(),
                                            model: model.text.trim(),
                                            apiKey: apiKey.text,
                                            enabled: enabled);
                                    Navigator.pop(sheetContext);
                                  },
                                  child: const Text('保存连接'))),
                        ]),
                      ])))),
    );
    sheet.whenComplete(() {
      baseUrl.dispose();
      model.dispose();
      apiKey.dispose();
    });
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.preset});
  final PromptPreset preset;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
      decoration: const BoxDecoration(
          gradient: SuicangTheme.heroGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
      child: SafeArea(
          bottom: false,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('配置中心',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            const Text('把 SillyTavern 的预设与世界书带到现代工作台',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 20),
            Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.12),
                    borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  const Icon(Icons.auto_awesome, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('当前预设',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 10)),
                          Text(preset.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ]),
                  ),
                  Text(preset.model.isEmpty ? '未选择模型' : preset.model,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11))
                ]))
          ])));
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: SuicangTheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))
        ]),
        const SizedBox(height: 10),
        ...children
      ]));
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({required this.preset, required this.onImport});
  final PromptPreset preset;
  final VoidCallback onImport;
  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: SuicangTheme.soft,
                      borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.tune, color: SuicangTheme.primary)),
              const SizedBox(width: 11),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(preset.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                        '${preset.model}  ·  Temperature ${preset.temperature.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 11, color: SuicangTheme.muted))
                  ])),
              IconButton(
                  tooltip: '导入预设',
                  onPressed: onImport,
                  icon: const Icon(Icons.file_upload_outlined)),
            ]),
            const SizedBox(height: 13),
            Row(children: [
              _Metric(label: 'Top P', value: preset.topP.toStringAsFixed(2)),
              _Metric(label: '最大输出', value: '${preset.maxTokens}'),
              _Metric(label: '来源', value: preset.source)
            ]),
          ],
        ),
      );
}

class _WorldBookCard extends StatelessWidget {
  const _WorldBookCard({required this.books, required this.onImport});
  final List<WorldBook> books;
  final VoidCallback onImport;
  @override
  Widget build(BuildContext context) => _Panel(
          child: Column(children: [
        if (books.isEmpty)
          const Text('还没有导入世界书', style: TextStyle(color: SuicangTheme.muted)),
        ...books.map((book) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.menu_book_outlined,
                color: SuicangTheme.primary),
            title: Text(book.name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${book.entries.length} 个条目  ·  ${book.source}',
                style: const TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded))),
        const Divider(height: 20),
        Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.add, size: 17),
                label: const Text('导入世界书')))
      ]));
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.config, required this.onTap});
  final ProviderConfig config;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _Panel(
      child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
              config.isReady ? Icons.cloud_done_outlined : Icons.cloud_outlined,
              color: config.isReady ? Colors.green : SuicangTheme.primary),
          title: const Text('OpenAI-compatible Provider',
              style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
              config.isReady ? '${config.model}  ·  已启用' : '尚未配置 API 连接',
              style: const TextStyle(fontSize: 11, color: SuicangTheme.muted)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap));
}

class _CompatibilityCard extends StatelessWidget {
  const _CompatibilityCard();
  @override
  Widget build(BuildContext context) => _Panel(
          child: Column(children: const [
        _CompatRow(
            icon: Icons.image_outlined,
            title: '角色卡',
            detail: 'PNG V1 / V2 · JSON'),
        _CompatRow(icon: Icons.tune_rounded, title: '预设', detail: '采样参数与系统提示'),
        _CompatRow(
            icon: Icons.menu_book_outlined,
            title: '世界书',
            detail: 'Character Book · Lorebook'),
        _CompatRow(
            icon: Icons.extension_outlined, title: '插件', detail: '兼容层开发中')
      ]));
}

class _CompatRow extends StatelessWidget {
  const _CompatRow(
      {required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: SuicangTheme.muted),
      title: Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      trailing: Text(detail,
          style: const TextStyle(fontSize: 10, color: SuicangTheme.muted)));
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: SuicangTheme.muted)),
        const SizedBox(height: 3),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
      ]));
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SuicangTheme.line)),
      child: child);
}
