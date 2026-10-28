// The built intro (v1.583, intro_screen.dart) as one moving picture: the real
// IntroScreen stepped frame by frame in the test clock, the title and the four
// lines included, then the fade into the Race and Profession screen. Written
// as PNG frames and joined into docs/ux-shots/intro-anim.gif with ffmpeg. Only
// with UX_ANIM (a folder):
//   UX_ANIM=/tmp/intro flutter test test/ux_intro_anim_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/screens/intro_screen.dart';
import 'package:narrative_data_app/screens/race_profession_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/story_text.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
    (
      'Spectral',
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('assets/fonts/$f');
      if (!file.existsSync()) continue;
      loader
          .addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    }
    await loader.load();
  }
  final icons = File(
      '/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await loader.load();
  }
}

void main() {
  final dir = Platform.environment['UX_ANIM'];
  if (dir == null) {
    test('the intro animation is rendered only with UX_ANIM', () {});
    return;
  }

  testWidgets('the intro, animated', (tester) async {
    await tester.runAsync(_loadFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    // The lines write themselves, as they do in play.
    storyTypewriterOn = true;
    addTearDown(() => storyTypewriterOn = false);
    const width = 412.0, height = 732.0;
    tester.view.physicalSize = const Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Directory(dir).createSync(recursive: true);
    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light));
    final nav = GlobalKey<NavigatorState>();
    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          navigatorKey: nav,
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: const Scaffold(backgroundColor: Colors.black),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));

    // The way the menu does it: the intro over the menu, then the game.
    var introDone = false;
    nav.currentState!
        .push(PageRouteBuilder<bool>(
          transitionDuration: Duration.zero,
          pageBuilder: (_, __, ___) => const IntroScreen(),
        ))
        .then((_) => introDone = true);
    // Let its pictures decode before the clock is read.
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }

    const fps = 15;
    const step = Duration(microseconds: 1000000 ~/ fps);
    var n = 0;
    Future<void> shoot() async {
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$dir/f_${(n++).toString().padLeft(4, '0')}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    var guard = 0;
    while (!introDone && guard++ < 400) {
      await shoot();
      await tester.pump(step);
    }
    expect(introDone, isTrue);

    // Then the game: the Race and Profession screen, as the page route brings it.
    nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const RaceProfessionScreen()));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(step);
    }
    for (var i = 0; i < fps * 2; i++) {
      await shoot();
      await tester.pump(step);
    }

    await tester.runAsync(() async {
      final r = await Process.run('ffmpeg', [
        '-y',
        '-framerate',
        '$fps',
        '-i',
        '$dir/f_%04d.png',
        '-vf',
        'split[a][b];[a]palettegen=max_colors=96:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle',
        '-loop',
        '0',
        '$dir/intro-anim.gif',
      ]);
      expect(r.exitCode, 0, reason: '${r.stderr}');
    });
  });
}
