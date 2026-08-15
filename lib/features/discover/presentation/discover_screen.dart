import 'package:flutter/material.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverAppBar.large(
        title: const Text('Suicang'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search)), IconButton(onPressed: () {}, icon: const Icon(Icons.menu))],
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        sliver: SliverList(delegate: SliverChildListDelegate([
          Text('今天想和谁', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text('开始一段故事？', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: const Color(0xFF6C5CE7), fontWeight: FontWeight.w800)),
          const SizedBox(height: 22),
          _HeroCard(onTap: () {}),
          const SizedBox(height: 28),
          _Section(title: '快速开始', children: const [Chip(label: Text('✦  角色扮演')), Chip(label: Text('☄  灵感写作')), Chip(label: Text('⌘  问答助手'))]),
          const SizedBox(height: 26),
          _Section(title: '继续对话', children: [_ContinueCard()]),
          const SizedBox(height: 26),
          _Section(title: '我的角色', children: const [_CharacterCard(emoji: '🦋', name: 'Aria'), _CharacterCard(emoji: '🧙', name: '老法师'), _CharacterCard(emoji: '🤖', name: 'Nova')]),
        ])),
      ),
    ],
  );
}

class _HeroCard extends StatelessWidget { const _HeroCard({required this.onTap}); final VoidCallback onTap; @override Widget build(BuildContext c) => Card(color: const Color(0xFF39335D), child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('CONTINUE CREATING', style: TextStyle(color: Colors.white.withOpacity(.7), letterSpacing: 1.5)), const SizedBox(height: 10), const Text('让灵感，\n从一句话开始。', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('探索角色、世界与无限可能。', style: TextStyle(color: Colors.white.withOpacity(.7))), const SizedBox(height: 18), FilledButton(onPressed: onTap, child: const Text('＋ 新建对话'))]))); }
class _Section extends StatelessWidget { const _Section({required this.title, required this.children}); final String title; final List<Widget> children; @override Widget build(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: c.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 12), Wrap(spacing: 10, runSpacing: 10, children: children)]); }
class _ContinueCard extends StatelessWidget { @override Widget build(BuildContext c) => Card(child: ListTile(contentPadding: const EdgeInsets.all(10), leading: const CircleAvatar(radius: 28, child: Text('🌙', style: TextStyle(fontSize: 25))), title: const Text('Luna · 月光下的旅人', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('“如果明天就要出发，你会带上什么…”'), trailing: const Icon(Icons.chevron_right))); }
class _CharacterCard extends StatelessWidget { const _CharacterCard({required this.emoji, required this.name}); final String emoji, name; @override Widget build(BuildContext c) => SizedBox(width: 125, height: 130, child: Card(color: const Color(0xFF7661D2), child: Padding(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [Text(emoji, style: const TextStyle(fontSize: 36)), Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))); }
