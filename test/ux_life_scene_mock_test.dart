// A mock of "A Life Before This One" played as scene pages (UX, for the user
// to approve before anything is built): each memory is a page like the story
// reader's, with a side-view backdrop of the memory's place from the existing
// kits (the street kit for the gutter behind the rope-walk, the frost kit for
// the frozen well), the text set in the reader's prose (it writes itself out
// in the real thing), the answers as choice cards with their stat chip, and
// the age rail kept small under the picture. The words are the real memories'.
// UX_SHOTS=<folder> takes docs/ux-shots/life-scenes-mock.png.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/climate.dart' show WeatherKind;
import 'package:narrative_data_app/data/journey_rules.dart' show DayPhase;
import 'package:narrative_data_app/data/origin_stories.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/ability_visuals.dart';
import 'package:narrative_data_app/widgets/side_view/frost_kit.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';
import 'package:narrative_data_app/widgets/street_view/street_view.dart';

Future<void> _loadFonts() async {
  const families = {
    'PixelifySans': [
      'assets/fonts/PixelifySans-Regular.ttf',
      'assets/fonts/PixelifySans-SemiBold.ttf',
    ],
    'Spectral': [
      'assets/fonts/Spectral-Regular.ttf',
      'assets/fonts/Spectral-Medium.ttf',
      'assets/fonts/Spectral-Italic.ttf',
    ],
    'IMFellEnglishSC': ['assets/fonts/IMFellEnglishSC-Regular.ttf'],
  };
  for (final family in families.entries) {
    final loader = FontLoader(family.key);
    for (final path in family.value) {
      loader.addFont(Future.value(ByteData.view(
          Uint8List.fromList(File(path).readAsBytesSync()).buffer)));
    }
    await loader.load();
  }
  final icons = File(
      '/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(
          ByteData.view(Uint8List.fromList(icons.readAsBytesSync()).buffer)));
    await loader.load();
  }
}

/// The age rail, small: six dots with the ages, the memory's own larger.
class _Rail extends StatelessWidget {
  const _Rail({required this.ages, required this.current});

  final List<int> ages;
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(children: [
      for (var i = 0; i < ages.length; i++) ...[
        if (i > 0)
          Expanded(
            child: Container(
              height: 1.5,
              margin: const EdgeInsets.only(bottom: 14),
              color: i <= current
                  ? colors.primary.withValues(alpha: 0.5)
                  : colors.outlineVariant,
            ),
          ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: i == current ? 14 : 10,
            height: i == current ? 14 : 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < current ? colors.primary : colors.surface,
              border: Border.all(
                  color: i <= current ? colors.primary : colors.outline,
                  width: i == current ? 2.5 : 1.2),
            ),
          ),
          const SizedBox(height: 2),
          Text('${ages[i]}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: i == current
                    ? colors.primary
                    : colors.onSurface.withValues(alpha: 0.7),
                fontWeight: i == current ? FontWeight.w700 : null,
              )),
        ]),
      ],
    ]);
  }
}

/// One memory as a scene page.
class _MemoryPage extends StatelessWidget {
  const _MemoryPage({
    required this.memory,
    required this.backdrop,
    required this.index,
    this.firstPage = false,
    this.typed = 1.0,
  });

  final OriginMemory memory;
  final Widget backdrop;
  final int index;
  final bool firstPage;

  /// How much of the text has been written (the real page types it out).
  final double typed;

  static const _ages = [6, 8, 10, 12, 14, 16];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final scene = memory.sceneEn;
    final shown = scene.substring(0, (scene.length * typed).round());
    return Scaffold(
      appBar: AppBar(title: const Text('A Life Before This One')),
      body: Column(children: [
        // The backdrop, fading into the page.
        SizedBox(
          height: 210,
          child: Stack(fit: StackFit.expand, children: [
            backdrop,
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.55, 1],
                  colors: [Colors.transparent, colors.surface],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'AGE ${memory.age} · ${memory.isChildhood ? 'CHILDHOOD' : 'ADOLESCENCE'}',
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.primary,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600)),
                  Text(memory.titleEn, style: theme.textTheme.headlineSmall),
                ],
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: _Rail(ages: _ages, current: index),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            children: [
              // The scene in the reader's prose, no card around it.
              Text(
                shown,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontSize: 18, height: 1.6, letterSpacing: 0.1),
              ),
              const SizedBox(height: 16),
              // The answers come when the text has been written (a tap
              // finishes it, as in the reader).
              if (typed < 1)
                Center(
                  child: Text('tap to finish',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.5))),
                )
              else
                for (final a in memory.answers) ...[
                  Material(
                    color: colors.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.en,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontSize: 16.5, height: 1.35)),
                          const SizedBox(height: 8),
                          AbilityPill(
                            icon: abilityIcon(a.ability),
                            label:
                                '+1 ${a.ability[0].toUpperCase()}${a.ability.substring(1)}',
                            color: colors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              if (firstPage)
                Center(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.casino_outlined, size: 18),
                    label: const Text('Choose my whole life at random'),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('a picture of two memories as scene pages (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    final sparrow =
        originMemoriesFor(raceId: 'human', professionId: 'warrior').first;
    final well =
        originMemoriesFor(raceId: 'voidkin', professionId: 'warrior')[1];
    tester.view.physicalSize = const Size(1600, 1900);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    final theme = buildAppTheme(const ColorScheme.dark());
    Widget phone(Widget page) => SizedBox(
          width: 390,
          height: 950,
          child: Theme(
            data: theme,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(390, 950)),
              child: ClipRect(child: Navigator(onGenerateRoute: (_) {
                return MaterialPageRoute<void>(builder: (_) => page);
              })),
            ),
          ),
        );
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        body: RepaintBoundary(
          key: key,
          child: Row(children: [
            phone(_MemoryPage(
              memory: sparrow,
              index: 0,
              firstPage: true,
              backdrop: StreetViewScene(
                kind: 'warehouse',
                name: 'The rope-walk',
                phase: DayPhase.day,
                sky: WeatherKind.rain,
              ),
            )),
            const SizedBox(width: 20),
            phone(_MemoryPage(
              memory: well,
              index: 1,
              typed: 0.62,
              backdrop: SideViewScene(
                layers: frostLayers(progress: 0.3),
                particles: SideParticles.snow,
                moving: false,
                height: 210,
              ),
            )),
          ]),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/life-scenes-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}
