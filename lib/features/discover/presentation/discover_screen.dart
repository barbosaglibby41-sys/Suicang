import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/suicang_theme.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) => CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: _Header()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _Greeting(),
                const SizedBox(height: 18),
                _HeroCard(onTap: () => context.go('/chat')),
                const SizedBox(height: 24),
                const _SectionHeader(title: '快速开始', action: '全部'),
                const SizedBox(height: 11),
                const _QuickActions(),
                const SizedBox(height: 24),
                const _SectionHeader(title: '继续对话', action: '查看历史'),
                const SizedBox(height: 11),
                const _ContinueCard(),
                const SizedBox(height: 24),
                const _SectionHeader(title: '我的角色', action: '管理角色'),
                const SizedBox(height: 11),
                const _CharacterRail(),
              ]),
            ),
          ),
        ],
      );
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
        child: Row(children: [
          Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: SuicangTheme.ink,
                  borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 21)),
          const SizedBox(width: 12),
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Suicang',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('你的 AI 创作空间',
                    style: TextStyle(fontSize: 11, color: SuicangTheme.muted))
              ])),
          _IconButton(icon: Icons.search, onTap: () {}),
          const SizedBox(width: 8),
          _IconButton(icon: Icons.tune_rounded, onTap: () {}),
        ]),
      );
}

class _Greeting extends StatelessWidget {
  const _Greeting();
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.only(top: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('星期六，8 月 15 日',
            style: TextStyle(fontSize: 13, color: SuicangTheme.muted)),
        SizedBox(height: 7),
        Text('今天想和谁\n开始一段故事？',
            style: TextStyle(
                fontSize: 29, height: 1.08, fontWeight: FontWeight.w800))
      ]));
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
      height: 198,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: SuicangTheme.heroGradient,
          borderRadius: BorderRadius.circular(18)),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CONTINUE CREATING',
              style: TextStyle(
                  color: Colors.white.withOpacity(.65),
                  fontSize: 10,
                  letterSpacing: 1.5)),
          const SizedBox(height: 9),
          const Text('让灵感，\n从一句话开始。',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('探索角色、世界与无限可能。',
              style: TextStyle(
                  color: Colors.white.withOpacity(.65), fontSize: 12)),
          const Spacer(),
          FilledButton.tonal(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: SuicangTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('＋ 新建对话',
                  style: TextStyle(fontWeight: FontWeight.w700)))
        ]),
        Positioned(
            right: 6,
            bottom: 4,
            child: Icon(Icons.auto_awesome,
                color: Colors.white.withOpacity(.22), size: 78))
      ]));
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});
  final String title;
  final String action;
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const Spacer(),
        Text('$action  ›',
            style: const TextStyle(
                color: SuicangTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12))
      ]);
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _QuickChip(icon: Icons.auto_awesome, label: '角色扮演', active: true),
        SizedBox(width: 9),
        _QuickChip(icon: Icons.edit_note, label: '灵感写作'),
        SizedBox(width: 9),
        _QuickChip(icon: Icons.question_answer_outlined, label: '问答助手')
      ]));
}

class _QuickChip extends StatelessWidget {
  const _QuickChip(
      {required this.icon, required this.label, this.active = false});
  final IconData icon;
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
          color: active
              ? SuicangTheme.soft
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active
                  ? SuicangTheme.primary.withOpacity(.25)
                  : SuicangTheme.line)),
      child: Row(children: [
        Icon(icon,
            size: 17, color: active ? SuicangTheme.primary : SuicangTheme.ink),
        const SizedBox(width: 7),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? SuicangTheme.primary : SuicangTheme.ink))
      ]));
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SuicangTheme.line)),
      child: Row(children: [
        Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                gradient: SuicangTheme.brandGradient,
                borderRadius: BorderRadius.circular(14)),
            child: const Center(
                child: Text('🌙', style: TextStyle(fontSize: 26)))),
        const SizedBox(width: 12),
        const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Luna · 月光下的旅人',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          SizedBox(height: 5),
          Text('“如果明天就要出发，你会带上什么…”',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: SuicangTheme.muted)),
          SizedBox(height: 9),
          LinearProgressIndicator(
              value: .64,
              minHeight: 4,
              borderRadius: BorderRadius.all(Radius.circular(4)),
              color: SuicangTheme.primary,
              backgroundColor: SuicangTheme.line)
        ])),
        const SizedBox(width: 10),
        const Icon(Icons.arrow_forward_rounded,
            size: 19, color: SuicangTheme.primary)
      ]));
}

class _CharacterRail extends StatelessWidget {
  const _CharacterRail();
  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _CharacterCard(
            emoji: '🦋',
            name: 'Aria',
            tag: '幻想 · 冒险',
            colors: [Color(0xFF9B6655), Color(0xFF4A3935)]),
        SizedBox(width: 12),
        _CharacterCard(
            emoji: '🧙',
            name: '老法师',
            tag: '奇幻 · 故事',
            colors: [Color(0xFFE4A38E), Color(0xFF8066A9)]),
        SizedBox(width: 12),
        _CharacterCard(
            emoji: '🤖',
            name: 'Nova',
            tag: '科幻 · 助手',
            colors: [Color(0xFF5B9B9A), Color(0xFF2D4C66)])
      ]));
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard(
      {required this.emoji,
      required this.name,
      required this.tag,
      required this.colors});
  final String emoji;
  final String name;
  final String tag;
  final List<Color> colors;
  @override
  Widget build(BuildContext context) => Container(
      width: 137,
      height: 124,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors),
          borderRadius: BorderRadius.circular(16)),
      child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(left: 0, bottom: 30, child: Text(emoji, style: const TextStyle(fontSize: 32))),
            Positioned(left: 0, bottom: 14, child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800))),
            Positioned(left: 0, bottom: 0, child: Text(tag, style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 10))),
          ]));
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: SuicangTheme.muted,
          fixedSize: const Size(38, 38),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: SuicangTheme.line))));
}
