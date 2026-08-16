import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/characters/presentation/characters_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

final suicangRouter = GoRouter(
  initialLocation: '/discover',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
        GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
        GoRoute(path: '/characters', builder: (_, __) => const CharactersScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = ['/discover', '/chat', '/characters', '/settings'].indexWhere(location.startsWith);
    const paths = ['/discover', '/chat', '/characters', '/settings'];
    const icons = [Icons.explore_outlined, Icons.forum_outlined, Icons.auto_awesome_outlined, Icons.tune_rounded];
    const labels = ['此刻', '对话', '角色', '控制'];
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(child: child),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    height: 62,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(.82),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.45)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 26, offset: const Offset(0, 10))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(4, (i) => _NavItem(
                        icon: icons[i], label: labels[i], selected: i == (index < 0 ? 0 : index), onTap: () => context.go(paths[i]),
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkResponse(
      onTap: onTap,
      radius: 30,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: selected ? const Color(0xFF6956E8) : Colors.transparent, borderRadius: BorderRadius.circular(15)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant),
          AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: selected ? Padding(key: const ValueKey('label'), padding: const EdgeInsets.only(left: 7), child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))) : const SizedBox(key: ValueKey('empty'))),
        ]),
      ),
    ),
  );
}
