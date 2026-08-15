import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/suicang_theme.dart';
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
        GoRoute(
            path: '/characters', builder: (_, __) => const CharactersScreen()),
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
    final index = ['/discover', '/chat', '/characters', '/settings']
        .indexWhere(location.startsWith);
    final wide = MediaQuery.sizeOf(context).width >= 820;
    final destinations = const [
      NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '发现'),
      NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: '聊天'),
      NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: '角色'),
      NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: '设置'),
    ];
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: index < 0 ? 0 : index,
                onDestinationSelected: (i) => context
                    .go(['/discover', '/chat', '/characters', '/settings'][i]),
                labelType: NavigationRailLabelType.all,
                backgroundColor: Theme.of(context).colorScheme.surface,
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        gradient: SuicangTheme.brandGradient,
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 21),
                  ),
                ),
                destinations: destinations
                    .map((destination) => NavigationRailDestination(
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon,
                          label: Text(destination.label),
                        ))
                    .toList(),
              ),
            Expanded(
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: child,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              height: 72,
              elevation: 0,
              backgroundColor:
                  Theme.of(context).colorScheme.surface.withOpacity(.96),
              indicatorColor: const Color(0xFFEEEAFD),
              labelTextStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              selectedIndex: index < 0 ? 0 : index,
              onDestinationSelected: (i) => context
                  .go(['/discover', '/chat', '/characters', '/settings'][i]),
              destinations: destinations,
            ),
    );
  }
}
