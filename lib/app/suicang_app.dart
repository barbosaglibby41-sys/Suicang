import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import '../core/theme/suicang_theme.dart';

class SuicangApp extends ConsumerWidget {
  const SuicangApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Suicang',
      debugShowCheckedModeBanner: false,
      theme: SuicangTheme.light,
      darkTheme: SuicangTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: suicangRouter,
    );
  }
}
