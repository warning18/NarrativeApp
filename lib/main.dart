import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_info.dart';
import 'providers/palette_provider.dart';
import 'screens/home_shell.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(appPaletteProvider);
    return MaterialApp(
      title: AppInfo.displayName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: palette.seedColor),
        useMaterial3: true,
      ),
      builder: (context, child) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: const HomeShell(),
    );
  }
}
