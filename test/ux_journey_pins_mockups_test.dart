// Mockups for the Journey map's pins by category, the legend popin and the
// scene on arrival (docs/proposals/journey-pins-scene.md). Not a test of the
// app: with UX_SHOTS (a folder) set it draws the boards from the app's own
// theme, fonts and icons and saves them as PNGs; without it, it does nothing.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';

// --- The kinds of way ------------------------------------------------------

/// The categories a pin can show. They are `JourneyStepKind` folded to the
/// seven a player can learn (main, side, detour, shop, travel, rest, way).
enum Cat { main, side, detour, shop, travel, rest, way }

extension on Cat {
  IconData get icon => switch (this) {
        Cat.main => Icons.flag_outlined,
        Cat.side => Icons.chat_bubble_outline,
        Cat.detour => Icons.explore_outlined,
        Cat.shop => Icons.storefront_outlined,
        Cat.travel => Icons.sailing_outlined,
        Cat.rest => Icons.local_fire_department_outlined,
        Cat.way => Icons.signpost_outlined,
      };

  Color color(bool dark) {
    final ink = dark ? InkColors.dark : InkColors.light;
    return switch (this) {
      Cat.main => ink.gold,
      Cat.side => ink.voidColor,
      Cat.detour => ink.ember,
      Cat.shop => ink.tide,
      Cat.travel => dark ? const Color(0xFF6FA8E8) : const Color(0xFF2F5F9E),
      Cat.rest => ink.heal,
      Cat.way => ink.ash,
    };
  }

  String name(bool fr) => switch (this) {
        Cat.main => fr ? 'Quête principale' : 'Main quest',
        Cat.side => fr ? 'Quête secondaire' : 'Side quest',
        Cat.detour => fr ? 'Détour' : 'Detour',
        Cat.shop => fr ? 'Boutique et service' : 'Shop and service',
        Cat.travel => fr ? 'Voyage' : 'Travel',
        Cat.rest => fr ? 'Repos' : 'Rest',
        Cat.way => fr ? 'Chemin' : 'Plain way',
      };

  String line(bool fr) => switch (this) {
        Cat.main =>
          fr ? 'La suite de l’histoire du chapitre.' : 'The chapter’s way on.',
        Cat.side =>
          fr ? 'Un travail offert ou en cours.' : 'A job offered or under way.',
        Cat.detour => fr
            ? 'Une expédition : un lieu à fouiller.'
            : 'An expedition: a place to search.',
        Cat.shop =>
          fr ? 'Acheter, se soigner, s’équiper.' : 'Buy, heal, equip.',
        Cat.travel =>
          fr ? 'Un voyage vers un autre lieu.' : 'A trip to another place.',
        Cat.rest => fr
            ? 'Un feu ou un lit : on récupère.'
            : 'A fire or a bed: you recover.',
        Cat.way =>
          fr ? 'Un chemin, sans rien de plus.' : 'A road, nothing more said.',
      };
}

/// Which category a pin shows when a place holds several: the one that
/// matters most (the order of `journeyStepKindOf`'s own priority).
Cat dominant(List<Cat> ways) =>
    (List.of(ways)..sort((a, b) => a.index.compareTo(b.index))).first;

class Place {
  const Place(this.id, this.nameEn, this.nameFr, this.at, this.ways);
  final String id;
  final String nameEn;
  final String nameFr;
  final Offset at; // fractions of the map
  final List<Cat> ways;
  String name(bool fr) => fr ? nameFr : nameEn;
}

const _places = [
  Place('bridge', 'Stone Bridge', 'Pont de Pierre', Offset(0.72, 0.20),
      [Cat.main]),
  Place('beggar', 'Blind Beggar', 'Mendiant Aveugle', Offset(0.21, 0.30),
      [Cat.side]),
  Place('market', 'Market Row', 'Rue du Marché', Offset(0.60, 0.58),
      [Cat.shop, Cat.shop, Cat.side]),
  Place('cellars', 'The Cellars', 'Les Souterrains', Offset(0.84, 0.44),
      [Cat.detour]),
  Place('quay', 'High Quay', 'Haut Quai', Offset(0.30, 0.82), [Cat.travel]),
  Place('inn', 'The Lantern Inn', 'Auberge de la Lanterne', Offset(0.13, 0.62),
      [Cat.rest]),
];

const _here = Offset(0.42, 0.42);

// --- Fonts ------------------------------------------------------------------

Future<void> _loadFonts() async {
  for (final (family, files) in [
    (
      InkFonts.system,
      ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']
    ),
    (
      InkFonts.prose,
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    (InkFonts.display, ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(
          ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync())));
    }
    await loader.load();
  }
  final icons = File('/tmp/flutter/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

// --- The district map -------------------------------------------------------

class _DistrictPainter extends CustomPainter {
  _DistrictPainter(this.dark);
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final land = dark ? const Color(0xFF262A36) : const Color(0xFFE4D6B3);
    final block = dark ? const Color(0xFF3A3F50) : const Color(0xFFCDBE97);
    final sea = dark ? const Color(0xFF16323B) : const Color(0xFFB9CBC8);
    final river = dark ? const Color(0xFF2E6C7E) : const Color(0xFF7FA9AE);
    canvas.drawRect(Offset.zero & size, Paint()..color = sea);
    final hull = Path()
      ..moveTo(size.width * 0.30, 0)
      ..lineTo(size.width * 1.0, 0)
      ..lineTo(size.width * 1.0, size.height)
      ..lineTo(size.width * 0.16, size.height)
      ..quadraticBezierTo(
          size.width * 0.02, size.height * 0.5, size.width * 0.30, 0)
      ..close();
    canvas.drawPath(hull, Paint()..color = land);
    canvas.save();
    canvas.clipPath(hull);
    final rnd = math.Random(11);
    final bp = Paint()..color = block;
    for (var y = 6.0; y < size.height; y += 26) {
      for (var x = 20.0; x < size.width; x += 30) {
        final w = 14 + rnd.nextDouble() * 12;
        final h = 12 + rnd.nextDouble() * 10;
        canvas.save();
        canvas.translate(x + rnd.nextDouble() * 8, y + rnd.nextDouble() * 8);
        canvas.rotate((rnd.nextDouble() - 0.5) * 0.5);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(0, 0, w, h), const Radius.circular(2)),
            bp);
        canvas.restore();
      }
    }
    // The river.
    final r = Path()
      ..moveTo(size.width * 0.62, 0)
      ..cubicTo(size.width * 0.52, size.height * 0.3, size.width * 0.74,
          size.height * 0.55, size.width * 0.56, size.height);
    canvas.drawPath(
        r,
        Paint()
          ..color = river
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14);
    // Main street.
    final s = Path()
      ..moveTo(size.width * 0.18, size.height * 0.50)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.40,
          size.width * 1.0, size.height * 0.48);
    canvas.drawPath(
        s,
        Paint()
          ..color = dark ? const Color(0xFF4A4F63) : const Color(0xFFB8A77C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);
    canvas.restore();
    // The district's edge, dashed.
    final edge = Paint()
      ..color = (dark ? const Color(0xFFD9544D) : const Color(0xFFA5302A))
          .withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final m in hull.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 6, m.length)), edge);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_DistrictPainter old) => old.dark != dark;
}

// --- Pin styles -------------------------------------------------------------

enum PinStyle { discs, flags, ring }

Widget _disc(Cat c, bool dark, {double size = 30, bool lit = false}) {
  final surface = dark ? const Color(0xFF141218) : const Color(0xFFFAF3E2);
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: c.color(dark),
      border: Border.all(color: lit ? Colors.white : surface, width: 2),
      boxShadow: lit
          ? [
              BoxShadow(
                  color: c.color(dark).withValues(alpha: 0.7), blurRadius: 10)
            ]
          : null,
    ),
    child: Icon(c.icon,
        size: size * 0.58,
        color: dark ? const Color(0xFF141218) : Colors.white),
  );
}

Widget _badge(int n, Color color, bool dark) => Container(
      width: 17,
      height: 17,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dark ? const Color(0xFF141218) : const Color(0xFFFAF3E2),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text('$n',
          style: TextStyle(
              fontFamily: InkFonts.system,
              fontSize: 10,
              height: 1,
              color: dark ? Colors.white : const Color(0xFF241B0E))),
    );

Widget _pinLabel(String text, bool dark) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: (dark ? const Color(0xFF141218) : const Color(0xFFFAF3E2))
            .withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(text,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
              fontFamily: InkFonts.system,
              fontSize: 9.5,
              height: 1.1,
              color: dark ? const Color(0xFFE9E3D5) : const Color(0xFF241B0E))),
    );

/// A pin at [p], in [style], as the map draws it. [selected] lights it.
Widget _pin(Place p, PinStyle style, bool dark, bool fr, Size map,
    {bool selected = false}) {
  final top = dominant(p.ways);
  final cx = p.at.dx * map.width;
  final cy = p.at.dy * map.height;
  switch (style) {
    case PinStyle.discs:
      return Positioned(
        left: cx - 60,
        top: cy - 15,
        width: 120,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _disc(top, dark, size: 30, lit: selected),
                if (p.ways.length > 1)
                  Positioned(
                      right: -7,
                      top: -7,
                      child: _badge(p.ways.length, top.color(dark), dark)),
              ],
            ),
            const SizedBox(height: 2),
            _pinLabel(p.name(fr), dark),
          ],
        ),
      );
    case PinStyle.flags:
      final shown = p.ways.length > 3 ? p.ways.sublist(0, 3) : p.ways;
      final extra = p.ways.length - shown.length;
      final width = 24.0 + (shown.length - 1) * 20;
      final boxW = math.max(width + 24, 120.0);
      return Positioned(
        left: cx - boxW / 2,
        top: cy - 42,
        width: boxW,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              width: width + 12,
              child: Stack(
                children: [
                  for (var i = 0; i < shown.length; i++) ...[
                    Positioned(
                      left: i * 20.0 + 2,
                      bottom: 0,
                      child: Container(
                          width: 2,
                          height: 38 - i * 3,
                          color: dark
                              ? const Color(0xFFE9E3D5)
                              : const Color(0xFF241B0E)),
                    ),
                    Positioned(
                      left: i * 20.0 + 4,
                      top: i * 3.0,
                      child: _Flag(shown[i], dark, lit: selected && i == 0),
                    ),
                  ],
                  if (extra > 0)
                    Positioned(
                        right: -6,
                        top: 0,
                        child: _badge(p.ways.length, top.color(dark), dark)),
                ],
              ),
            ),
            const SizedBox(height: 1),
            _pinLabel(p.name(fr), dark),
          ],
        ),
      );
    case PinStyle.ring:
      return Positioned(
        left: cx - 60,
        top: cy - 19,
        width: 120,
        child: Column(
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (p.ways.length > 1)
                    CustomPaint(
                        size: const Size(38, 38),
                        painter: _RingPainter(
                            [for (final c in p.ways) c.color(dark)], dark)),
                  _disc(top, dark, size: 26, lit: selected),
                ],
              ),
            ),
            _pinLabel(p.name(fr), dark),
          ],
        ),
      );
  }
}

/// One arc per way round the pin, each in its own category's colour.
class _RingPainter extends CustomPainter {
  _RingPainter(this.colors, this.dark);
  final List<Color> colors;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final n = colors.length;
    const gap = 0.22;
    final sweep = (2 * math.pi - n * gap) / n;
    final rect = Rect.fromCircle(
        center: size.center(Offset.zero), radius: size.width / 2 - 2.5);
    for (var i = 0; i < n; i++) {
      canvas.drawArc(
          rect,
          -math.pi / 2 + i * (sweep + gap) + gap / 2,
          sweep,
          false,
          Paint()
            ..color = colors[i]
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt
            ..strokeWidth = 5);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

class _Flag extends StatelessWidget {
  const _Flag(this.cat, this.dark, {this.lit = false});
  final Cat cat;
  final bool dark;
  final bool lit;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _FlagPainter(cat.color(dark), dark, lit),
        child: SizedBox(
          width: 26,
          height: 18,
          child: Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Icon(cat.icon,
                size: 12, color: dark ? const Color(0xFF141218) : Colors.white),
          ),
        ),
      );
}

class _FlagPainter extends CustomPainter {
  _FlagPainter(this.color, this.dark, this.lit);
  final Color color;
  final bool dark;
  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - 5, size.height / 2)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    if (lit) {
      canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = dark ? const Color(0xFF141218) : const Color(0xFFFAF3E2));
  }

  @override
  bool shouldRepaint(_FlagPainter old) => false;
}

// --- A phone ----------------------------------------------------------------

const _phoneSize = Size(411, 890);

Widget _phoneApp(bool dark, Widget Function(BuildContext) body,
    {bool fr = false}) {
  final theme = buildAppTheme(
      stitchedInkScheme(dark ? Brightness.dark : Brightness.light));
  return SizedBox(
    width: _phoneSize.width,
    height: _phoneSize.height,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Builder(
        builder: (context) {
          final ink = InkColors.of(context);
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: const Icon(Icons.home_outlined),
              title: Text(fr ? 'Histoire' : 'Story'),
              actions: [
                const Icon(Icons.map_outlined),
                const SizedBox(width: 14),
                Text(fr ? 'FR' : 'EN',
                    style: const TextStyle(
                        fontFamily: InkFonts.system, fontSize: 14)),
                const SizedBox(width: 14),
                const Icon(Icons.settings),
                const SizedBox(width: 12),
              ],
            ),
            body: body(context),
            bottomNavigationBar: NavigationBar(
              selectedIndex: 0,
              destinations: [
                NavigationDestination(
                    icon: const Icon(Icons.alt_route),
                    label: fr ? 'Parcours' : 'Journey'),
                NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    label: fr ? 'Personnage' : 'Character'),
                NavigationDestination(
                    icon: const Icon(Icons.local_fire_department_outlined),
                    label: fr ? 'Campement' : 'Camp'),
                NavigationDestination(
                    icon: const Icon(Icons.more_horiz),
                    label: fr ? 'Autres' : 'Other'),
              ],
              backgroundColor: ink.seam.withValues(alpha: 0.0),
            ),
          );
        },
      ),
    ),
  );
}

Widget _stats(BuildContext context, bool fr) {
  final ink = InkColors.of(context);
  Widget item(IconData i, String t, Color c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, size: 14, color: c),
          const SizedBox(width: 3),
          Text(t,
              style:
                  const TextStyle(fontFamily: InkFonts.system, fontSize: 12)),
        ],
      );
  return Container(
    margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      border: Border.all(color: ink.seam),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        item(Icons.shield, fr ? 'Niv. 1' : 'Lv 1', ink.gold),
        item(Icons.wb_sunny_outlined, fr ? 'J1' : 'D1', ink.ember),
        item(Icons.favorite, '100/100', ink.blood),
        item(Icons.water_drop, '4/4', ink.tide),
        item(Icons.monetization_on, '100', ink.gold),
      ],
    ),
  );
}

Widget _crumbs(BuildContext context, bool fr) {
  final ink = InkColors.of(context);
  return Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
              fr ? 'Alster › La Ville basse' : 'Alster › The Lower Town',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontFamily: InkFonts.display)),
        ),
        Icon(Icons.auto_stories_outlined, size: 16, color: ink.gold),
        const SizedBox(width: 4),
        Text(fr ? 'Lire' : 'Read',
            style: TextStyle(
                fontFamily: InkFonts.system, fontSize: 13, color: ink.gold)),
      ],
    ),
  );
}

Widget _levelTabs(BuildContext context, bool fr, {Widget? trailing}) {
  final ink = InkColors.of(context);
  Widget tab(String t, bool on) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        color: on ? ink.gold.withValues(alpha: 0.18) : null,
        child: Text(t,
            style: TextStyle(
                fontFamily: InkFonts.system,
                fontSize: 13,
                color: on ? ink.gold : ink.ash)),
      );
  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
    child: Row(
      children: [
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: ink.seam),
              borderRadius: BorderRadius.circular(3)),
          child: Row(children: [
            tab(fr ? 'Quartier' : 'District', true),
            tab(fr ? 'Ville' : 'Town', false),
            tab(fr ? 'Monde' : 'World', false),
          ]),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    ),
  );
}

/// The legend's key button on the map.
Widget _keyButton(bool dark, {bool open = false}) {
  final ink = dark ? InkColors.dark : InkColors.light;
  return Container(
    key: const Key('legend_key'),
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: (dark ? const Color(0xFF141218) : const Color(0xFFFAF3E2))
          .withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(4),
      border:
          Border.all(color: open ? ink.gold : ink.seam, width: open ? 2 : 1),
    ),
    child: Icon(Icons.vpn_key_outlined,
        size: 18, color: open ? ink.gold : ink.ash),
  );
}

Widget _youAreHere(Size map, bool dark, bool fr, {Offset at = _here}) {
  final ink = dark ? InkColors.dark : InkColors.light;
  return Positioned(
    left: at.dx * map.width - 18,
    top: at.dy * map.height - 18,
    child: Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ink.gold, width: 2),
          ),
          child: Center(
            child: Container(
              width: 9,
              height: 9,
              decoration:
                  BoxDecoration(color: ink.gold, shape: BoxShape.circle),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _map(bool dark, bool fr, PinStyle style,
    {Size size = const Size(387, 270),
    String? selected,
    List<Place> places = _places,
    Offset here = _here,
    String hereLabel = '',
    bool keyOpen = false}) {
  return SizedBox(
    width: size.width,
    height: size.height,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DistrictPainter(dark))),
          _youAreHere(size, dark, fr, at: here),
          Positioned(
            left: here.dx * size.width - 60,
            top: here.dy * size.height + 20,
            width: 120,
            child: Center(
                child: _pinLabel(
                    hereLabel.isEmpty
                        ? (fr ? 'Le taudis' : 'The hovel')
                        : hereLabel,
                    dark)),
          ),
          for (final p in places)
            _pin(p, style, dark, fr, size, selected: p.id == selected),
          Positioned(right: 8, top: 8, child: _keyButton(dark, open: keyOpen)),
        ],
      ),
    ),
  );
}

/// One row of the list under the map: the category's disc, the way, where.
Widget _wayRow(BuildContext context, Cat c, String text, String place,
    {bool selected = false, bool dark = true}) {
  final ink = InkColors.of(context);
  final theme = Theme.of(context);
  return Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
    padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
    decoration: BoxDecoration(
      color: selected
          ? c.color(dark).withValues(alpha: 0.14)
          : theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
          color: selected ? c.color(dark) : theme.colorScheme.outlineVariant,
          width: selected ? 2 : 1),
    ),
    child: Row(
      children: [
        _disc(c, dark, size: 24),
        const SizedBox(width: 9),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontFamily: InkFonts.prose, height: 1.2)),
        ),
        const SizedBox(width: 6),
        Text(place,
            style: TextStyle(
                fontFamily: InkFonts.system, fontSize: 10.5, color: ink.ash)),
      ],
    ),
  );
}

const _ways = [
  (Cat.main, 'bridge', 'Cross the bridge', 'Traverser le pont'),
  (Cat.side, 'beggar', 'Hear the beggar out', 'Écouter le mendiant'),
  (Cat.shop, 'market', 'The forge', 'La forge'),
  (Cat.shop, 'market', 'The apothecary', 'L’apothicaire'),
  (Cat.side, 'market', 'Find the missing carter', 'Retrouver le charretier'),
  (Cat.detour, 'cellars', 'Search the cellars', 'Fouiller les souterrains'),
  (Cat.travel, 'quay', 'Sail from the quay', 'Embarquer au quai'),
  (Cat.rest, 'inn', 'Sleep at the Lantern', 'Dormir à la Lanterne'),
];

List<Widget> _wayRows(BuildContext context, bool dark, bool fr,
    {String? selected, String? exclude}) {
  Place by(String id) => _places.firstWhere((p) => p.id == id);
  return [
    for (final (c, place, en, frText) in _ways)
      if (place != exclude)
        _wayRow(context, c, fr ? frText : en, by(place).name(fr),
            selected: place == selected, dark: dark),
  ];
}

Widget _journeyBody(BuildContext context, bool dark, bool fr, PinStyle style,
    {String? selected, bool keyOpen = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _stats(context, fr),
      _crumbs(context, fr),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: _map(dark, fr, style, selected: selected, keyOpen: keyOpen),
      ),
      _levelTabs(context, fr),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Text((fr ? '8 chemins ici' : '8 ways here').toUpperCase(),
            style: TextStyle(
                fontFamily: InkFonts.system,
                fontSize: 11,
                letterSpacing: 1,
                color: InkColors.of(context).ash)),
      ),
      ..._wayRows(context, dark, fr, selected: selected),
    ],
  );
}

// --- The legend -------------------------------------------------------------

Widget _legendSheet(BuildContext context, bool dark, bool fr) {
  final theme = Theme.of(context);
  final ink = InkColors.of(context);
  return Container(
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      border: Border(top: BorderSide(color: ink.seam)),
    ),
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                  color: ink.seam, borderRadius: BorderRadius.circular(2))),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.vpn_key_outlined, size: 18, color: ink.gold),
            const SizedBox(width: 8),
            Text(fr ? 'Légende de la carte' : 'Map key',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontFamily: InkFonts.display)),
            const Spacer(),
            Icon(Icons.close, size: 20, color: ink.ash),
          ],
        ),
        const SizedBox(height: 10),
        for (final c in Cat.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _disc(c, dark, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name(fr),
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontFamily: InkFonts.system,
                              color: c.color(dark))),
                      Text(c.line(fr),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: ink.ash)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 18),
        Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                      left: 0, top: 0, child: _disc(Cat.shop, dark, size: 26)),
                  Positioned(
                      right: -2,
                      top: -4,
                      child: _badge(3, Cat.shop.color(dark), dark)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  fr
                      ? 'Un chiffre : plusieurs chemins au même endroit. La couleur est celle du plus important.'
                      : 'A number: several ways at one place. The colour is the most important one.',
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _legendBoard(bool dark, bool fr) => _phoneApp(
      dark,
      fr: fr,
      (context) => Stack(
        children: [
          Positioned.fill(
              child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: _journeyBody(context, dark, fr, PinStyle.discs,
                      keyOpen: true))),
          Positioned.fill(
              child: ColoredBox(
                  color: Colors.black.withValues(alpha: dark ? 0.55 : 0.4))),
          Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _legendSheet(context, dark, fr)),
        ],
      ),
    );

// --- The scene --------------------------------------------------------------

ui.Image? _art;

Future<void> _ensureArt(WidgetTester tester) async {
  if (_art != null) return;
  await tester.runAsync(() async {
    final bytes = await File('docs/proposals/images/inplace-5-scene-bridge.png')
        .readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    _art = (await codec.getNextFrame()).image;
  });
}

/// The scene art: the toll booth scene of the in-place choices proposal
/// (docs/proposals/images/inplace-5-scene-bridge.png), cropped to its scene,
/// a stand-in for the place's own kit.
Widget _sceneArt(bool dark, bool fr,
    {double height = 250, bool withCard = true, Cat cat = Cat.side}) {
  return SizedBox(
    height: height,
    width: double.infinity,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            maxHeight: double.infinity,
            child: Transform.translate(
              offset: const Offset(0, -80),
              child: RawImage(
                  image: _art, width: _phoneSize.width, fit: BoxFit.fitWidth),
            ),
          ),
        ),
        if (withCard)
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 12, 7),
              decoration: BoxDecoration(
                color: const Color(0xFF141218).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _disc(cat, true, size: 28),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          (fr ? 'Ville basse · ' : 'Lower Town · ') +
                              cat.name(fr),
                          style: TextStyle(
                              fontFamily: InkFonts.system,
                              fontSize: 9.5,
                              color: cat.color(true))),
                      Text(fr ? 'Le Mendiant Aveugle' : 'The Blind Beggar',
                          style: const TextStyle(
                              fontFamily: InkFonts.display,
                              fontSize: 17,
                              color: Color(0xFFE9E3D5))),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _actionCard(BuildContext context, IconData icon, Color color,
    String text, String tag, bool dark,
    {String? to, Cat? cat}) {
  final theme = Theme.of(context);
  final ink = InkColors.of(context);
  return Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 7),
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: theme.colorScheme.outlineVariant),
    ),
    child: Row(
      children: [
        cat != null
            ? _disc(cat, dark, size: 34)
            : Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surface,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: InkFonts.prose,
                      fontWeight: FontWeight.w500,
                      height: 1.2)),
              if (to != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_forward, size: 12, color: ink.ash),
                    const SizedBox(width: 3),
                    Text(to,
                        style: TextStyle(
                            fontFamily: InkFonts.system,
                            fontSize: 10.5,
                            color: ink.ash)),
                  ],
                ),
            ],
          ),
        ),
        if (tag.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.7)),
              color: color.withValues(alpha: 0.12),
            ),
            child: Text(tag,
                style: TextStyle(
                    fontFamily: InkFonts.system,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
      ],
    ),
  );
}

List<Widget> _sceneCards(BuildContext context, bool dark, bool fr) {
  final ink = InkColors.of(context);
  return [
    _actionCard(
        context,
        Icons.record_voice_over_outlined,
        ink.tide,
        fr ? 'Écouter son histoire' : 'Hear his story out',
        fr ? 'CHA 12' : 'CHA DC 12',
        dark),
    _actionCard(
        context,
        Icons.monetization_on_outlined,
        ink.gold,
        fr ? 'Lui donner une pièce' : 'Give him a coin',
        '1 ${fr ? 'or' : 'gold'}',
        dark),
    _actionCard(context, Icons.signpost_outlined, ink.ash,
        fr ? 'Prendre la ruelle de la forge' : 'Take the forge alley', '', dark,
        to: fr ? 'Rue du Marché' : 'Market Row', cat: Cat.shop),
    _actionCard(
        context,
        Icons.signpost_outlined,
        ink.ash,
        fr
            ? 'Suivre sa piste vers les caves'
            : 'Follow his lead to the cellars',
        '',
        dark,
        to: fr ? 'Les Souterrains' : 'The Cellars',
        cat: Cat.detour),
  ];
}

Widget _sceneText(BuildContext context, bool fr, {int lines = 3}) {
  final ink = InkColors.of(context);
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text((fr ? 'AU COIN DE LA RUE' : 'AT THE CORNER').toUpperCase(),
                style: TextStyle(
                    fontFamily: InkFonts.system,
                    fontSize: 10.5,
                    letterSpacing: 1,
                    color: ink.ash)),
            const Spacer(),
            Icon(Icons.auto_stories_outlined, size: 15, color: ink.gold),
            const SizedBox(width: 4),
            Text(fr ? 'Lire' : 'Read',
                style: TextStyle(
                    fontFamily: InkFonts.system,
                    fontSize: 12,
                    color: ink.gold)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
            fr
                ? 'Un vieil homme aux yeux blancs tendait la main contre le mur. « Une pièce, et je te dis qui tient vraiment le pont. »'
                : 'An old man with milk-white eyes held out a hand against the wall. “A coin, and I’ll tell you who really holds the bridge.”',
            maxLines: lines,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontFamily: InkFonts.prose, height: 1.35)),
      ],
    ),
  );
}

Widget _sceneContent(BuildContext context, bool dark, bool fr) {
  return ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _sceneArt(dark, fr, height: 240),
        _sceneText(context, fr),
        ..._sceneCards(context, dark, fr),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined,
                    size: 16, color: InkColors.of(context).ash),
                const SizedBox(width: 6),
                Text(fr ? 'Retour à la carte' : 'Back to the map',
                    style: TextStyle(
                        fontFamily: InkFonts.system,
                        fontSize: 12.5,
                        color: InkColors.of(context).ash)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _sceneScreen(bool dark, bool fr) => _phoneApp(
      dark,
      fr: fr,
      (context) => _sceneContent(context, dark, fr),
    );

/// Option S2: the scene as a sheet over the dimmed map.
Widget _sceneSheetScreen(bool dark, bool fr) => _phoneApp(
      dark,
      fr: fr,
      (context) {
        final theme = Theme.of(context);
        final ink = InkColors.of(context);
        return Stack(
          children: [
            Positioned.fill(
                child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: _journeyBody(context, dark, fr, PinStyle.discs,
                        selected: 'beggar'))),
            Positioned.fill(
                child: ColoredBox(
                    color: Colors.black.withValues(alpha: dark ? 0.5 : 0.35))),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: 250,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  border: Border(top: BorderSide(color: ink.seam)),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    Center(
                      child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 7),
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                              color: ink.seam,
                              borderRadius: BorderRadius.circular(2))),
                    ),
                    _sceneArt(dark, fr, height: 150),
                    _sceneText(context, fr, lines: 2),
                    ..._sceneCards(context, dark, fr).take(3),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

/// The four frames of the way in: the pin picked, the camera dives into it,
/// the scene, and the way back with the party at the new place.
List<Widget> _transitionFrames(bool dark, bool fr) {
  Widget frame1() => _phoneApp(
        dark,
        fr: fr,
        (context) => Stack(
          children: [
            Positioned.fill(
                child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: _journeyBody(context, dark, fr, PinStyle.discs,
                        selected: 'beggar'))),
            // The callout of the picked pin.
            Positioned(
              left: 22,
              top: 262,
              child: _enterCallout(context, dark, fr),
            ),
          ],
        ),
      );

  // The place opens out of its pin: the scene grows from the pin's spot
  // over the dimmed map.
  Widget frame2() => _phoneApp(
        dark,
        fr: fr,
        (context) => Stack(
          children: [
            Positioned.fill(
                child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: _journeyBody(context, dark, fr, PinStyle.discs,
                        selected: 'beggar'))),
            Positioned.fill(
                child: ColoredBox(
                    color: Colors.black.withValues(alpha: dark ? 0.6 : 0.45))),
            Positioned.fill(
              child: Transform.scale(
                scale: 0.68,
                alignment: const Alignment(-0.45, -0.55),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Cat.side.color(dark), width: 3 / 0.68),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 24)
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IgnorePointer(
                    child: _sceneContent(context, dark, fr),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget frame4() => _phoneApp(
        dark,
        fr: fr,
        (context) {
          final rest = _places.where((p) => p.id != 'beggar').toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _stats(context, fr),
              _crumbs(context, fr),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _map(dark, fr, PinStyle.discs,
                    places: rest,
                    here: _places[1].at,
                    hereLabel: fr ? 'Le Mendiant' : 'The Beggar'),
              ),
              _levelTabs(context, fr),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Text(
                    (fr ? '6 chemins ici' : '6 ways here').toUpperCase(),
                    style: TextStyle(
                        fontFamily: InkFonts.system,
                        fontSize: 11,
                        letterSpacing: 1,
                        color: InkColors.of(context).ash)),
              ),
              ..._wayRows(context, dark, fr, exclude: 'beggar').take(7),
            ],
          );
        },
      );

  return [frame1(), frame2(), _sceneScreen(dark, fr), frame4()];
}

Widget _enterCallout(BuildContext context, bool dark, bool fr) {
  final theme = Theme.of(context);
  final ink = InkColors.of(context);
  return Container(
    padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Cat.side.color(dark), width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Cat.side.name(fr),
                style: TextStyle(
                    fontFamily: InkFonts.system,
                    fontSize: 10,
                    color: Cat.side.color(dark))),
            Text(fr ? 'Le Mendiant Aveugle' : 'The Blind Beggar',
                style: const TextStyle(
                    fontFamily: InkFonts.display, fontSize: 15)),
            Text(fr ? '3 façons d’agir ici' : '3 things to do here',
                style: TextStyle(
                    fontFamily: InkFonts.system, fontSize: 10, color: ink.ash)),
          ],
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: ink.gold, borderRadius: BorderRadius.circular(4)),
          child: Text(fr ? 'Entrer' : 'Enter',
              style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: 13,
                  color: dark ? const Color(0xFF1A1408) : Colors.white)),
        ),
      ],
    ),
  );
}

// --- Saving -----------------------------------------------------------------

Future<void> _save(WidgetTester tester, String name, List<Widget> phones,
    {double ratio = 1.5, double gap = 16, Color? bg}) async {
  await _ensureArt(tester);
  final dir = Platform.environment['UX_SHOTS']!;
  final key = GlobalKey();
  tester.view.physicalSize = Size(
      (_phoneSize.width + gap) * phones.length + gap,
      _phoneSize.height + 2 * gap);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: RepaintBoundary(
      key: key,
      child: Container(
        color: bg ?? const Color(0xFF0B0A0D),
        padding: EdgeInsets.all(gap),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < phones.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              ClipRRect(
                  borderRadius: BorderRadius.circular(18), child: phones[i]),
            ],
          ],
        ),
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) {
    test('journey pin mockups are drawn only with UX_SHOTS', () {});
    return;
  }

  setUpAll(_loadFonts);

  Widget journey(bool dark, PinStyle s, {bool fr = false, String? selected}) =>
      _phoneApp(
          dark,
          fr: fr,
          (context) => _journeyBody(context, dark, fr, s, selected: selected));

  testWidgets('pins A: discs', (tester) async {
    await _save(tester, 'journey-pins-1-discs', [
      journey(true, PinStyle.discs, selected: 'market'),
      journey(false, PinStyle.discs, selected: 'market'),
    ]);
  });

  testWidgets('pins B: flags', (tester) async {
    await _save(tester, 'journey-pins-2-flags', [
      journey(true, PinStyle.flags, selected: 'market'),
      journey(false, PinStyle.flags, selected: 'market'),
    ]);
  });

  testWidgets('pins C: ring', (tester) async {
    await _save(tester, 'journey-pins-3-ring', [
      journey(true, PinStyle.ring, selected: 'market'),
      journey(false, PinStyle.ring, selected: 'market'),
    ]);
  });

  testWidgets('legend', (tester) async {
    await _save(tester, 'journey-legend', [
      _legendBoard(true, false),
      _legendBoard(false, false),
      _legendBoard(true, true),
    ]);
  });

  testWidgets('scene: the way in', (tester) async {
    await _save(tester, 'journey-scene-1-view', _transitionFrames(true, false));
    await _save(
        tester, 'journey-scene-1-view-light', _transitionFrames(false, false));
  });

  testWidgets('scene: the sheet', (tester) async {
    await _save(tester, 'journey-scene-2-sheet', [
      _sceneSheetScreen(true, false),
      _sceneSheetScreen(false, false),
      _sceneSheetScreen(true, true),
    ]);
  });
}
