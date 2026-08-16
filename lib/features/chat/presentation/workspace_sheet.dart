import 'package:flutter/material.dart';
import '../application/chat_controller.dart';
import '../domain/chat_workspace.dart';
import '../../settings/domain/preset_models.dart';
import '../../characters/domain/character_card.dart';
import '../../../core/theme/suicang_theme.dart';

class WorkspaceSheet extends StatefulWidget {
  const WorkspaceSheet({required this.state, required this.characters, required this.onSessionSelected, required this.onCharacterSelected, required this.onPersonaChanged, required this.onGreetingSelected, required this.onNewSession, required this.onRenameSession, required this.onDeleteSession, required this.onParentSession, required this.preset, required this.worldBooks, required this.onResourcesChanged, super.key});
  final ChatState state;
  final List<CharacterCard> characters;
  final ValueChanged<String> onSessionSelected;
  final ValueChanged<CharacterProfile> onCharacterSelected;
  final ValueChanged<UserPersona> onPersonaChanged;
  final ValueChanged<String> onGreetingSelected;
  final VoidCallback onNewSession;
  final void Function(String id, String title) onRenameSession;
  final ValueChanged<String> onDeleteSession;
  final ValueChanged<String> onParentSession;
  final PromptPreset preset;
  final List<WorldBook> worldBooks;
  final void Function(String? presetName, List<String>? worldBookNames) onResourcesChanged;

  @override
  State<WorkspaceSheet> createState() => _WorkspaceSheetState();
}

class _WorkspaceSheetState extends State<WorkspaceSheet> {
  late UserPersona _persona = widget.state.persona;
  late CharacterProfile _character = widget.state.character;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('聊天工作区', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('角色、会话和 Persona 都属于当前聊天上下文。', style: TextStyle(fontSize: 12, color: SuicangTheme.muted)),
            const SizedBox(height: 18),
            _CharacterCard(character: _character, onTap: _selectCharacter),
            const SizedBox(height: 14),
            _ResourceBindingCard(preset: widget.preset, worldBooks: widget.worldBooks, selectedPreset: widget.state.presetName, selectedWorldBooks: widget.state.worldBookNames, onChanged: widget.onResourcesChanged),
            if (_character.card?.alternateGreetings.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _GreetingPicker(greetings: _character.card!.alternateGreetings, onSelected: widget.onGreetingSelected),
            ],
            const SizedBox(height: 20),
            Row(children: [const Expanded(child: _SheetTitle(icon: Icons.forum_outlined, title: '会话')), IconButton(tooltip: '新建会话', onPressed: widget.onNewSession, icon: const Icon(Icons.add_circle_outline))]),
            const SizedBox(height: 8),
            ..._orderedSessions(widget.state.sessions).map((item) { final session = item.session; return _SessionTile(session: session, depth: item.depth, selected: session.id == widget.state.sessionId, onTap: () => widget.onSessionSelected(session.id), onRename: () => _rename(session), onDelete: () => widget.onDeleteSession(session.id), onParent: session.parentSessionId == null ? null : () => widget.onParentSession(session.parentSessionId!)); }),
            const SizedBox(height: 18),
            const _SheetTitle(icon: Icons.badge_outlined, title: '用户 Persona'),
            const SizedBox(height: 8),
            _PersonaEditor(persona: _persona, onChanged: (next) { setState(() => _persona = next); widget.onPersonaChanged(next); }),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(ChatSessionSummary session) async {
    final controller = TextEditingController(text: session.title);
    final title = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('重命名会话'), content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: '会话名称')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('保存'))]));
    controller.dispose();
    if (title != null) widget.onRenameSession(session.id, title);
  }

  void _selectCharacter() {
    final options = widget.characters.map((card) => CharacterProfile(id: card.id, name: card.name, subtitle: card.tagline, emoji: card.avatar, avatarData: card.avatarData, description: card.description, card: card)).toList();
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: options.map((option) => ListTile(leading: Text(option.emoji, style: const TextStyle(fontSize: 26)), title: Text(option.name), subtitle: Text(option.subtitle), trailing: option.id == _character.id ? const Icon(Icons.check, color: SuicangTheme.primary) : null, onTap: () { setState(() => _character = option); widget.onCharacterSelected(option); Navigator.pop(context); })).toList())));
  }
}

class _SessionTreeItem {
  const _SessionTreeItem(this.session, this.depth);
  final ChatSessionSummary session;
  final int depth;
}

List<_SessionTreeItem> _orderedSessions(List<ChatSessionSummary> sessions) {
  final byParent = <String?, List<ChatSessionSummary>>{};
  final ids = sessions.map((session) => session.id).toSet();
  for (final session in sessions) {
    final parent = session.parentSessionId != null && ids.contains(session.parentSessionId) ? session.parentSessionId : null;
    byParent.putIfAbsent(parent, () => []).add(session);
  }
  final result = <_SessionTreeItem>[];
  final visited = <String>{};
  void visit(String? parentId, int depth) {
    for (final session in byParent[parentId] ?? const <ChatSessionSummary>[]) {
      if (!visited.add(session.id)) continue;
      result.add(_SessionTreeItem(session, depth));
      visit(session.id, depth + 1);
    }
  }
  visit(null, 0);
  for (final session in sessions) {
    if (visited.add(session.id)) result.add(_SessionTreeItem(session, 0));
  }
  return result;
}

class _ResourceBindingCard extends StatefulWidget {
  const _ResourceBindingCard({required this.preset, required this.worldBooks, required this.selectedPreset, required this.selectedWorldBooks, required this.onChanged});
  final PromptPreset preset;
  final List<WorldBook> worldBooks;
  final String? selectedPreset;
  final List<String>? selectedWorldBooks;
  final void Function(String? presetName, List<String>? worldBookNames) onChanged;

  @override
  State<_ResourceBindingCard> createState() => _ResourceBindingCardState();
}

class _ResourceBindingCardState extends State<_ResourceBindingCard> {
  late String? _preset = widget.selectedPreset;
  late Set<String> _books = {...?widget.selectedWorldBooks};

  void _emit() => widget.onChanged(_preset, _books.isEmpty ? null : _books.toList());

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: SuicangTheme.soft, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Icon(Icons.link_rounded, size: 18, color: SuicangTheme.primary), const SizedBox(width: 7), const Expanded(child: Text('本会话资源', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800))), if (_preset != null || _books.isNotEmpty) TextButton(onPressed: () { setState(() { _preset = null; _books.clear(); }); _emit(); }, child: const Text('恢复默认', style: TextStyle(fontSize: 11)))]),
    const SizedBox(height: 5),
    Text(_preset == null ? '预设：继承全局「${widget.preset.name}」' : '预设：固定「${widget.preset.name}」', style: const TextStyle(fontSize: 11, color: SuicangTheme.muted)),
    SwitchListTile(contentPadding: EdgeInsets.zero, dense: true, title: const Text('固定当前预设', style: TextStyle(fontSize: 12)), value: _preset != null, onChanged: (value) { setState(() => _preset = value ? widget.preset.name : null); _emit(); }),
    if (widget.worldBooks.isNotEmpty) ...[
      const Text('本会话启用的世界书', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      ...widget.worldBooks.map((book) => CheckboxListTile(contentPadding: EdgeInsets.zero, dense: true, title: Text(book.name, style: const TextStyle(fontSize: 11)), subtitle: Text('${book.entries.length} 个条目', style: const TextStyle(fontSize: 10)), value: _books.contains(book.name), onChanged: (value) { setState(() { if (value == true) _books.add(book.name); else _books.remove(book.name); }); _emit(); })),
    ] else const Padding(padding: EdgeInsets.only(top: 6), child: Text('暂无全局世界书，角色卡 Character Book 仍会参与注入。', style: TextStyle(fontSize: 10, color: SuicangTheme.muted))),
  ]));
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.character, required this.onTap});
  final CharacterProfile character;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: SuicangTheme.soft, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(gradient: SuicangTheme.brandGradient, borderRadius: BorderRadius.circular(15)), child: Center(child: Text(character.emoji, style: const TextStyle(fontSize: 25)))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(character.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), const SizedBox(height: 3), Text(character.subtitle, style: const TextStyle(fontSize: 11, color: SuicangTheme.muted)), const SizedBox(height: 5), Text(character.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.3))])), const Icon(Icons.chevron_right_rounded, color: SuicangTheme.muted)]),
        ),
      );
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, size: 17, color: SuicangTheme.primary), const SizedBox(width: 7), Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))]);
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.depth, required this.selected, required this.onTap, required this.onRename, required this.onDelete, this.onParent});
  final ChatSessionSummary session;
  final int depth;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onParent;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        contentPadding: EdgeInsets.only(left: 10 + depth * 18, right: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: selected ? SuicangTheme.soft : null,
        leading: Icon(selected ? Icons.chat_bubble : Icons.chat_bubble_outline, size: 18, color: selected ? SuicangTheme.primary : SuicangTheme.muted),
        title: Text(session.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        subtitle: Text(session.parentSessionId == null ? session.preview : '分支起点：${session.preview}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: SuicangTheme.muted)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (session.parentSessionId != null) const Icon(Icons.account_tree_outlined, size: 16, color: SuicangTheme.primary), if (selected) const Icon(Icons.check_circle, size: 17, color: SuicangTheme.primary), PopupMenuButton<String>(onSelected: (value) { if (value == 'parent' && onParent != null) onParent!(); if (value == 'rename') onRename(); if (value == 'delete') onDelete(); }, itemBuilder: (_) => [if (onParent != null) const PopupMenuItem(value: 'parent', child: Text('跳转到父会话')), const PopupMenuItem(value: 'rename', child: Text('重命名')), const PopupMenuItem(value: 'delete', child: Text('删除'))])]),
        onTap: onTap,
      );
}

class _PersonaEditor extends StatelessWidget {
  const _PersonaEditor({required this.persona, required this.onChanged});
  final UserPersona persona;
  final ValueChanged<UserPersona> onChanged;

  @override
  Widget build(BuildContext context) => Column(children: [TextFormField(initialValue: persona.name, decoration: const InputDecoration(labelText: '显示名称', prefixIcon: Icon(Icons.person_outline)), onChanged: (value) => onChanged(persona.copyWith(name: value))), const SizedBox(height: 10), TextFormField(initialValue: persona.description, maxLines: 2, decoration: const InputDecoration(labelText: '身份描述', prefixIcon: Icon(Icons.notes_outlined)), onChanged: (value) => onChanged(persona.copyWith(description: value)))]);
}


class _GreetingPicker extends StatelessWidget {
  const _GreetingPicker({required this.greetings, required this.onSelected});
  final List<String> greetings;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('替代开场白', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        ...greetings.asMap().entries.map((item) => ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              leading: CircleAvatar(radius: 13, backgroundColor: SuicangTheme.soft, child: Text('${item.key + 1}', style: const TextStyle(fontSize: 11, color: SuicangTheme.primary))),
              title: Text(item.value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.35)),
              onTap: () => onSelected(item.value),
            )),
      ]);
}
