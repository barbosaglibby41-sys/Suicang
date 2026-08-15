import 'package:flutter/material.dart';
import '../../../core/theme/suicang_theme.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _Header(colors: colors)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _Greeting(),
              const SizedBox(height: 22),
              _HeroCard(onTap: () {}),
              const SizedBox(height: 28),
              _SectionHeader(title: '快速开始', action: '全部'),
              const SizedBox(height: 12),
              const _QuickActions(),
              const SizedBox(height: 28),
              _SectionHeader(title: '继续对话', action: '查看历史'),
              const SizedBox(height: 12),
              const _ContinueCard(),
              const SizedBox(height: 28),
              _SectionHeader(title: '我的角色', action: '管理角色'),
              const SizedBox(height: 12),
              const _CharacterRail(),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.colors});
  final ColorScheme colors;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
    child: Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(gradient: SuicangTheme.brandGradient, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: SuicangTheme.primary.withOpacity(.25), blurRadius: 16, offset: const Offset(0, 7))]), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Suicang', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -.5)), SizedBox(height: 2), Text('你的 AI 创作空间', style: TextStyle(fontSize: 11, color: SuicangTheme.muted))])),
      _IconButton(icon: Icons.search, onTap: () {}), const SizedBox(width: 9), _IconButton(icon: Icons.menu_rounded, onTap: () {}),
    ]),
  );
}

class _Greeting extends StatelessWidget {
  const _Greeting();
  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.only(top: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('星期六，8 月 15 日', style: TextStyle(fontSize: 14, color: SuicangTheme.muted)), SizedBox(height: 7), Text('今天想和谁\n开始一段故事？', style: TextStyle(fontSize: 30, height: 1.08, fontWeight: FontWeight.w800, letterSpacing: -1.2))]));
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap}); final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(height: 180, padding: const EdgeInsets.all(21), decoration: BoxDecoration(gradient: SuicangTheme.heroGradient, borderRadius: BorderRadius.circular(27), boxShadow: [BoxShadow(color: const Color(0xFF39335D).withOpacity(.18), blurRadius: 24, offset: const Offset(0, 10))]), child: Stack(children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('CONTINUE CREATING', style: TextStyle(color: Colors.white.withOpacity(.72), fontSize: 11, letterSpacing: 1.6)), const SizedBox(height: 10), const Text('让灵感，\n从一句话开始。', style: TextStyle(color: Colors.white, fontSize: 22, height: 1.2, fontWeight: FontWeight.w800)), const SizedBox(height: 7), Text('探索角色、世界与无限可能。', style: TextStyle(color: Colors.white.withOpacity(.72), fontSize: 12)), const Spacer(), FilledButton.tonal(onPressed: onTap, style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: SuicangTheme.primary, padding: const EdgeInsets.symmetric(horizontal: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))), child: const Text('＋ 新建对话', style: TextStyle(fontWeight: FontWeight.w700)))]), Positioned(right: 4, bottom: 5, child: Transform.rotate(angle: .2, child: Container(width: 68, height: 68, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD5BA), Color(0xFFF0A6B8)]), borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 31))))]));
}

class _SectionHeader extends StatelessWidget { const _SectionHeader({required this.title, required this.action}); final String title, action; @override Widget build(BuildContext context) => Row(children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const Spacer(), TextButton(onPressed: () {}, style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: Text('$action  ›', style: const TextStyle(color: SuicangTheme.primary, fontWeight: FontWeight.w700, fontSize: 12)))]); }

class _QuickActions extends StatelessWidget { const _QuickActions(); @override Widget build(BuildContext context) => const SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_QuickChip(icon: Icons.auto_awesome, label: '角色扮演', active: true), SizedBox(width: 9), _QuickChip(icon: Icons.edit_note, label: '灵感写作'), SizedBox(width: 9), _QuickChip(icon: Icons.question_answer_outlined, label: '问答助手')])); }
class _QuickChip extends StatelessWidget { const _QuickChip({required this.icon, required this.label, this.active = false}); final IconData icon; final String label; final bool active; @override Widget build(BuildContext context) => Container padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: active ? SuicangTheme.soft : Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? SuicangTheme.primary.withOpacity(.2) : SuicangTheme.line)), child: Row(children: [Icon(icon, size: 18, color: active ? SuicangTheme.primary : SuicangTheme.ink), const SizedBox(width: 8), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? SuicangTheme.primary : SuicangTheme.ink))]); }
}

class _ContinueCard extends StatelessWidget { const _ContinueCard(); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(21), border: Border.all(color: SuicangTheme.line), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.035), blurRadius: 16, offset: const Offset(0, 6))]), child: Row(children: [Container(width: 58, height: 58, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFC9B1FF), Color(0xFFF1C5D6)]), borderRadius: BorderRadius.circular(18)), child: const Center(child: Text('🌙', style: TextStyle(fontSize: 27)))), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Luna · 月光下的旅人', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('“如果明天就要出发，你会带上什么…”', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: SuicangTheme.muted)), SizedBox(height: 9), LinearProgressIndicator(value: .64, minHeight: 4, borderRadius: BorderRadius.all(Radius.circular(4)), color: SuicangTheme.primary, backgroundColor: SuicangTheme.line)])), const SizedBox(width: 10), Container(width: 32, height: 32, decoration: BoxDecoration(color: SuicangTheme.soft, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.chevron_right, color: SuicangTheme.primary))])); }

class _CharacterRail extends StatelessWidget { const _CharacterRail(); @override Widget build(BuildContext context) => const SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_CharacterCard(emoji: '🦋', name: 'Aria', tag: '幻想 · 冒险', colors: [Color(0xFF816BDC), Color(0xFF4A416B)]), SizedBox(width: 12), _CharacterCard(emoji: '🧙', name: '老法师', tag: '奇幻 · 故事', colors: [Color(0xFFE4A38E), Color(0xFF8066A9)]), SizedBox(width: 12), _CharacterCard(emoji: '🤖', name: 'Nova', tag: '科幻 · 助手', colors: [Color(0xFF5B9B9A), Color(0xFF2D4C66)])])); }
class _CharacterCard extends StatelessWidget { const _CharacterCard({required this.emoji, required this.name, required this.tag, required this.colors}); final String emoji, name, tag; final List<Color> colors; @override Widget build(BuildContext context) => Container(width: 137, height: 150, padding: const EdgeInsets.all(13), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors), borderRadius: BorderRadius.circular(21)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [Text(emoji, style: const TextStyle(fontSize: 39)), const SizedBox(height: 6), Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(tag, style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 10))])); }
class _IconButton extends StatelessWidget { const _IconButton({required this.icon, required this.onTap}); final IconData icon; final VoidCallback onTap; @override Widget build(BuildContext context) => IconButton(onPressed: onTap, icon: Icon(icon, size: 20), style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface, foregroundColor: SuicangTheme.muted, fixedSize: const Size(38, 38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: SuicangTheme.line)))); }
