// PROPOSAL (pictures only, no PR): Core's late-game work (v2.5.0), at 360 and
// 320, English and French (UX_SHOTS=<folder>):
//   banner  the Void Banner's own gear slot, the 6th after Foot, on the
//           inventory: three layouts (a wide tile, a 7th tile, hidden until
//           found) and the slot's states
//   goals   the chapter goals (3 a chapter, chapters 4 to 8): the card, where
//           it shows (the chapter page, the fight's setup, a toast) and the
//           ticks as they come
//   chest   the chapter chest at the end of a chapter (Wooden for 0 goals met,
//           Iron 1, Silver 2, Gold 3), apart from the boss chest
// The goals' lines are samples (Narrative writes the real ones).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'package:narrative_data_app/widgets/clan_offer_gifts.dart' show CardTier;
import 'package:narrative_data_app/widgets/inventory_parts.dart';
import 'package:narrative_data_app/widgets/ink_panel.dart';
import 'package:narrative_data_app/widgets/pixel_glyph.dart';

import 'support/fonts.dart';

// ---- the Banner slot ---------------------------------------------------------

Widget _tile(BuildContext context, double w, double h, String label,
    {String? worn, Widget? icon, bool lit = false, CardTier? tier}) {
  final ink = InkColors.of(context);
  return SizedBox(
    width: w,
    height: h,
    child: InventorySlotTile(
      slotLabel: label,
      icon: icon ?? Icon(Icons.flag_outlined, size: 32, color: ink.ash),
      worn: worn,
      lit: lit,
      tier: tier,
      onClear: worn == null ? null : () {},
    ),
  );
}

Widget _grid(BuildContext context, double width, bool fr,
    {required String banner, bool bannerWorn = true}) {
  final tileW = (width - 32 - 16) / 3;
  const h = 96.0;
  final ink = InkColors.of(context);
  final names = fr
      ? ['Dé', 'Tête', 'Torse', 'Arme', 'Jambes', 'Pieds']
      : ['Dice', 'Head', 'Body', 'Weapon', 'Legs', 'Feet'];
  final worn = fr
      ? [
          null,
          'Couronne du Souverain',
          'Manteau de la Veille',
          'Claymore forgée',
          'Jambières de peau',
          'Bottes ferrées'
        ]
      : [
          null,
          'The Sovereign’s Crown',
          'Harbourwatch Coat',
          'Warforged Claymore',
          'Hide Greaves',
          'Iron-Shod Boots'
        ];
  final glyphs = [
    PixelGlyphs.slotBag,
    PixelGlyphs.slotHead,
    PixelGlyphs.slotBody,
    PixelGlyphs.slotWeapon,
    PixelGlyphs.slotLegs,
    PixelGlyphs.slotFeet,
  ];
  Widget std(int i) => _tile(context, tileW, h, names[i],
      worn: worn[i],
      icon: PixelGlyph(glyphs[i], size: 32, color: ink.ash, opacity: 0.7),
      tier: worn[i] == null ? null : CardTier.rare);
  final bannerName = bannerWorn
      ? (fr ? 'Bannière du Néant (Linceul Gris)' : 'Void Banner (Grey Shroud)')
      : null;
  final bannerIcon = bannerWorn
      ? const ItemPixelIcon('void_banner', 'Artifact', size: 32)
      : null;
  final label = fr ? 'Bannière' : 'Banner';
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (var i = 0; i < 6; i++) std(i)]),
    const SizedBox(height: 8),
    if (banner == 'wide')
      _tile(context, width - 32, 72, label,
          worn: bannerName,
          icon: bannerIcon,
          lit: !bannerWorn,
          tier: bannerWorn ? CardTier.legendary : null)
    else if (banner == 'seventh')
      _tile(context, tileW, h, label,
          worn: bannerName,
          icon: bannerIcon,
          lit: !bannerWorn,
          tier: bannerWorn ? CardTier.legendary : null),
  ]);
}

Widget _caption(String s) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(s.toUpperCase(),
        style: const TextStyle(
            fontFamily: InkFonts.system, fontSize: 10, letterSpacing: 1.2)));

Widget _bannerSheet(BuildContext context, double w, bool fr) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          fr
              ? 'La Bannière du Néant : un sixième emplacement'
              : 'The Void Banner: a sixth slot',
          style: Theme.of(context).textTheme.titleMedium),
      _caption(
          fr ? 'A · une tuile large (mon choix)' : 'A · a wide tile (my pick)'),
      _grid(context, w, fr, banner: 'wide'),
      _caption(fr
          ? 'B · une septième tuile, seule sur sa rangée'
          : 'B · a seventh tile, alone on its row'),
      _grid(context, w, fr, banner: 'seventh'),
      _caption(fr
          ? 'C · rien tant qu’elle n’est pas trouvée'
          : 'C · nothing until it is found'),
      _grid(context, w, fr, banner: 'none'),
      _caption(fr
          ? 'Trouvée, pas portée : l’emplacement s’allume'
          : 'Found, not worn: the slot lights'),
      _grid(context, w, fr, banner: 'wide', bannerWorn: false),
    ]);

// ---- chapter goals -----------------------------------------------------------

class _Goal {
  const _Goal(this.en, this.fr, this.hintEn, this.hintFr);
  final String en, fr, hintEn, hintFr;
}

const _goals = [
  _Goal(
      'Win a fight in 4 rounds or fewer',
      'Gagner un combat en 4 manches ou moins',
      'Best so far: 6 rounds',
      'Record : 6 manches'),
  _Goal('Beat the boss on the first try', 'Battre le chef du premier coup',
      'The boss waits at the end', 'Le chef attend à la fin'),
  _Goal('Win a fight without a potion', 'Gagner un combat sans potion',
      'Done at the Salt Gate', 'Fait à la Porte du Sel'),
];

Widget _tick(bool done, {bool fresh = false}) => Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
          color: done ? const Color(0xFF3F8F5A) : null,
          border: Border.all(
              color: done ? const Color(0xFF3F8F5A) : Colors.grey, width: 1.6),
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            if (fresh) const BoxShadow(color: Color(0xAA3F8F5A), blurRadius: 8),
          ]),
      child:
          done ? const Icon(Icons.check, size: 15, color: Colors.white) : null,
    );

Widget _goalCard(BuildContext context, bool fr, List<bool> done,
    {int fresh = -1, bool compact = false}) {
  final theme = Theme.of(context);
  final n = done.where((d) => d).length;
  return InkPanel(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text(fr ? 'Chapitre 5 · Objectifs' : 'Chapter 5 · Goals',
                style: theme.textTheme.titleSmall)),
        Text('$n/3', style: theme.textTheme.labelLarge),
      ]),
      const SizedBox(height: 8),
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _tick(done[i], fresh: i == fresh),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fr ? _goals[i].fr : _goals[i].en,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            decoration:
                                done[i] ? TextDecoration.lineThrough : null)),
                    if (!compact)
                      Text(fr ? _goals[i].hintFr : _goals[i].hintEn,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                  ]),
            ),
          ]),
        ),
      Row(children: [
        for (final t in ['wooden', 'iron', 'silver', 'gold'])
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Opacity(
              opacity: ['wooden', 'iron', 'silver', 'gold'].indexOf(t) == n
                  ? 1
                  : 0.35,
              child: Image.asset('assets/icons/chests/${t}_closed.png',
                  width: 26,
                  height: 26,
                  filterQuality: FilterQuality.none,
                  fit: BoxFit.contain),
            ),
          ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
              fr
                  ? 'Le coffre du chapitre grandit avec vos objectifs.'
                  : 'The chapter chest grows with your goals.',
              style: theme.textTheme.bodySmall),
        ),
      ]),
    ]),
  );
}

Widget _goalsSheet(BuildContext context, double w, bool fr) {
  final theme = Theme.of(context);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(fr ? 'Les objectifs du chapitre' : 'The chapter goals',
        style: theme.textTheme.titleMedium),
    _caption(fr
        ? '1 · La page du chapitre (le foyer des objectifs)'
        : '1 · The chapter page (the home of the goals)'),
    _goalCard(context, fr, [true, false, false], fresh: 0),
    _caption(fr
        ? '2 · Au début d’un combat : seulement ceux qui s’y jouent'
        : '2 · At a fight’s setup: only the goals it can settle'),
    Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        _tick(false),
        const SizedBox(width: 10),
        Expanded(
            child: Text(
                fr
                    ? 'Objectif : gagner en 4 manches ou moins'
                    : 'Goal: win in 4 rounds or fewer',
                style: theme.textTheme.bodyMedium)),
        Text('○ 1/3', style: theme.textTheme.labelMedium),
      ]),
    ),
    _caption(fr
        ? '3 · Après le combat : un bandeau'
        : '3 · After the fight: a toast'),
    Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
          color: theme.colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        _tick(true, fresh: true),
        const SizedBox(width: 10),
        Expanded(
            child: Text(
                fr
                    ? 'Objectif atteint : sans potion · 2/3'
                    : 'Goal met: no potion · 2/3',
                style: TextStyle(color: theme.colorScheme.onInverseSurface))),
      ]),
    ),
    _caption(
        fr ? 'La carte, au fil du chapitre' : 'The card, through a chapter'),
    _goalCard(context, fr, [false, false, false], compact: true),
    const SizedBox(height: 8),
    _goalCard(context, fr, [true, true, false], compact: true),
    const SizedBox(height: 8),
    _goalCard(context, fr, [true, true, true], compact: true),
  ]);
}

// ---- the chapter chest -------------------------------------------------------

Widget _chestSheet(BuildContext context, double w, bool fr, int met) {
  final theme = Theme.of(context);
  const tiers = ['wooden', 'iron', 'silver', 'gold'];
  final names = fr
      ? ['de bois', 'de fer', 'd’argent', 'd’or']
      : ['Wooden', 'Iron', 'Silver', 'Gold'];
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(fr ? 'Chapitre 5 terminé' : 'Chapter 5 complete',
        style: theme.textTheme.headlineSmall),
    Text(
        fr
            ? 'Vos objectifs ouvrent le coffre du chapitre.'
            : 'Your goals open the chapter chest.',
        style: theme.textTheme.bodyMedium),
    const SizedBox(height: 12),
    _goalCard(context, fr, [for (var i = 0; i < 3; i++) i < met],
        compact: true),
    const SizedBox(height: 14),
    InkPanel(
      lit: true,
      child: Column(children: [
        Image.asset('assets/icons/chests/${tiers[met]}_closed.png',
            width: 96,
            height: 96,
            filterQuality: FilterQuality.none,
            fit: BoxFit.contain),
        const SizedBox(height: 6),
        Text(
            fr
                ? 'Coffre du chapitre ${names[met]}'
                : '${names[met]} chapter chest',
            style: theme.textTheme.titleMedium),
        Text(
            fr
                ? '$met objectif${met > 1 ? 's' : ''} atteint${met > 1 ? 's' : ''} sur 3'
                : '$met of 3 goals met',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 4; i++) ...[
            Opacity(
              opacity: i == met ? 1 : 0.3,
              child: Image.asset('assets/icons/chests/${tiers[i]}_closed.png',
                  width: 30,
                  height: 30,
                  filterQuality: FilterQuality.none,
                  fit: BoxFit.contain),
            ),
            if (i < 3) const SizedBox(width: 8),
          ],
        ]),
        const SizedBox(height: 12),
        SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: () {},
                child: Text(fr ? 'Ouvrir le coffre' : 'Open the chest'))),
      ]),
    ),
    const SizedBox(height: 12),
    Text(
        fr
            ? 'Le coffre du chef reste à part : il s’ouvre après le combat, comme avant.'
            : 'The boss chest stays apart: it opens after the fight, as before.',
        style: theme.textTheme.bodySmall),
  ]);
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  Future<void> sheet(WidgetTester t, String name, double w,
      Widget Function(BuildContext) body) async {
    final key = GlobalKey();
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = Size(w, 2400);
    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.dark));
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            child: Container(
              width: w,
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Builder(
                  builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [body(context)])),
            ),
          ),
        ),
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(t.takeException(), isNull, reason: name);
    await t.runAsync(() async {
      final render =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    await t.pumpWidget(const SizedBox());
  }

  testWidgets('the late-game pictures', skip: shots == null, (t) async {
    await t.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    addTearDown(t.view.reset);
    for (final w in [360.0, 320.0]) {
      final n = w.toInt();
      for (final fr in [false, true]) {
        final l = fr ? 'fr' : 'en';
        await sheet(t, 'banner-$n-$l', w, (c) => _bannerSheet(c, w, fr));
        await sheet(t, 'goals-$n-$l', w, (c) => _goalsSheet(c, w, fr));
        for (final met in [0, 2, 3]) {
          await sheet(t, 'chest-$met-goals-$n-$l', w,
              (c) => _chestSheet(c, w, fr, met));
        }
      }
    }
  });
}
