// Mock: Vica follows the hero's sprite (docs/proposals/vica-follows.md).
// The real scenes (the street at the door, the land walk's side view, the
// story page's strip) with a follower layer drawn in: the dog's own frames
// (assets/visuals/companion), placed beside the hero. Drawn only with
// UX_SHOTS (a folder):
//   UX_SHOTS=docs/ux-shots flutter test test/ux_vica_follow_mock_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/journey_rules.dart' show DayPhase;
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/providers/walking_party_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/side_view/desert_kit.dart';
import 'package:narrative_data_app/widgets/side_view/side_sprite.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';
import 'package:narrative_data_app/widgets/street_view/street_facade.dart';
import 'package:narrative_data_app/widgets/street_view/street_view.dart';

import 'ux_skills_mock_parts.dart' show NotesPanel;

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

const _dogRoot = 'assets/visuals/companion/dog_companion_animations';

Future<ui.Image> _decode(String path) async {
  final bytes = File(path).readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

/// The dog's frames, decoded once.
class _Dog {
  _Dog(this.sit, this.walk, this.bark, this.hero);
  final ui.Image sit;
  final List<ui.Image> walk;
  final ui.Image bark;

  /// The ronin standing, facing east (the hero on the page strip).
  final ui.Image hero;
}

Future<_Dog> _loadDog() async => _Dog(
      await _decode('$_dogRoot/Sitting_down/rotations/south.png'),
      [
        for (var i = 0; i < 8; i++)
          await _decode(
              '$_dogRoot/Walking/east/frame_${i.toString().padLeft(3, '0')}.png'),
      ],
      await _decode(
          '$_dogRoot/Fight_-_Attack/animations/Bark/south/frame_002.png'),
      await _decode('assets/visuals/walker/ronin_idle_east.png'),
    );

/// The follower as one small layer: [img] with its bottom edge on [feet] and
/// its middle on [x], in scene pixels; [upp] scene pixels per source pixel
/// (the same factor for every pose, as the page strip does, so the dog keeps
/// one size from pose to pose).
void _paintDog(
    ui.Canvas c, double u, ui.Image img, double x, double feet, double upp,
    {bool west = false, double lift = 0}) {
  final w = img.width * upp, h = img.height * upp;
  final dst =
      Rect.fromLTWH((x - w / 2) * u, (feet - h + lift) * u, w * u, h * u);
  final paint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;
  c.save();
  if (west) {
    c.translate(x * u * 2, 0);
    c.scale(-1, 1);
  }
  c.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      dst,
      paint);
  c.restore();
}

Widget _panel(String caption, double width, double height, Widget child) =>
    Column(children: [
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1F1C24),
          border: Border.all(color: const Color(0xFF3A3642), width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: width,
        child: Text(caption,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'Spectral',
                fontSize: 15,
                color: Color(0xFFEDE6DC))),
      ),
    ]);

Widget _title(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(text,
          style: const TextStyle(
              fontFamily: 'IMFellEnglishSC',
              fontSize: 22,
              color: Color(0xFFEDE6DC))),
    );

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  if (shots == null) {
    test('the Vica mock is drawn only with UX_SHOTS', () {});
    return;
  }

  setUp(rootBundle.clear);

  testWidgets('Vica follows the hero', (tester) async {
    await tester.runAsync(_loadFonts);
    SharedPreferences.setMockInitialValues({});
    final dog = (await tester.runAsync(_loadDog))!;
    await tester.runAsync(SideSprites.preload);
    const width = 320.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light));

    // The street at the door, the way the intro and the journey draw it.
    const kind = 'tavern', name = 'The Blind Beggar';
    final style = facadeStyleOf(kind, name);
    Widget street(void Function(ui.Canvas, double, double, double)? dogAt) =>
        SideViewScene(
          layers: streetLayers(style: style, phase: DayPhase.day, sky: null),
          actors: SideLayer(0, (c, s, scroll, t, u) {
            streetParty(style: style).paint(c, s, scroll, t, u);
            final box = facadeBoxFor(style, s.width / u, streetKerb);
            final heroX = (box.doorX - 14).floorToDouble();
            dogAt?.call(c, u, heroX, streetKerb + 5);
          }),
          overlay: streetOverlay(style: style, phase: DayPhase.day),
          moving: false,
          height: 230,
        );
    const streetUpp = 0.2;

    // The land walk's side view, the hero a ronin sprite and the party's
    // second figure Vica.
    Widget walk(
        {required bool moving,
        required bool dogSprite,
        bool inParty = true,
        double t = 0}) {
      final party = [
        const WalkingPartyMember(id: heroWalkerId, spriteKey: heroWalkerId),
        if (inParty && !dogSprite)
          const WalkingPartyMember(id: 'vica', spriteKey: 'companion_vica'),
      ];
      return SideViewScene(
        layers: desertLayers(),
        actors: SideLayer(0, (c, s, scroll, tt, u) {
          desertActors(party: party, moving: moving).paint(c, s, scroll, t, u);
          if (dogSprite) {
            final xs = walkingPartyXs(2);
            final img = moving ? dog.walk[(t * 10).floor() % 8] : dog.sit;
            _paintDog(c, u, img, xs[1] - 4, 66, 0.26, lift: moving ? 2 : 3);
          }
        }),
        moving: false,
        height: 230,
      );
    }

    Widget pageStrip(bool proposed) => Container(
          color: theme.scaffoldBackgroundColor,
          child: Column(children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Text(
                    'The tavern door stands open, and the smell of tallow and wet wool rolls out into the lane. Someone inside is laughing, badly.',
                    style: theme.textTheme.bodyMedium),
              ),
            ),
            if (proposed)
              Container(
                height: 118,
                width: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFF3A3642))),
                ),
                child: Stack(children: [
                  Positioned(
                    left: 40,
                    bottom: 0,
                    child: RawImage(
                        image: dog.hero,
                        width: dog.hero.width * 2.6,
                        height: dog.hero.height * 2.6,
                        filterQuality: FilterQuality.none),
                  ),
                  Positioned(
                    left: 40 + dog.hero.width * 2.6 + 2,
                    bottom: 10,
                    child: RawImage(
                        image: dog.sit,
                        width: dog.sit.width * 1.36,
                        height: dog.sit.height * 1.36,
                        filterQuality: FilterQuality.none),
                  ),
                ]),
              )
            else
              const SizedBox(height: 118),
          ]),
        );

    tester.view.physicalSize = const Size(width * 4 + 3 * 20 + 48 + 330, 1200);
    final board = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: board,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Material(
          color: const Color(0xFF17151B),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _title('The street, at the door'),
                Row(children: [
                  _panel('Today: the hero alone', width, 230, street(null)),
                  const SizedBox(width: 20),
                  _panel('Vica sits by the hero', width, 230,
                      street((c, u, x, feet) {
                    _paintDog(c, u, dog.sit, x - 9, feet, streetUpp, lift: 1);
                  })),
                  const SizedBox(width: 20),
                  _panel('Vica trots in behind', width, 230,
                      street((c, u, x, feet) {
                    _paintDog(c, u, dog.walk[3], x - 13, feet, streetUpp,
                        lift: 1);
                  })),
                  const SizedBox(width: 20),
                  _panel('Vica alert: a pin is picked', width, 230,
                      street((c, u, x, feet) {
                    _paintDog(c, u, dog.bark, x - 9, feet, streetUpp, lift: 1);
                  })),
                ]),
                const SizedBox(height: 16),
                _title('On the road (the land walk)'),
                Row(children: [
                  _panel('Today if Vica were in the party: a cloaked figure',
                      380, 230, walk(moving: true, dogSprite: false)),
                  const SizedBox(width: 20),
                  _panel('With her own frames: she trots behind', 380, 230,
                      walk(moving: true, dogSprite: true, t: 0.3)),
                  const SizedBox(width: 20),
                  _panel('The party halts: the hero stands, she sits', 380, 230,
                      walk(moving: false, dogSprite: true)),
                ]),
                const SizedBox(height: 16),
                _title('The story page (the trotting dog is removed, v1.600)'),
                Row(children: [
                  _panel('v1.600: the page without the dog', width, 230,
                      pageStrip(false)),
                  const SizedBox(width: 20),
                  _panel('Option: a still band, the hero and Vica together',
                      width, 230, pageStrip(true)),
                ]),
              ]),
              const SizedBox(width: 24),
              const NotesPanel(title: 'Vica follows', sections: [
                (
                  'What it is',
                  'Vica is the mandatory companion: every hero has her before the city after the desert. From then on she sits, stands or trots beside the hero in the scenes that draw the hero, in her own frames. Before that, no follower. Another companion can replace her in the party later; she then stays at camp and the follower goes with her.'
                ),
                (
                  'The street',
                  'The hero stands at the door (streetParty). Vica is a second small figure beside: sitting by default, mid-step when the scene opens, alert when a pin is picked. One layer in street_view.dart.'
                ),
                (
                  'The road',
                  'The walk already seats companions behind the hero (walkingPartyOf, desertActors and the other kits): today a companion with no sprite is a cloaked figure with a human face from her id, which would be wrong for a dog. A dog frame set for `companion_vica` replaces the placeholder: the 8 walking frames while the party moves, the sitting pose when it halts.'
                ),
                (
                  'The story page',
                  'The trotting dog on the page is removed in v1.600 (the tutorial guide stays). Right: an option, not part of any build: a still band under the text with the hero and Vica standing together once she has joined, no trotting. Without it the page has no figure to follow.'
                ),
                (
                  'Rooms',
                  'A room is a plan (RoomPlanPainter) and draws no figure for the hero, so there is nothing to follow. A paw mark by the hero’s marker would be the only way; not drawn.'
                ),
              ]),
            ]),
          ),
        ),
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      final b =
          board.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.25);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/vica-follows.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
