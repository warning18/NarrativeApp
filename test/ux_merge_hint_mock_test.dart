// Where a "a merge is ready" hint could show (UX_SHOTS=<folder>), pictures only:
//   A  on the Skills screen, a plate above the list;
//   B  at the camp, on the Skillwright's house card and a dot on the Camp tab.
// Each with the Skillwright built ("Craft") and not built ("Build it first").
// Real data: skill_merges.json (Fireball + Shadow Step -> Blazing Shadow),
// skills.json, houses.json; the story kit's plate and gem. Mock only: nothing
// here is used by the app.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/pixel_chip.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'package:narrative_data_app/widgets/clan_offer_gifts.dart' show CardTier;
import 'package:narrative_data_app/widgets/story_panel.dart';

import 'support/fonts.dart';

late Map<String, dynamic> _skills;
late Map<String, dynamic> _houses;

TextStyle _sys(BuildContext c, double s, {Color? color}) => TextStyle(
    fontFamily: InkFonts.system,
    fontSize: s,
    height: 1.2,
    color: color ?? Theme.of(c).colorScheme.onSurfaceVariant);
TextStyle _prose(BuildContext c, double s,
        {Color? color, bool italic = false}) =>
    TextStyle(
        fontFamily: InkFonts.prose,
        fontSize: s,
        height: 1.35,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color ?? Theme.of(c).colorScheme.onSurface);
TextStyle _display(BuildContext c, double s) => TextStyle(
    fontFamily: InkFonts.display,
    fontSize: s,
    height: 1.1,
    color: Theme.of(c).colorScheme.onSurface);

Widget _skillIcon(String id, double size) => Container(
      width: size + 8,
      height: size + 8,
      decoration: ShapeDecoration(
        color: const Color(0xFF10141F),
        shape: PixelChipBorder(
            side: const BorderSide(color: Color(0xFF394A50), width: 1.5),
            step: 2,
            steps: 2),
      ),
      alignment: Alignment.center,
      child: SkillPixelIcon(id, size: size),
    );

Widget _phone(BuildContext c,
        {required String title,
        required Widget body,
        int tab = 1,
        bool campDot = false}) =>
    Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const Icon(Icons.home_outlined),
        title: Text(title, style: _display(c, 19)),
        actions: const [
          Icon(Icons.map_outlined),
          SizedBox(width: 14),
          Icon(Icons.balance),
          SizedBox(width: 14),
          Icon(Icons.settings),
          SizedBox(width: 10),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.alt_route), label: 'Journey'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Character'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: campDot,
                  child: const Icon(Icons.local_fire_department_outlined)),
              label: 'Camp'),
          const NavigationDestination(
              icon: Icon(Icons.more_horiz), label: 'Other'),
        ],
      ),
    );

/// The recipe's three skills in a row: two inputs, an arrow, the result.
Widget _recipe(BuildContext c) {
  final ink = InkColors.of(c);
  return Row(children: [
    _skillIcon('fireball', 28),
    const SizedBox(width: 6),
    Text('+', style: _sys(c, 14)),
    const SizedBox(width: 6),
    _skillIcon('shadow_step', 28),
    const SizedBox(width: 8),
    Icon(Icons.arrow_forward, size: 16, color: ink.ash),
    const SizedBox(width: 8),
    // The result wears its rarity's frame (the new legendary gold).
    StoryFrame(
      tier: _tier(_skills['blazing_shadow']['rarity'] as String),
      band: 0.5,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: SkillPixelIcon('blazing_shadow', size: 28),
      ),
    ),
  ]);
}

CardTier _tier(String rarity) => switch (rarity) {
      'legendary' => CardTier.legendary,
      'epic' => CardTier.epic,
      'rare' => CardTier.rare,
      'uncommon' => CardTier.uncommon,
      _ => CardTier.common,
    };

// ------------------------------------------------------------ A: skills ---
Widget skillsScreen(BuildContext c, {required bool built}) {
  final ink = InkColors.of(c);
  final scheme = Theme.of(c).colorScheme;
  final sw = _houses['skillwright'] as Map<String, dynamic>;
  final plate = StoryPlate(
    title: 'A merge is ready',
    color: ink.tide,
    lead: Icon(Icons.auto_fix_high, size: 14, color: storyInkOn(ink.tide)),
    trail: Text(built ? 'SKILLWRIGHT' : 'NOT BUILT',
        style: _sys(c, 8, color: storyInkOn(ink.tide))),
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _recipe(c),
      const SizedBox(height: 8),
      Text(
          '${skillDisplayName('fireball')} and ${skillDisplayName('shadow_step')} become ${skillDisplayName('blazing_shadow')}. Both are spent.',
          style: _prose(c, 14)),
      const SizedBox(height: 10),
      if (built)
        _button(c, 'Craft at the Skillwright', ink.tide, Icons.auto_fix_high)
      else ...[
        Text(
            'The Skillwright is not built yet: ${sw['buildCost']} gold, 3 timber and 2 slag glass at the camp.',
            style:
                _prose(c, 13.5, italic: true, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        _button(c, 'Go to the camp', ink.gold,
            Icons.local_fire_department_outlined),
      ],
    ]),
  );
  Widget row(String id) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          _skillIcon(id, 28),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(skillDisplayName(id), style: _prose(c, 16)),
                Text((_skills[id]['description'] as String).split('.').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _sys(c, 10)),
              ])),
          Text(_skills[id]['rarity'] as String,
              style: _sys(c, 10, color: ink.ash)),
        ]),
      );
  return _phone(c,
      title: 'Skills',
      tab: 1,
      body: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        children: [
          plate,
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final (l, sel) in const [
                ('All 6', true),
                ('Attack 3', false),
                ('Heal 1', false),
                ('Mana 1', false)
              ])
                Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                        label: Text(l), selected: sel, onSelected: (_) {})),
            ]),
          ),
          const SizedBox(height: 6),
          Text('MAGE', style: _sys(c, 10, color: ink.ash)),
          row('fireball'),
          row('shadow_step'),
          row('second_wind'),
          row('mage_frost_nova'),
        ],
      ));
}

Widget _button(BuildContext c, String label, Color color, IconData icon) =>
    Container(
      height: 42,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: color,
        shape: PixelChipBorder(
            side: BorderSide(
                color: Color.lerp(color, Colors.black, 0.35)!, width: 2),
            step: 3,
            steps: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: storyInkOn(color)),
        const SizedBox(width: 8),
        Text(label, style: _sys(c, 13, color: storyInkOn(color))),
      ]),
    );

// ------------------------------------------------------------- B: camp ---
Widget campScreen(BuildContext c, {required bool built}) {
  final ink = InkColors.of(c);
  Widget house(String id, {bool builtHere = true, bool hint = false}) {
    final h = _houses[id] as Map<String, dynamic>;
    final color = hint ? ink.tide : ink.seam;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: StoryPlate(
        title: h['houseName'] as String,
        color:
            hint ? ink.tide : Theme.of(c).colorScheme.surfaceContainerHighest,
        frame: color,
        trail: hint
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_fix_high,
                    size: 11, color: storyInkOn(ink.tide)),
                const SizedBox(width: 3),
                Text('1 MERGE READY',
                    style: _sys(c, 8, color: storyInkOn(ink.tide))),
              ])
            : Text(builtHere ? 'BUILT' : '${h['buildCost']} GOLD',
                style: _sys(c, 8, color: ink.ash)),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text((h['description'] as String).split('.').first + '.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _prose(c, 13.5)),
          if (hint) ...[
            const SizedBox(height: 8),
            _recipe(c),
            const SizedBox(height: 8),
            _button(
                c,
                built ? 'Craft it' : 'Build it first · ${h['buildCost']} gold',
                built ? ink.tide : ink.gold,
                built ? Icons.auto_fix_high : Icons.hardware),
          ],
        ]),
      ),
    );
  }

  return _phone(c,
      title: 'Camp',
      tab: 2,
      campDot: true,
      body: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        children: [
          house('keldas_hall'),
          house('skillwright', builtHere: built, hint: true),
          house('hammersmith', builtHere: false),
        ],
      ));
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('merge hint', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    await tester.runAsync(StoryFrames.instance.preload);
    Map<String, dynamic> load(String f) =>
        jsonDecode(File('assets/gamedata/$f.json').readAsStringSync())
            as Map<String, dynamic>;
    _skills = load('skills');
    _houses = load('houses');
    Directory(shots!).createSync(recursive: true);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);
    final key = GlobalKey();
    for (final dark in [true, false]) {
      final scheme = AppPalette.stitchedInk
          .schemeFor(dark ? Brightness.dark : Brightness.light);
      final screens = <String, Widget Function(BuildContext)>{
        'a-skills-built': (c) => skillsScreen(c, built: true),
        'a-skills-unbuilt': (c) => skillsScreen(c, built: false),
        'b-camp-built': (c) => campScreen(c, built: true),
        'b-camp-unbuilt': (c) => campScreen(c, built: false),
      };
      for (final e in screens.entries) {
        await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(scheme),
            home: Builder(builder: e.value),
          ),
        ));
        for (var i = 0; i < 3; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 60)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        late List<int> bytes;
        await tester.runAsync(() async {
          final b =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await b.toImage(pixelRatio: 1.5);
          bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
              .buffer
              .asUint8List();
        });
        File('$shots/${e.key}-${dark ? 'dark' : 'light'}.png')
            .writeAsBytesSync(bytes);
      }
    }
  });
}
