// Three overall directions for the story side (UX_SHOTS=<folder>), each on the
// same five screens: the story scene with its choices, an NPC, the chapter
// title, the journal's quests and the character sheet. Real text and real
// NPCs, English, phone size (360 x 780), dark and light. They keep the game's
// tokens and fonts and reuse what shipped this week: the PixelLab rarity
// frames (9-sliced into panels), the clan colours, banners and emblems, the
// fight blocks' nameplates and gems, the Apollo palette.
//   A  Illuminated page   B  Board and plates   C  Quiet book
// Mock only: nothing here is used by the app.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/palette.dart';
import 'package:narrative_data_app/theme/pixel_chip.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'package:narrative_data_app/widgets/head_avatar.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

import 'support/fonts.dart';

// ------------------------------------------------------------- the data ---
late Map<String, dynamic> _factions;
late Map<String, dynamic> _npcs;
late Map<String, dynamic> _quests;
late Map<String, dynamic> _items;
late Map<String, dynamic> _chapters;

Color _clanColor(String id) => Color(
    int.parse((_factions[id]['color'] as String).substring(1), radix: 16) |
        0xFF000000);
String _clanName(String id) => _factions[id]['name'] as String;
String _clanShort(String id) => _factions[id]['short'] as String;

enum Tier { common, uncommon, rare, epic, legendary }

Tier _tierOfItem(String rarity) => switch (rarity) {
      'Uncommon' => Tier.uncommon,
      'Rare' => Tier.rare,
      'Epic' => Tier.epic,
      'Relic' || 'Legendary' => Tier.legendary,
      _ => Tier.common,
    };

const _narrationRest = ' Fish scales and black oil. Every step was a small '
    'negotiation with gravity.';

// ---------------------------------------------------------- the pieces ---
Image _png(String path, {double? w, double? h, BoxFit fit = BoxFit.fill}) =>
    Image.asset(path,
        width: w,
        height: h,
        fit: fit,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true);

/// The five rarity frames, decoded once (the test loads them before it draws).
final Map<Tier, ui.Image> _frames = {};

/// 9-slice painter: the frame's 12 art-pixel corners drawn at [k] dp an art
/// pixel, the edges stretched, the middle left empty.
class _NinePainter extends CustomPainter {
  _NinePainter(this.image, this.k);
  final ui.Image image;
  final double k;
  @override
  void paint(Canvas canvas, Size size) {
    const c = 12.0; // corner, in art pixels
    final w = image.width.toDouble(), h = image.height.toDouble();
    final d = c * k;
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    void draw(Rect src, Rect dst) =>
        canvas.drawImageRect(image, src, dst, paint);
    final xs = [0.0, c, w - c, w];
    final ys = [0.0, c, h - c, h];
    final dxs = [0.0, d, size.width - d, size.width];
    final dys = [0.0, d, size.height - d, size.height];
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        if (i == 1 && j == 1) continue;
        draw(Rect.fromLTRB(xs[i], ys[j], xs[i + 1], ys[j + 1]),
            Rect.fromLTRB(dxs[i], dys[j], dxs[i + 1], dys[j + 1]));
      }
    }
  }

  @override
  bool shouldRepaint(_NinePainter old) => old.image != image || old.k != k;
}

/// A rarity frame (Art's PixelLab card frame) stretched round any box: the
/// 6-art-pixel band kept at 2 dp a pixel (times [band]), the middle empty, so
/// the panel's own fill shows through.
class Framed extends StatelessWidget {
  const Framed({
    super.key,
    required this.child,
    this.tier = Tier.common,
    this.fill,
    this.padding = const EdgeInsets.all(14),
    this.band = 1.0,
  });
  final Widget child;
  final Tier tier;
  final Color? fill;
  final EdgeInsets padding;

  /// The frame's scale (1 = 2 dp an art pixel).
  final double band;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = _frames[tier]!;
    return CustomPaint(
      foregroundPainter: _NinePainter(image, 2 * band),
      child: ColoredBox(
        color: fill ?? scheme.surface,
        child: Padding(
          padding: padding + EdgeInsets.all(12 * band),
          child: child,
        ),
      ),
    );
  }
}

/// The hero's face: the warrior sprite cropped to the head.
Widget _heroFace(double size) => Container(
      width: size,
      height: size,
      color: const Color(0x33000000),
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.9),
          child: SizedBox(
              width: 48,
              height: 48,
              child: _png('assets/visuals/heroes/warrior_idle_east.png')),
        ),
      ),
    );

Widget _banner(String clan, double h) => SizedBox(
    height: h,
    child: FittedBox(
        fit: BoxFit.contain,
        child: PixelBanner(id: clanBannerId(clan)!, scale: 1)));

Widget _emblem(String clan, double size) => SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.05),
          child: SizedBox(
              width: pixelBannerSize.width,
              height: pixelBannerSize.height,
              child: PixelBanner(id: clanBannerId(clan)!, scale: 1)),
        ),
      ),
    );

Color _inkOn(Color c) =>
    ThemeData.estimateBrightnessForColor(c) == Brightness.light
        ? Palette.apolloOutline
        : Palette.apolloCream;

TextStyle _display(BuildContext c, double size,
        {Color? color, double h = 1.1}) =>
    TextStyle(
        fontFamily: InkFonts.display,
        fontSize: size,
        height: h,
        color: color ?? Theme.of(c).colorScheme.onSurface);
TextStyle _prose(BuildContext c, double size,
        {Color? color,
        bool italic = false,
        FontWeight? weight,
        double h = 1.4}) =>
    TextStyle(
        fontFamily: InkFonts.prose,
        fontSize: size,
        height: h,
        fontWeight: weight,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color ?? Theme.of(c).colorScheme.onSurface);
TextStyle _sys(BuildContext c, double size, {Color? color}) => TextStyle(
    fontFamily: InkFonts.system,
    fontSize: size,
    height: 1.2,
    color: color ?? Theme.of(c).colorScheme.onSurfaceVariant);

/// A gem: a small pixel-cornered plate with a mark and a number (the fight
/// blocks' armour and damage gems).
class Gem extends StatelessWidget {
  const Gem(this.value, this.color, {super.key, this.label, this.size = 36});
  final String value;
  final Color color;
  final String? label;
  final double size;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: ShapeDecoration(
        color: scheme.surface,
        shape: PixelChipBorder(
            side: BorderSide(color: color, width: 1.5), step: 2, steps: 2),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (label != null) Text(label!, style: _sys(context, 8, color: color)),
        Text(value,
            style: TextStyle(
                fontFamily: InkFonts.prose,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.1,
                color: scheme.onSurface)),
      ]),
    );
  }
}

/// A fight block's nameplate: a coloured band with the emblem, the name and a
/// mark, over a pixel-cornered panel.
class Plate extends StatelessWidget {
  const Plate({
    super.key,
    required this.title,
    required this.color,
    required this.child,
    this.lead,
    this.trail,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 12),
    this.frame,
  });
  final String title;
  final Color color;
  final Widget child;
  final Widget? lead;
  final Widget? trail;
  final EdgeInsets padding;
  final Color? frame;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = _inkOn(color);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.surface,
        shape: PixelChipBorder(
            side: BorderSide(color: frame ?? color, width: 2),
            step: 3,
            steps: 3),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          height: 22,
          margin: const EdgeInsets.fromLTRB(3, 3, 3, 0),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          color: color,
          child: Row(children: [
            if (lead != null) ...[lead!, const SizedBox(width: 5)],
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(title,
                    maxLines: 1,
                    style: _display(context, 15, color: ink, h: 1)),
              ),
            ),
            if (trail != null) trail!,
          ]),
        ),
        Padding(padding: padding, child: child),
      ]),
    );
  }
}

/// A button the way the fight's Roll button reads: a plain filled slab.
Widget _button(BuildContext c, String label, Color color, {IconData? icon}) =>
    Container(
      height: 46,
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
        if (icon != null) ...[
          Icon(icon, size: 18, color: _inkOn(color)),
          const SizedBox(width: 8),
        ],
        Text(label, style: _sys(c, 14, color: _inkOn(color))),
      ]),
    );

// ------------------------------------------------------- the phone shell ---
/// The app's own header (chapter, icons) and tab bar, so every screen sits
/// where it would.
Widget _phone(BuildContext c,
    {required Widget body, String? chapter, String? title, int tab = 0}) {
  final scheme = Theme.of(c).colorScheme;
  final ink = InkColors.of(c);
  return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      leading: const Icon(Icons.home_outlined),
      title: chapter == null
          ? Text(title ?? '')
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CHAPTER 3', style: _sys(c, 9, color: ink.tide)),
              Text(title ?? '', style: _display(c, 17)),
            ]),
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
      destinations: const [
        NavigationDestination(icon: Icon(Icons.alt_route), label: 'Journey'),
        NavigationDestination(
            icon: Icon(Icons.person_outline), label: 'Character'),
        NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined), label: 'Camp'),
        NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Other'),
      ],
      backgroundColor: scheme.surface,
    ),
  );
}

// ================================================ A: ILLUMINATED PAGE ===
/// Story text on a framed ink panel, a drop cap, choices as small framed
/// cards that wear a clan tab when they touch a clan, a tier frame when the
/// outcome has weight.
class DirA {
  static Widget scene(BuildContext c) {
    final ink = InkColors.of(c);
    final scheme = Theme.of(c).colorScheme;
    return _phone(c,
        chapter: 'x',
        title: 'Saltmouth',
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          children: [
            Framed(
              tier: Tier.uncommon,
              padding: EdgeInsets.zero,
              child: _png('assets/visuals/scenes/saltmouth_wharf.png',
                  h: 118, w: double.infinity),
            ),
            const SizedBox(height: 10),
            Framed(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: 'I',
                    style: _display(c, 50, color: ink.gold, h: 0.85)),
                TextSpan(
                    text: 'nside the walls the road ran steeply down to ',
                    style: _prose(c, 15.5, weight: FontWeight.w600)),
                TextSpan(
                    text: 'Saltmouth',
                    style: _prose(c, 15.5,
                        color: ink.tide, weight: FontWeight.w600)),
                TextSpan(
                    text:
                        '’s harbour quarter, the Smugglers’ Wharf, the caravan master called it.',
                    style: _prose(c, 15.5, weight: FontWeight.w600)),
                TextSpan(text: _narrationRest, style: _prose(c, 15.5)),
              ])),
            ),
            const SizedBox(height: 10),
            Row(children: [
              _heroFace(38),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('What do you do in the market?',
                      style: _prose(c, 14,
                          italic: true, color: scheme.onSurfaceVariant))),
              Framed(
                  tier: Tier.common,
                  padding: EdgeInsets.zero,
                  band: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: HeadAvatar(
                        id: 'vane_quartermaster', name: 'Vane', size: 30),
                  )),
            ]),
            const SizedBox(height: 10),
            _choice(c, 'Walk the stalls before dealing with Vane'),
            const SizedBox(height: 8),
            _choice(c, 'Lift what you can from an unwatched crate',
                clan: 'crows', tier: Tier.uncommon, tag: 'Alignment −1'),
            const SizedBox(height: 12),
            _button(c, 'Back to the map', ink.gold, icon: Icons.map_outlined),
          ],
        ));
  }

  static Widget _choice(BuildContext c, String text,
      {String? clan, Tier tier = Tier.common, String? tag}) {
    final scheme = Theme.of(c).colorScheme;
    final color = clan == null ? InkColors.of(c).gold : _clanColor(clan);
    return Framed(
      tier: tier,
      band: 0.75,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            width: 36,
            color: color.withValues(alpha: clan == null ? 0.14 : 0.9),
            alignment: Alignment.center,
            child: clan == null
                ? Icon(Icons.chat_bubble_outline, size: 16, color: color)
                : _emblem(clan, 22),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              child: Row(children: [
                Expanded(
                    child: Text(text,
                        style: _prose(c, 14.5, color: scheme.onSurface))),
                if (tag != null) ...[
                  const SizedBox(width: 6),
                  Text(tag,
                      style: _sys(c, 10, color: InkColors.of(c).voidColor)),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  static Widget npc(BuildContext c) {
    final ink = InkColors.of(c);
    final npc = _npcs['aurel_vane'] as Map<String, dynamic>;
    final clan = 'dominion';
    return _phone(c,
        title: 'Aurel Vane',
        tab: 0,
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          children: [
            Framed(
              tier: Tier.rare,
              padding: const EdgeInsets.all(8),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _banner(clan, 118),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Framed(
                              tier: Tier.rare,
                              band: 0.5,
                              padding: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: HeadAvatar(
                                    id: 'aurel_vane',
                                    name: 'Aurel Vane',
                                    size: 56),
                              )),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Aurel Vane', style: _display(c, 22)),
                                  Text('Inquisitor-General',
                                      style: _prose(c, 14,
                                          color: Theme.of(c)
                                              .colorScheme
                                              .onSurfaceVariant)),
                                ]),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          color: _clanColor(clan),
                          child: Text(_clanName(clan).toUpperCase(),
                              style: _sys(c, 9.5,
                                  color: _inkOn(_clanColor(clan)))),
                        ),
                        const SizedBox(height: 4),
                        Text('The Lower Town · met in chapter 1',
                            style: _sys(c, 10)),
                      ]),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Framed(
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: 'T',
                    style: _display(c, 44, color: ink.gold, h: 0.85)),
                TextSpan(
                    text:
                        'he Inquisitor-General of the Lantern Dominion, the Regent’s hunting hand: tall, in dark robes and a white mask, dark-haired, with red sashes at the waist and a small lantern hooded in black at his collar. He walked out of the ruin of your house in Alster holding your sister off the ground by one wrist, and he knew exactly who you were.',
                    style: _prose(c, 14.5)),
              ])),
            ),
            const SizedBox(height: 10),
            for (final line in const [
              'Your house was a very small price for a door that size. I hope you will come to see it that way.',
              'I have read every page of your mother’s hiding. She was thorough. You are not thorough, and that is how we will know you.',
            ]) ...[
              Framed(
                tier: Tier.common,
                band: 0.75,
                fill: _clanColor(clan).withValues(alpha: 0.14),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('“',
                          style:
                              _display(c, 34, color: _clanColor(clan), h: 0.9)),
                      const SizedBox(width: 6),
                      Expanded(
                          child:
                              Text(line, style: _prose(c, 14.5, italic: true))),
                    ]),
              ),
              const SizedBox(height: 8),
            ],
            Text(npc['want'] as String? ?? '', style: _sys(c, 1)),
          ],
        ));
  }

  static Widget chapter(BuildContext c) {
    final ink = InkColors.of(c);
    final ch = _chapters['ch3'] as Map<String, dynamic>;
    return _phone(c,
        title: 'The Story',
        tab: 0,
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          children: [
            Framed(
              tier: Tier.epic,
              padding: EdgeInsets.zero,
              child: _png('assets/visuals/chapters/chapter_3.png',
                  w: double.infinity, h: 190),
            ),
            const SizedBox(height: 18),
            Center(
                child: Text('CHAPTER 3', style: _sys(c, 12, color: ink.tide))),
            const SizedBox(height: 6),
            Center(
                child: Text(ch['title'] as String,
                    textAlign: TextAlign.center,
                    style: _display(c, 34, h: 1.05))),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 54, height: 2, color: ink.gold),
              const SizedBox(width: 8),
              Icon(Icons.diamond_outlined, size: 12, color: ink.gold),
              const SizedBox(width: 8),
              Container(width: 54, height: 2, color: ink.gold),
            ]),
            const SizedBox(height: 12),
            Framed(
              child: Text(ch['mainQuestHint'] as String,
                  style: _prose(c, 15, italic: true)),
            ),
            const SizedBox(height: 14),
            _button(c, 'Climb the Spire', ink.gold, icon: Icons.play_arrow),
          ],
        ));
  }

  static Widget quests(BuildContext c) {
    final ink = InkColors.of(c);
    Widget card(String id, {String? clan, String? itemId}) {
      final q = _quests[id] as Map<String, dynamic>;
      final obj = (q['objectives'] as List).first['description'] as String;
      final item =
          itemId == null ? null : _items[itemId] as Map<String, dynamic>;
      final tier =
          item == null ? Tier.common : _tierOfItem(item['rarity'] as String);
      final color = clan == null ? ink.gold : _clanColor(clan);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Framed(
          tier: tier,
          padding: EdgeInsets.zero,
          child: IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                  width: 40,
                  color: color.withValues(alpha: clan == null ? 0.16 : 0.92),
                  alignment: Alignment.center,
                  child: clan == null
                      ? Icon(Icons.flag_outlined, color: color, size: 20)
                      : _emblem(clan, 24)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q['questName'] as String, style: _display(c, 19)),
                        const SizedBox(height: 4),
                        Text(obj, style: _prose(c, 14)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Text('+${q['rewardGold']} gold',
                              style: _sys(c, 11, color: ink.gold)),
                          const SizedBox(width: 10),
                          Text('+${q['rewardXP']} xp',
                              style: _sys(c, 11, color: ink.tide)),
                          if (item != null) ...[
                            const SizedBox(width: 10),
                            Text(item['itemName'] as String,
                                style: _sys(c, 11,
                                    color:
                                        tier == Tier.common ? null : ink.gold)),
                          ],
                        ]),
                      ]),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return _phone(c,
        title: 'The story so far',
        tab: 3,
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          children: [
            Text('QUESTS', style: _sys(c, 10)),
            const SizedBox(height: 6),
            card('q_ch2_dockside_debts'),
            card('q_ch2_smugglers_favor', clan: 'crows', itemId: 'dagger_t2'),
            card('q_ch2_burning_manifest', clan: 'dominion'),
          ],
        ));
  }

  static Widget character(BuildContext c) {
    final ink = InkColors.of(c);
    Widget slot(String itemId, {bool locked = false}) {
      final it = _items[itemId] as Map<String, dynamic>;
      final tier = _tierOfItem(it['rarity'] as String);
      return Expanded(
        child: Framed(
          tier: tier,
          band: 0.6,
          padding: const EdgeInsets.all(2),
          child: Column(children: [
            ItemPixelIcon(
                itemId, itemId.startsWith('shield') ? 'Shield' : 'Weapon',
                size: 32),
            const SizedBox(height: 3),
            Text(it['itemName'] as String,
                maxLines: 2, textAlign: TextAlign.center, style: _sys(c, 9)),
          ]),
        ),
      );
    }

    return _phone(c,
        title: 'Character',
        tab: 1,
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          children: [
            Framed(
              tier: Tier.rare,
              child: Row(children: [
                Framed(
                    tier: Tier.uncommon,
                    band: 0.5,
                    padding: EdgeInsets.zero,
                    child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: _heroFace(64))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ayla', style: _display(c, 26)),
                        Text('Human Warrior · Level 8', style: _prose(c, 14)),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                            value: 315 / 800, minHeight: 6, color: ink.gold),
                        const SizedBox(height: 2),
                        Text('XP 315 / 800', style: _sys(c, 10)),
                      ]),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Gem('20/20', ink.blood, label: 'HP')),
              const SizedBox(width: 8),
              Expanded(child: Gem('4/4', ink.tide, label: 'MANA')),
              const SizedBox(width: 8),
              Expanded(child: Gem('340', ink.gold, label: 'GOLD')),
            ]),
            const SizedBox(height: 12),
            Text('EQUIPMENT', style: _sys(c, 10)),
            const SizedBox(height: 6),
            Row(children: [
              slot('sword_t4'),
              const SizedBox(width: 8),
              slot('shield_t4'),
              const SizedBox(width: 8),
              slot('sword_t6'),
            ]),
            const SizedBox(height: 12),
            Text('ABILITIES', style: _sys(c, 10)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final (k, v) in const [
                ('STR', '6'),
                ('DEX', '4'),
                ('CON', '5'),
                ('INT', '2'),
                ('WIS', '3'),
                ('CHA', '3'),
              ])
                SizedBox(width: 100, child: Gem(v, ink.gold, label: k)),
            ]),
          ],
        ));
  }
}

// ================================================= B: BOARD AND PLATES ===
class DirB {
  static Widget scene(BuildContext c) {
    final ink = InkColors.of(c);
    final scheme = Theme.of(c).colorScheme;
    return _phone(c,
        chapter: 'x',
        title: 'Saltmouth',
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          children: [
            Plate(
              title: 'Smugglers’ Wharf',
              color: ink.tide,
              padding: const EdgeInsets.all(0),
              trail:
                  Text('SALTMOUTH', style: _sys(c, 9, color: _inkOn(ink.tide))),
              child: _png('assets/visuals/scenes/saltmouth_wharf.png',
                  w: double.infinity, h: 116),
            ),
            const SizedBox(height: 10),
            Plate(
              title: 'The caravan master',
              color: scheme.surfaceContainerHighest,
              frame: ink.seam,
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: 'Inside the walls the road ran steeply down to ',
                    style: _prose(c, 15.5, weight: FontWeight.w600)),
                TextSpan(
                    text: 'Saltmouth',
                    style: _prose(c, 15.5,
                        color: ink.tide, weight: FontWeight.w600)),
                TextSpan(
                    text:
                        '’s harbour quarter, the Smugglers’ Wharf, the caravan master called it.',
                    style: _prose(c, 15.5, weight: FontWeight.w600)),
                TextSpan(text: _narrationRest, style: _prose(c, 15.5)),
              ])),
            ),
            const SizedBox(height: 10),
            _choice(
                c, 'Walk the stalls before dealing with Vane', ink.gold, null),
            const SizedBox(height: 8),
            _choice(c, 'Lift what you can from an unwatched crate',
                _clanColor('crows'), 'crows',
                gem: Gem('−1', ink.voidColor, label: 'ALIGN')),
            const SizedBox(height: 12),
            _button(c, 'Back to the map', ink.gold, icon: Icons.map_outlined),
          ],
        ));
  }

  static Widget _choice(BuildContext c, String text, Color color, String? clan,
      {Widget? gem}) {
    final scheme = Theme.of(c).colorScheme;
    return Plate(
      title: clan == null ? 'Stay your hand' : _clanShort(clan),
      color: clan == null ? scheme.surfaceContainerHighest : color,
      frame: clan == null ? InkColors.of(c).seam : color,
      lead: clan == null
          ? Icon(Icons.chat_bubble_outline, size: 13, color: scheme.onSurface)
          : _emblem(clan, 13),
      padding: const EdgeInsets.fromLTRB(12, 9, 10, 10),
      child: Row(children: [
        Expanded(child: Text(text, style: _prose(c, 14.5))),
        if (gem != null) ...[const SizedBox(width: 8), gem],
      ]),
    );
  }

  static Widget npc(BuildContext c) {
    final ink = InkColors.of(c);
    const clan = 'dominion';
    final color = _clanColor(clan);
    return _phone(c,
        title: 'Aurel Vane',
        tab: 0,
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          children: [
            Plate(
              title: 'Aurel Vane',
              color: color,
              lead: _emblem(clan, 13),
              trail: Row(children: [
                Icon(Icons.workspace_premium, size: 12, color: _inkOn(color)),
                const SizedBox(width: 2),
                Text('INQUISITOR-GENERAL',
                    style: _sys(c, 8, color: _inkOn(color))),
              ]),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  SizedBox(
                      width: 64,
                      height: 64,
                      child: HeadAvatar(
                          id: 'aurel_vane', name: 'Aurel Vane', size: 64)),
                  const SizedBox(height: 6),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Gem('Wary', ink.gold, size: 28),
                    const SizedBox(width: 4),
                    Gem('Ch 1', ink.tide, size: 28),
                  ]),
                ]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      'The Inquisitor-General of the Lantern Dominion, the Regent’s hunting hand: tall, in dark robes and a white mask, dark-haired, with red sashes at the waist.',
                      style: _prose(c, 14)),
                ),
              ]),
            ),
            const SizedBox(height: 22),
            Plate(
              title: 'What they want',
              color: Theme.of(c).colorScheme.surfaceContainerHighest,
              frame: ink.seam,
              child: Text(
                  'Wants the tear for a door and your blood for its key.',
                  style: _prose(c, 14.5, italic: true)),
            ),
            const SizedBox(height: 10),
            for (final line in const [
              'Your house was a very small price for a door that size. I hope you will come to see it that way.',
              'I have read every page of your mother’s hiding. She was thorough. You are not thorough, and that is how we will know you.',
              'Do not run. It is a courtesy I extend only once: I will not follow you tonight.',
            ]) ...[
              Plate(
                title: 'Aurel Vane says',
                color: color.withValues(alpha: 0.55),
                frame: color,
                lead: _emblem(clan, 12),
                child: Text(line, style: _prose(c, 14, italic: true)),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ));
  }

  static Widget chapter(BuildContext c) {
    final ink = InkColors.of(c);
    final ch = _chapters['ch3'] as Map<String, dynamic>;
    return _phone(c,
        title: 'The Story',
        tab: 0,
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          children: [
            Plate(
              title: 'Chapter 3 · ${ch['title']}',
              color: ink.gold,
              lead: Icon(Icons.menu_book, size: 14, color: _inkOn(ink.gold)),
              padding: EdgeInsets.zero,
              child: _png('assets/visuals/chapters/chapter_3.png',
                  w: double.infinity, h: 190),
            ),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: Gem('Lvl 9', ink.gold, label: 'ADVISED')),
              const SizedBox(width: 8),
              Expanded(child: Gem('1', ink.tide, label: 'MAIN QUEST')),
              const SizedBox(width: 8),
              Expanded(child: Gem('8', ink.heal, label: 'ACTIVITIES')),
            ]),
            const SizedBox(height: 12),
            Plate(
              title: 'Climb the Spire',
              color: Theme.of(c).colorScheme.surfaceContainerHighest,
              frame: ink.seam,
              child: Text(ch['mainQuestHint'] as String,
                  style: _prose(c, 14.5, italic: true)),
            ),
            const SizedBox(height: 12),
            _button(c, 'Begin the chapter', ink.gold, icon: Icons.play_arrow),
          ],
        ));
  }

  static Widget quests(BuildContext c) {
    final ink = InkColors.of(c);
    Widget block(String id,
        {String? clan, String? itemId, double progress = 0}) {
      final q = _quests[id] as Map<String, dynamic>;
      final obj = (q['objectives'] as List).first['description'] as String;
      final item =
          itemId == null ? null : _items[itemId] as Map<String, dynamic>;
      final tier =
          item == null ? Tier.common : _tierOfItem(item['rarity'] as String);
      final color = clan == null ? ink.gold : _clanColor(clan);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Plate(
          title: q['questName'] as String,
          color: color,
          lead: clan == null
              ? Icon(Icons.flag_outlined, size: 13, color: _inkOn(color))
              : _emblem(clan, 13),
          trail: Text('CH 2', style: _sys(c, 9, color: _inkOn(color))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(obj, style: _prose(c, 14)),
            const SizedBox(height: 8),
            ClipRect(
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                    color: ink.seam.withValues(alpha: 0.5),
                    border: Border.all(color: ink.seam)),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                    widthFactor: progress, child: Container(color: color)),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Gem('+${q['rewardGold']}', ink.gold, label: 'GOLD', size: 30),
              const SizedBox(width: 8),
              Gem('+${q['rewardXP']}', ink.tide, label: 'XP', size: 30),
              if (item != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: ShapeDecoration(
                      shape: PixelChipBorder(
                          side: BorderSide(
                              color: tier == Tier.common ? ink.seam : ink.gold,
                              width: 1.5),
                          step: 2,
                          steps: 2),
                    ),
                    child: Row(children: [
                      ItemPixelIcon('dagger_t2', 'Weapon', size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(item['itemName'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _sys(c, 10))),
                    ]),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      );
    }

    return _phone(c,
        title: 'The story so far',
        tab: 3,
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          children: [
            block('q_ch2_dockside_debts', progress: 0.3),
            block('q_ch2_smugglers_favor',
                clan: 'crows', itemId: 'dagger_t2', progress: 0.0),
            block('q_ch2_burning_manifest', clan: 'dominion', progress: 0.7),
          ],
        ));
  }

  static Widget character(BuildContext c) {
    final ink = InkColors.of(c);
    Widget slot(String itemId) {
      final it = _items[itemId] as Map<String, dynamic>;
      final tier = _tierOfItem(it['rarity'] as String);
      final color = switch (tier) {
        Tier.rare => const Color(0xFF4F8FBA),
        Tier.uncommon => const Color(0xFF75A743),
        _ => ink.seam,
      };
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: ShapeDecoration(
            color: Theme.of(c).colorScheme.surface,
            shape: PixelChipBorder(
                side: BorderSide(color: color, width: 2), step: 3, steps: 2),
          ),
          child: Column(children: [
            ItemPixelIcon(
                itemId, itemId.startsWith('shield') ? 'Shield' : 'Weapon',
                size: 32),
            const SizedBox(height: 3),
            Text(it['itemName'] as String,
                maxLines: 2, textAlign: TextAlign.center, style: _sys(c, 9)),
          ]),
        ),
      );
    }

    return _phone(c,
        title: 'Character',
        tab: 1,
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          children: [
            Plate(
              title: 'Ayla',
              color: ink.gold,
              lead: Text('8', style: _sys(c, 10, color: _inkOn(ink.gold))),
              trail: Row(children: [
                Icon(Icons.star, size: 11, color: _inkOn(ink.gold)),
                Text('HUMAN WARRIOR',
                    style: _sys(c, 8, color: _inkOn(ink.gold))),
              ]),
              child: Row(children: [
                Stack(clipBehavior: Clip.none, children: [
                  SizedBox(width: 64, height: 64, child: _heroFace(64)),
                  Positioned(
                      left: -2,
                      bottom: -14,
                      child: Gem('3', Palette.slate, label: 'ARM', size: 30)),
                  Positioned(
                      right: -8,
                      bottom: -14,
                      child: Gem('4', Palette.hot, label: 'DMG', size: 30)),
                ]),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(children: [
                    _bar(c, '20 / 20', 1.0, ink.heal),
                    const SizedBox(height: 5),
                    _bar(c, '4 / 4', 1.0, ink.tide),
                    const SizedBox(height: 5),
                    _bar(c, 'XP 315 / 800', 315 / 800, ink.gold),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 22),
            Row(children: [
              slot('sword_t4'),
              const SizedBox(width: 8),
              slot('shield_t4'),
              const SizedBox(width: 8),
              slot('sword_t6')
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final (k, v) in const [
                ('STR', '6'),
                ('DEX', '4'),
                ('CON', '5'),
                ('INT', '2'),
                ('WIS', '3'),
                ('CHA', '3'),
              ])
                SizedBox(width: 100, child: Gem(v, ink.gold, label: k)),
            ]),
          ],
        ));
  }

  static Widget _bar(BuildContext c, String text, double v, Color color) =>
      Container(
        height: 14,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            border: Border.all(color: color.withValues(alpha: 0.6))),
        alignment: Alignment.centerLeft,
        child: Stack(alignment: Alignment.center, children: [
          FractionallySizedBox(
              widthFactor: v,
              child: Container(color: color.withValues(alpha: 0.7))),
          Text(text, style: _sys(c, 9, color: Colors.white)),
        ]),
      );
}

// ======================================================= C: QUIET BOOK ===
class DirC {
  static Widget _rule(BuildContext c, {Color? color}) => Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 14),
      color: color ?? InkColors.of(c).seam);

  static Widget scene(BuildContext c) {
    final ink = InkColors.of(c);
    final scheme = Theme.of(c).colorScheme;
    return _phone(c,
        chapter: 'x',
        title: 'Saltmouth',
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
          children: [
            const SizedBox(height: 14),
            _png('assets/visuals/scenes/saltmouth_wharf.png',
                w: double.infinity, h: 112),
            const SizedBox(height: 22),
            Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: 'Inside the walls the road ran steeply down to ',
                    style: _prose(c, 18, h: 1.6, weight: FontWeight.w600)),
                TextSpan(
                    text: 'Saltmouth',
                    style: _prose(c, 18,
                        h: 1.6, color: ink.tide, weight: FontWeight.w600)),
                TextSpan(
                    text:
                        '’s harbour quarter, the Smugglers’ Wharf, the caravan master called it.',
                    style: _prose(c, 18, h: 1.6, weight: FontWeight.w600)),
                TextSpan(text: _narrationRest, style: _prose(c, 18, h: 1.6)),
              ]),
            ),
            _rule(c),
            Text('What do you do in the market?',
                style: _prose(c, 15.5,
                    italic: true, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            _row(c, '1', 'Walk the stalls before dealing with Vane'),
            const SizedBox(height: 8),
            _row(c, '2', 'Lift what you can from an unwatched crate',
                clan: 'crows', tag: 'Alignment −1'),
            const SizedBox(height: 18),
            _button(c, 'Back to the map', ink.gold, icon: Icons.map_outlined),
          ],
        ));
  }

  /// A choice: a number and the words; one with weight (a clan, an alignment
  /// cost) gets the frame and the clan's colour, and nothing else does.
  static Widget _row(BuildContext c, String n, String text,
      {String? clan, String? tag}) {
    final ink = InkColors.of(c);
    final inner = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: 22,
          child: clan == null
              ? Text(n, style: _display(c, 18, color: ink.gold))
              : _emblem(clan, 18)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: _prose(c, 17, h: 1.35))),
      if (tag != null)
        Padding(
            padding: const EdgeInsets.only(left: 6, top: 3),
            child: Text(tag, style: _sys(c, 10, color: ink.voidColor))),
    ]);
    return clan == null
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 8), child: inner)
        : Framed(
            tier: Tier.uncommon,
            band: 0.75,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            fill: _clanColor(clan).withValues(alpha: 0.12),
            child: inner,
          );
  }

  static Widget npc(BuildContext c) {
    final ink = InkColors.of(c);
    const clan = 'dominion';
    return _phone(c,
        title: 'Aurel Vane',
        tab: 0,
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
          children: [
            Center(
                child:
                    HeadAvatar(id: 'aurel_vane', name: 'Aurel Vane', size: 84)),
            const SizedBox(height: 12),
            Center(child: Text('Aurel Vane', style: _display(c, 30))),
            const SizedBox(height: 4),
            Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
              _emblem(clan, 14),
              const SizedBox(width: 6),
              Text('Inquisitor-General · The Lantern Dominion',
                  style: _sys(c, 10, color: _clanColor(clan))),
            ])),
            _rule(c),
            Text(
                'The Inquisitor-General of the Lantern Dominion, the Regent’s hunting hand: tall, in dark robes and a white mask, dark-haired, with red sashes at the waist and a small lantern hooded in black at his collar. He walked out of the ruin of your house in Alster holding your sister off the ground by one wrist, and he knew exactly who you were.',
                style: _prose(c, 17, h: 1.55)),
            const SizedBox(height: 16),
            for (final line in const [
              'Your house was a very small price for a door that size. I hope you will come to see it that way.',
              'I have read every page of your mother’s hiding. She was thorough. You are not thorough, and that is how we will know you.',
            ]) ...[
              Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                    border: Border(
                        left: BorderSide(color: _clanColor(clan), width: 3))),
                child: Text(line, style: _prose(c, 16.5, italic: true, h: 1.5)),
              ),
              const SizedBox(height: 14),
            ],
            Text('WHAT THEY WANT', style: _sys(c, 10, color: ink.ash)),
          ],
        ));
  }

  static Widget chapter(BuildContext c) {
    final ink = InkColors.of(c);
    final ch = _chapters['ch3'] as Map<String, dynamic>;
    return _phone(c,
        title: 'The Story',
        tab: 0,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(28, 10, 28, 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Spacer(),
            Center(
                child: Text('3',
                    style: _display(c, 130,
                        color: ink.gold.withValues(alpha: 0.9), h: 1))),
            Center(
                child:
                    Text('CHAPTER THREE', style: _sys(c, 12, color: ink.tide))),
            const SizedBox(height: 14),
            Center(
                child: Text(ch['title'] as String,
                    textAlign: TextAlign.center,
                    style: _display(c, 36, h: 1.05))),
            _rule(c),
            Text(ch['mainQuestHint'] as String,
                textAlign: TextAlign.center,
                style: _prose(c, 17, italic: true, h: 1.55)),
            const Spacer(),
            _button(c, 'Climb the Spire', ink.gold, icon: Icons.play_arrow),
            const SizedBox(height: 14),
          ]),
        ));
  }

  static Widget quests(BuildContext c) {
    final ink = InkColors.of(c);
    Widget entry(String id, {String? clan, String? itemId}) {
      final q = _quests[id] as Map<String, dynamic>;
      final obj = (q['objectives'] as List).first['description'] as String;
      final item =
          itemId == null ? null : _items[itemId] as Map<String, dynamic>;
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (clan != null) ...[_emblem(clan, 16), const SizedBox(width: 8)],
            Expanded(
                child: Text(q['questName'] as String, style: _display(c, 22))),
          ]),
          const SizedBox(height: 4),
          Text(obj, style: _prose(c, 16.5, h: 1.45)),
          const SizedBox(height: 6),
          Text('+${q['rewardGold']} gold · +${q['rewardXP']} xp',
              style: _sys(c, 11, color: ink.gold)),
          if (item != null) ...[
            const SizedBox(height: 8),
            Framed(
              tier: _tierOfItem(item['rarity'] as String),
              band: 0.6,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              child: Row(children: [
                ItemPixelIcon(itemId!, 'Weapon', size: 24),
                const SizedBox(width: 8),
                Text(item['itemName'] as String, style: _prose(c, 15)),
                const Spacer(),
                Text('REWARD', style: _sys(c, 9, color: ink.gold)),
              ]),
            ),
          ],
          _rule(c),
        ]),
      );
    }

    return _phone(c,
        title: 'The story so far',
        tab: 3,
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          children: [
            Text('OPEN QUESTS', style: _sys(c, 10, color: ink.ash)),
            const SizedBox(height: 10),
            entry('q_ch2_dockside_debts'),
            entry('q_ch2_smugglers_favor', clan: 'crows', itemId: 'dagger_t2'),
            entry('q_ch2_burning_manifest', clan: 'dominion'),
          ],
        ));
  }

  static Widget character(BuildContext c) {
    final ink = InkColors.of(c);
    Widget stat(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Expanded(child: Text(k, style: _prose(c, 16.5))),
            Text(v, style: _display(c, 20, color: ink.gold)),
          ]),
        );
    Widget gear(String itemId) {
      final it = _items[itemId] as Map<String, dynamic>;
      final tier = _tierOfItem(it['rarity'] as String);
      final row = Row(children: [
        ItemPixelIcon(itemId, itemId.startsWith('shield') ? 'Shield' : 'Weapon',
            size: 28),
        const SizedBox(width: 10),
        Expanded(child: Text(it['itemName'] as String, style: _prose(c, 16.5))),
        Text(it['rarity'] as String, style: _sys(c, 10, color: ink.ash)),
      ]);
      return tier == Tier.common || tier == Tier.uncommon
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 7), child: row)
          : Framed(
              tier: tier,
              band: 0.6,
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
              child: row);
    }

    return _phone(c,
        title: 'Character',
        tab: 1,
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
          children: [
            Row(children: [
              _heroFace(56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ayla', style: _display(c, 30)),
                      Text('Human Warrior · Level 8', style: _prose(c, 16)),
                    ]),
              ),
            ]),
            const SizedBox(height: 12),
            Text('Health 20 / 20  ·  Mana 4 / 4  ·  340 gold',
                style: _sys(c, 12, color: ink.gold)),
            _rule(c),
            Text('WORN', style: _sys(c, 10, color: ink.ash)),
            const SizedBox(height: 4),
            gear('sword_t4'),
            gear('shield_t4'),
            gear('sword_t6'),
            _rule(c),
            Text('ABILITIES', style: _sys(c, 10, color: ink.ash)),
            const SizedBox(height: 4),
            stat('Strength', '6'),
            stat('Dexterity', '4'),
            stat('Constitution', '5'),
          ],
        ));
  }
}

// ------------------------------------------------------------ the test ---
void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('three directions', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    Map<String, dynamic> load(String f) =>
        jsonDecode(File('assets/gamedata/$f.json').readAsStringSync())
            as Map<String, dynamic>;
    _factions = load('factions');
    _npcs = load('npcs');
    _quests = load('quests');
    _items = load('items');
    _chapters = load('chapters');
    for (final t in Tier.values) {
      final bytes =
          File('assets/visuals/cards/frame_${t.name}.png').readAsBytesSync();
      _frames[t] = await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(bytes);
        return (await codec.getNextFrame()).image;
      }) as ui.Image;
    }
    Directory(shots!).createSync(recursive: true);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);
    final key = GlobalKey();
    final only = Platform.environment['UX_ONLY'];

    for (final dark in [true, false]) {
      final scheme = AppPalette.stitchedInk
          .schemeFor(dark ? Brightness.dark : Brightness.light);
      final screens = <String, Widget Function(BuildContext)>{
        'a-scene': DirA.scene,
        'a-npc': DirA.npc,
        'a-chapter': DirA.chapter,
        'a-quests': DirA.quests,
        'a-character': DirA.character,
        'b-scene': DirB.scene,
        'b-npc': DirB.npc,
        'b-chapter': DirB.chapter,
        'b-quests': DirB.quests,
        'b-character': DirB.character,
        'c-scene': DirC.scene,
        'c-npc': DirC.npc,
        'c-chapter': DirC.chapter,
        'c-quests': DirC.quests,
        'c-character': DirC.character,
      };
      for (final e in screens.entries) {
        if (only != null && !e.key.startsWith(only)) continue;
        await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(scheme),
            home: Builder(builder: e.value),
          ),
        ));
        for (var i = 0; i < 4; i++) {
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
