import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_info.dart';
import 'providers/palette_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'screens/main_menu_screen.dart';

void main() {
  // The world map's pixel font is under the SIL Open Font License, which
  // asks that its licence travel with it: it shows in the app's licences.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['Pixelify Sans'],
      await rootBundle.loadString('assets/fonts/PixelifySans-OFL.txt'),
    );
  });
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(appPaletteProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: AppInfo.displayName,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: palette.seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: palette.seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      builder: (context, child) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}
