import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/suicang_theme.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
          sliver: SliverList(delegate: SliverChildListDelegate([
            const _TopBar(),
            const SizedBox(height: 38),
            const _Welcome(),
            const SizedBox(height: 26),
            _StoryStage(onTap: () => context.go('/chat')),
            const SizedBox(height: 34),
            _SectionTitle(title: '最近相遇', action: '全部'),
            const SizedBox(height: 14),
            _RecentStory(onTap: () => context.go('/chat')),
            const SizedBox(height: 34),
            const _SectionTitle(title: '为你准备的角色', action: '探索'),
            const SizedBox(height: 14),
            const _CharacterRail(),
          ])),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 36, height: 36, decoration: BoxDecoration(gradient: SuicangTheme.brandGradient, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 19)),
    const SizedBox(width: 10),
    const Text('suicang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    const Spacer(),
    IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded, size: 22)),
    IconButton(onPressed: () {}, icon: const Icon(Icons.account_circle_outlined, size: 24)),
  ]);
}

class _Welcome extends StatelessWidget {
  const _Welcome();
  @override
  Widget build(BuildContext context) => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('星期六，8 月 16 日', style: TextStyle(color: SuicangTheme.muted, fontSize: 13, fontWeight: FontWeight.w600)),
    SizedBox(height: 9),
    Text('今天，\n想让谁走进你的故事？', style: TextStyle(fontSize: 31, height: 1.08, fontWeight: FontWeight.w800)),
  ]);
}

class _StoryStage extends StatelessWidget {
  const _StoryStage({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AspectRatio(aspectRatio: 1.12, child: GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(gradient: SuicangTheme.heroGradient, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF332B62).withOpacity(.24), blurRadius: 30, offset: const Offset(0, 14))]),
    child: Stack(children: [
      Positioned(right: -18, top: -18, child: Container(width: 190, height: 190, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFB3A1FF).withOpacity(.12)))),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONTINUE A STORY', style: TextStyle(color: Colors.white.withOpacity(.56), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.7)),
        const Spacer(),
        const Text('月光下的\n旅人', style: TextStyle(color: Colors.white, fontSize: 29, height: 1.03, fontWeight: FontWeight.w800)),
        const SizedBox(height: 9),
        Text('Luna 还在旧城的窗边等你。', style: TextStyle(color: Colors.white.withOpacity(.68), fontSize: 12)),
        const SizedBox(height: 20),
        Row(children: [
          FilledButton.icon(onPressed: onTap, icon: const Icon(Icons.play_arrow_rounded, size: 18), label: const Text('继续对话'), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF4F3CA8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11))),
          const SizedBox(width: 10),
          Text('64% 完成', style: TextStyle(color: Colors.white.withOpacity(.62), fontSize: 11)),
        ]),
      ]),
      const Positioned(right: 22, top: 35, child: Text('🌙', style: TextStyle(fontSize: 64))),
    ]),
  )));
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});
  final String title, action;
  @override
  Widget build(BuildContext context) => Row(children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const Spacer(), Text(action, style: const TextStyle(color: SuicangTheme.primary, fontSize: 12, fontWeight: FontWeight.w700))]);
}

class _RecentStory extends StatelessWidget {
  const _RecentStory({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: SuicangTheme.line)), child: Row(children: [
    Container(width: 56, height: 56, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFB09AFF), Color(0xFFEBC6D7)]), borderRadius: BorderRadius.circular(15)), child: const Center(child: Text('🌙', style: TextStyle(fontSize: 28)))),
    const SizedBox(width: 13),
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Luna · 月光下的旅人', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), SizedBox(height: 5), Text('“我会带上一盏灯。”', style: TextStyle(color: SuicangTheme.muted, fontSize: 12)), SizedBox(height: 9), LinearProgressIndicator(value: .64, minHeight: 3, borderRadius: BorderRadius.all(Radius.circular(4)), color: SuicangTheme.primary, backgroundColor: SuicangTheme.line)])),
    const SizedBox(width: 9), const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: SuicangTheme.muted),
  ])));
}

class _CharacterRail extends StatelessWidget {
  const _CharacterRail();
  @override
  Widget build(BuildContext context) => const SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
    _CharacterCard(emoji: '🦋', name: 'Aria', subtitle: '星海观测者', colors: [Color(0xFF8376D8), Color(0xFF302952)]),
    SizedBox(width: 12), _CharacterCard(emoji: '🤖', name: 'Nova', subtitle: '实验助手', colors: [Color(0xFF76B1AE), Color(0xFF203F52)]),
    SizedBox(width: 12), _CharacterCard(emoji: '🧙', name: '老法师', subtitle: '奇幻故事', colors: [Color(0xFFDB9C84), Color(0xFF5B3C65)]),
  ]));
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.emoji, required this.name, required this.subtitle, required this.colors});
  final String emoji, name, subtitle; final List<Color> colors;
  @override
  Widget build(BuildContext context) => Container(width: 152, height: 180, padding: const EdgeInsets.all(15), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors), borderRadius: BorderRadius.circular(19)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [Text(emoji, style: const TextStyle(fontSize: 48)), const SizedBox(height: 10), Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(.62), fontSize: 11))]));
}
