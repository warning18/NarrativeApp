// The drawing of the refined in-place choices mock
// (ux_inplace_refined_mock_test.dart): the scene panel and stage mode, the two
// designs the user kept, on four real scenes of the story (the Stone Bridge,
// the family house, Vane's gate, the price of the crossing) at 412 and 320 px.
// Built from the real choice card, the real sprites and the app's own theme;
// the map is drawn like the District zoom. Mock only; nothing here ships.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/choice_card.dart';

enum Act { fight, pay, decide, talk }

class Pick {
  const Pick(this.text, this.act,
      {this.tag, this.tagKind, this.leadsTo, this.note});

  final String text;
  final Act act;

  /// "30 gold", "Fight", "Evil −2".
  final String? tag;

  /// gold, blood, void or tide: the tag's colour.
  final String? tagKind;
  final String? leadsTo;
  final String? note;

  bool get moves => leadsTo != null;
}

class SceneSpec {
  const SceneSpec({
    required this.place,
    required this.crumb,
    required this.facingName,
    required this.facingSprite,
    required this.line,
    required this.prompt,
    required this.picks,
    required this.mapSeed,
    this.river = false,
    this.speaker,
    this.destination,
    this.hasFight = false,
  });

  final String place;
  final String crumb;
  final String? facingName;

  /// A sprite of assets/visuals/fighters (a stand-in where the person has
  /// none), or null for a narrator scene.
  final String? facingSprite;

  /// What was just said, the last sentence of the node's text.
  final String line;

  /// The node's `prompt`: the question the scene ends on.
  final String prompt;
  final List<Pick> picks;
  final int mapSeed;
  final bool river;

  /// A voice with no body (the Sovereign), for a narrator scene.
  final String? speaker;

  /// The name of the pin a moving choice leads to on the map.
  final String? destination;
  final bool hasFight;
}

const bridge = SceneSpec(
  place: 'The Stone Bridge',
  crumb: '… of Alster  ›  Alster  ›',
  facingName: 'Toll keeper',
  facingSprite: 'white_soldier',
  line: '“Toll,” he said. “For the Inquisition’s peace.”',
  prompt: 'Pay the toll, or fight?',
  mapSeed: 3,
  river: true,
  hasFight: true,
  picks: [
    Pick('Pay the toll', Act.pay,
        tag: '30 gold', tagKind: 'gold', note: 'You have 127'),
    Pick('Refuse and fight', Act.fight,
        tag: 'Fight',
        tagKind: 'blood',
        note: 'Slum thug',
        leadsTo: 'Your Family’s House'),
  ],
);

const house = SceneSpec(
  place: 'Your Family’s House',
  crumb: '… of Alster  ›  Alster  ›  The Lower Town  ›',
  facingName: 'Aurel Vane',
  facingSprite: 'aurel_vane',
  line: 'He holds your sister off the ground by one wrist.',
  prompt: 'What do you do about Vane?',
  mapSeed: 8,
  destination: 'The Black Hold',
  hasFight: true,
  picks: [
    Pick('Charge him', Act.fight,
        tag: 'Fight', tagKind: 'blood', note: 'Aurel Vane'),
    Pick('Kneel and beg him to spare her', Act.decide,
        tag: 'Good +2', tagKind: 'void', leadsTo: 'The Black Hold'),
    Pick('Run, and come back for her later', Act.decide,
        tag: 'Evil −2', tagKind: 'void', leadsTo: 'The Black Hold'),
  ],
);

const vane = SceneSpec(
  place: 'Saltmouth Wharf',
  crumb: '… of Saltmouth  ›  Saltmouth  ›',
  facingName: 'Vane, the quartermaster',
  facingSprite: 'inquisition_soldier_02',
  line: 'There were three ways past him, and he knew all of them.',
  prompt: 'How do you get past Vane?',
  mapSeed: 12,
  river: true,
  picks: [
    Pick('Bribe Vane with information', Act.talk, tag: 'CHA DC 12'),
    Pick('Threaten him to clear the path', Act.talk, tag: 'CHA DC 14'),
    Pick('Push past him toward the exit', Act.decide,
        leadsTo: 'The Ship-breaker’s Yard'),
    Pick('Not yet; back to the wharf', Act.decide),
  ],
);

const price = SceneSpec(
  place: 'The Hollow Shore',
  crumb: '… of the Hollow Coast  ›  The Hollow Shore  ›',
  facingName: null,
  facingSprite: null,
  speaker: 'The Sovereign',
  line:
      'Une porte de cette taille se paie sur le seuil : ce que vous aimiez, ce que vous étiez, ou ce que vous aviez bâti.',
  prompt: 'Que paierez-vous pour la traversée ?',
  mapSeed: 21,
  picks: [
    Pick('Lui donner l’un des nôtres', Act.decide,
        tag: 'Mal −2', tagKind: 'void'),
    Pick('Lui donner le légat', Act.decide, tag: 'Mal −3', tagKind: 'void'),
    Pick('Lui donner votre sang. Ce que la traversée laissera de vous',
        Act.decide),
    Pick('Lui donner le campement. Laisser la côte brûler derrière vous',
        Act.decide,
        tag: 'Mal −4', tagKind: 'void'),
  ],
);

// -------------------------------------------------------------- app chrome

const Color boardInk = Color(0xFFEDE6DC);

/// A phone [w] wide (the shape of a 411 x 890): the app's own chrome, the
/// Journey's header, the body, the bottom bar.
class Phone extends StatelessWidget {
  const Phone({super.key, required this.w, required this.child});

  final double w;
  final Widget child;

  double get h => (w * 2.16).roundToDouble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Container(
      width: w,
      height: h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A3642), width: 2),
      ),
      child: MediaQuery(
        data: MediaQueryData(size: Size(w, h)),
        child: Column(children: [
          // The app bar.
          SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                const Icon(Icons.home_outlined, size: 22),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CHAPTER 1',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: ink.ember,
                            fontFamily: InkFonts.system,
                            fontSize: 8)),
                    Text('Story',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontFamily: InkFonts.display)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.map_outlined, size: 20),
                if (w > 360) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.balance, size: 20),
                ],
                const SizedBox(width: 12),
                Text('EN',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontFamily: InkFonts.system)),
              ]),
            ),
          ),
          Expanded(child: child),
          // The bottom bar.
          Container(
            height: 58,
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final (icon, label, on) in const [
                  (Icons.alt_route, 'Journey', true),
                  (Icons.person_outline, 'Character', false),
                  (Icons.local_fire_department_outlined, 'Camp', false),
                  (Icons.more_horiz, 'Other', false),
                ])
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20, color: on ? ink.gold : ink.ash),
                      Text(label,
                          style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9, color: on ? ink.gold : ink.ash)),
                    ],
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// The status line and the breadcrumb under the header.
Widget journeyHeader(BuildContext context, SceneSpec s, {bool fr = false}) {
  final theme = Theme.of(context);
  final ink = InkColors.of(context);
  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text('Lvl 1   D1   96/108   8/6   127   1',
            style: theme.textTheme.labelSmall
                ?.copyWith(fontFamily: InkFonts.system, fontSize: 9)),
      ),
      const SizedBox(height: 4),
      Row(children: [
        Flexible(
          child: Text(s.place,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontFamily: InkFonts.display)),
        ),
        const SizedBox(width: 6),
        Icon(Icons.star_border, size: 16, color: ink.gold),
      ]),
    ]),
  );
}

// ------------------------------------------------------------------- map

/// A map like the District zoom: rings, a plan of building boxes, a river,
/// the party's marker, and (when [focus] is set) the road of a choice that
/// moves the party, to a pin with its name.
class MapMock extends StatelessWidget {
  const MapMock({
    super.key,
    required this.seed,
    this.river = false,
    this.dim = 0.0,
    this.focus,
    this.showMarker = true,
    this.zoom = 1.0,
  });

  final int seed;
  final bool river;

  /// 0 to 1: how much the map is darkened.
  final double dim;

  /// The name of a pin the road to which is lit.
  final String? focus;
  final bool showMarker;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    return LayoutBuilder(builder: (context, box) {
      return ClipRect(
        child: Stack(children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MapPainter(seed, river, ink.tide, focus != null, zoom),
            ),
          ),
          Positioned.fill(
              child: ColoredBox(color: Colors.black.withValues(alpha: dim))),
          if (showMarker)
            Align(
              alignment: const Alignment(-0.1, 0.1),
              child: _Marker(ink.gold),
            ),
          if (focus != null)
            Align(
              alignment: const Alignment(0.7, -0.55),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14121A),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: ink.voidColor),
                  ),
                  child: Text(focus!,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: const Color(0xFFEDE6DC))),
                ),
                Icon(Icons.place, size: 22, color: ink.voidColor),
              ]),
            ),
        ]),
      );
    });
  }
}

class _Marker extends StatelessWidget {
  const _Marker(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: const Color(0xFF14121A), width: 3),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 14),
          ],
        ),
        child: const Icon(Icons.person_outline,
            size: 17, color: Color(0xFF14121A)),
      );
}

class _MapPainter extends CustomPainter {
  const _MapPainter(this.seed, this.river, this.water, this.road, this.zoom);

  final int seed;
  final bool river;
  final Color water;
  final bool road;
  final double zoom;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF1A1820));
    final c = Offset(s.width * 0.45, s.height * 0.55);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF2A2833);
    for (var r = 40.0 * zoom; r < s.longestSide; r += 70 * zoom) {
      canvas.drawCircle(c, r, line);
    }
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
          c, c + Offset(math.cos(a), math.sin(a)) * s.longestSide, line);
    }
    final rng = math.Random(seed);
    final box = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF34313F);
    for (var i = 0; i < 70; i++) {
      final p = Offset(rng.nextDouble() * s.width, rng.nextDouble() * s.height);
      final sz = (10 + rng.nextDouble() * 18) * zoom;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(rng.nextDouble() * 0.9);
      canvas.drawRect(
          Rect.fromLTWH(0, 0, sz, sz * (0.6 + rng.nextDouble())), box);
      canvas.restore();
    }
    if (river) {
      final path = Path()
        ..moveTo(s.width * 0.55, -10)
        ..cubicTo(s.width * 0.5, s.height * 0.3, s.width * 0.3, s.height * 0.35,
            s.width * 0.4, s.height * 0.6)
        ..cubicTo(s.width * 0.5, s.height * 0.8, s.width * 0.35,
            s.height * 0.95, s.width * 0.4, s.height + 10);
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 22 * zoom
            ..color = water.withValues(alpha: 0.35));
    }
    if (road) {
      final from = c;
      final to = Offset(s.width * 0.85, s.height * 0.22);
      final dash = Paint()
        ..color = const Color(0xFFB08AD9)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      final d = to - from;
      final n = (d.distance / 9).floor();
      for (var i = 0; i < n; i += 2) {
        canvas.drawLine(from + d * (i / n), from + d * ((i + 1) / n), dash);
      }
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => false;
}

// ----------------------------------------------------------------- sprites

/// A standing figure from the real sprite sheets: the ronin (a strip of
/// frames, the first drawn) or a fighter's single west-facing frame.
class Figure extends StatelessWidget {
  const Figure.hero({super.key, required this.px, this.dim = false})
      : sprite = null;
  const Figure.foe(this.sprite,
      {super.key, required this.px, this.dim = false});

  final String? sprite;
  final double px;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final hero = sprite == null;
    final w = (hero ? 42 : 48) * px;
    final h = (hero ? 47 : 48) * px;
    final image = Image.asset(
      hero
          ? 'assets/visuals/walker/ronin_idle_east.png'
          : 'assets/visuals/fighters/${sprite}_idle_west.png',
      filterQuality: FilterQuality.none,
      fit: BoxFit.fitHeight,
      height: h,
      alignment: Alignment.centerLeft,
    );
    return Opacity(
      opacity: dim ? 0.55 : 1,
      child: SizedBox(
        width: w,
        height: h,
        child: ClipRect(
          child: hero
              ? Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1 / 8,
                  child: image)
              : image,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ choice cards

Color _tagColor(InkColors ink, String? kind) => switch (kind) {
      'gold' => ink.gold,
      'blood' => ink.blood,
      'void' => ink.voidColor,
      _ => ink.tide,
    };

IconData _icon(Act a) => switch (a) {
      Act.fight => Icons.sports_kabaddi,
      Act.pay => Icons.paid_outlined,
      Act.decide => Icons.balance,
      Act.talk => Icons.chat_bubble_outline,
    };

Color _actColor(InkColors ink, Act a) => switch (a) {
      Act.fight => ink.blood,
      Act.pay => ink.gold,
      Act.decide => ink.voidColor,
      Act.talk => ink.tide,
    };

/// The real choice card for [p]; [selected] shows Go.
Widget card(BuildContext context, Pick p,
    {bool selected = false, String go = 'Go'}) {
  final ink = InkColors.of(context);
  return ChoiceCard(
    icon: _icon(p.act),
    color: _actColor(ink, p.act),
    text: p.text,
    goLabel: go,
    notes: [if (p.note != null) p.note!],
    leadsTo: p.leadsTo,
    tag: p.tag == null ? null : ChoiceTag(p.tag!, _tagColor(ink, p.tagKind)),
    selected: selected,
    onTap: () {},
    onGo: () {},
  );
}

/// A choice as a speech bubble from the hero: the same words, tag and
/// destination, in a bubble whose tail points back at the hero's side.
class Bubble extends StatelessWidget {
  const Bubble(this.p, {super.key, this.selected = false, this.dim = false});

  final Pick p;
  final bool selected;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final tone = _actColor(ink, p.act);
    final bg = selected
        ? Color.alphaBlend(
            tone.withValues(alpha: 0.22), const Color(0xFFF1E8D2))
        : const Color(0xFFF1E8D2);
    return Opacity(
      opacity: dim ? 0.45 : 1,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, bottom: 6),
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tone, width: selected ? 2.4 : 1.6),
            ),
            child: Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(shape: BoxShape.circle, color: tone),
                child: Icon(_icon(p.act), size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: InkFonts.prose,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: const Color(0xFF1B1812))),
                    if (p.note != null)
                      Text(p.note!,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: const Color(0xFF6A604E))),
                    if (p.leadsTo != null)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.arrow_forward,
                            size: 11, color: Color(0xFF6A604E)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(p.leadsTo!,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: const Color(0xFF6A604E))),
                        ),
                      ]),
                  ],
                ),
              ),
              if (p.tag != null) ...[
                const SizedBox(width: 6),
                Text(p.tag!,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: tone, fontWeight: FontWeight.w700)),
              ],
            ]),
          ),
          // The tail, at the left, toward the hero.
          Positioned(
            left: -8,
            top: 14,
            child:
                CustomPaint(size: const Size(10, 12), painter: _Tail(bg, tone)),
          ),
        ]),
      ),
    );
  }
}

class _Tail extends CustomPainter {
  const _Tail(this.fill, this.edge);

  final Color fill;
  final Color edge;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()
      ..moveTo(s.width, 0)
      ..lineTo(0, s.height * 0.5)
      ..lineTo(s.width, s.height)
      ..close();
    canvas.drawPath(p, Paint()..color = fill);
    canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = edge);
  }

  @override
  bool shouldRepaint(_Tail old) => false;
}

// ------------------------------------------------------------ panel design

/// The refined scene panel: the map stays in view above (lit, with the road
/// of a choice that moves you), the panel under it is a compact vignette, the
/// question and the cards; with four choices or a long text the vignette
/// folds to one line so the cards keep their room, and a list that is still
/// too long scrolls under a fade.
Widget panelScreen(BuildContext context, SceneSpec s, double w,
    {int selected = -1, bool fr = false}) {
  final theme = Theme.of(context);
  final ink = InkColors.of(context);
  final narrow = w < 360;
  final long = s.picks.any((p) => p.text.length > 46) || s.picks.length >= 4;
  final mapH = narrow ? 118.0 : 190.0;
  final focus = selected >= 0 && s.picks[selected].moves
      ? s.picks[selected].leadsTo
      : null;
  return Column(children: [
    journeyHeader(context, s, fr: fr),
    SizedBox(
      height: mapH,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(children: [
            MapMock(seed: s.mapSeed, river: s.river, dim: 0.18, focus: focus),
            Positioned(
              left: 8,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF14121A).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(s.place,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontFamily: InkFonts.display)),
              ),
            ),
          ]),
        ),
      ),
    ),
    const SizedBox(height: 8),
    Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          border: Border(
              top: BorderSide(
                  color: ink.gold.withValues(alpha: 0.6), width: 1.5)),
        ),
        child: Column(children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(top: 6, bottom: 6),
              decoration: BoxDecoration(
                color: ink.ash,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: long
                ? _speakerLine(context, s, narrow)
                : _vignette(context, s, narrow),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(s.prompt,
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontFamily: InkFonts.prose, fontStyle: FontStyle.italic)),
            ),
          ),
          Expanded(
            child: Stack(children: [
              ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                children: [
                  for (var i = 0; i < s.picks.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: card(context, s.picks[i],
                          selected: i == selected, go: fr ? 'Aller' : 'Go'),
                    ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 22,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.surfaceContainerHigh
                              .withValues(alpha: 0),
                          theme.colorScheme.surfaceContainerHigh,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    ),
  ]);
}

/// One line for who you face: its head, its name, the line it just said.
Widget _speakerLine(BuildContext context, SceneSpec s, bool narrow) {
  final theme = Theme.of(context);
  final ink = InkColors.of(context);
  return Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(children: [
      SizedBox(
        width: 40,
        height: 40,
        child: ClipRect(
          child: s.facingSprite == null
              ? Icon(Icons.record_voice_over_outlined, color: ink.voidColor)
              : FittedBox(
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.8),
                  child: Figure.foe(s.facingSprite, px: 1)),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text((s.facingName ?? s.speaker ?? '').toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: InkFonts.system, color: ink.ash, fontSize: 9)),
          Text(s.line,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: InkFonts.prose, fontStyle: FontStyle.italic)),
        ]),
      ),
    ]),
  );
}

/// The vignette: you and who you face on one ground line, the line said
/// under them.
Widget _vignette(BuildContext context, SceneSpec s, bool narrow) {
  final theme = Theme.of(context);
  final ink = InkColors.of(context);
  final px = narrow ? 1.6 : 2.6;
  return Column(children: [
    Container(
      height: px * 48 + 30,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 22,
          child: Container(height: 1.5, color: ink.gold.withValues(alpha: 0.5)),
        ),
        Positioned(
          left: narrow ? 30 : 56,
          bottom: 23,
          child: Figure.hero(px: px),
        ),
        if (s.facingSprite != null)
          Positioned(
            right: narrow ? 30 : 56,
            bottom: 23,
            child: Figure.foe(s.facingSprite, px: px),
          ),
        Positioned(
          left: narrow ? 30 : 56,
          bottom: 5,
          child: Text('YOU',
              style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: InkFonts.system, color: ink.ash, fontSize: 8)),
        ),
        if (s.facingName != null)
          Positioned(
            right: narrow ? 30 : 56,
            bottom: 5,
            child: Text(s.facingName!.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: InkFonts.system, color: ink.ash, fontSize: 8)),
          ),
      ]),
    ),
    Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(s.line,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: InkFonts.prose, fontStyle: FontStyle.italic)),
    ),
  ]);
}

// ------------------------------------------------------------ stage design

/// The refined stage: the map zoomed behind, dimmed, the two figures on one
/// ground line with the other's line in a bubble over it, and the choices
/// NOT over the figures: a tray of bubbles under the stage, a thread running
/// from the hero down it, each tail turned to the thread. A moving choice
/// names where it goes and, picked, its door lights at the stage's edge.
Widget stageScreen(BuildContext context, SceneSpec s, double w,
    {int selected = -1, bool fr = false, bool balloon = false}) {
  final theme = Theme.of(context);
  final ink = InkColors.of(context);
  final narrow = w < 360;
  final stageH = narrow ? 236.0 : 330.0;
  final px = narrow ? 2.2 : 3.0;
  final doorLit = selected >= 0 && s.picks[selected].moves;
  return Column(children: [
    journeyHeader(context, s, fr: fr),
    SizedBox(
      height: stageH,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(children: [
            MapMock(
                seed: s.mapSeed,
                river: s.river,
                dim: 0.5,
                showMarker: false,
                zoom: 1.6),
            // The ground line.
            Positioned(
              left: 0,
              right: 0,
              bottom: 26,
              child:
                  Container(height: 2, color: ink.gold.withValues(alpha: 0.7)),
            ),
            Positioned(
              left: narrow ? 28 : 52,
              bottom: 27,
              child: Figure.hero(px: px),
            ),
            Positioned(
              left: narrow ? 28 : 52,
              bottom: 6,
              child: Text('YOU',
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: InkFonts.system,
                      color: ink.ash,
                      fontSize: 9)),
            ),
            if (s.facingSprite != null)
              Positioned(
                right: narrow ? 28 : 52,
                bottom: 27,
                child: Figure.foe(s.facingSprite, px: px),
              ),
            // The hero's balloon: the picked choice said aloud, over the hero.
            if (balloon && selected >= 0)
              Positioned(
                left: 10,
                top: 8,
                right: narrow ? 70 : 120,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1E8D2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _actColor(ink, s.picks[selected].act), width: 2),
                  ),
                  child: Text('“${s.picks[selected].text}”',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: InkFonts.prose,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1B1812))),
                ),
              ),
            // The other's line, over their head, small.
            if (!(balloon && selected >= 0))
              Positioned(
                right: 10,
                top: 8,
                left: narrow ? 100 : 150,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14121A).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ink.ash.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text((s.facingName ?? s.speaker ?? '').toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                                fontFamily: InkFonts.system,
                                color: ink.gold,
                                fontSize: 8)),
                        Text(s.line,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: InkFonts.prose,
                                fontStyle: FontStyle.italic,
                                fontSize: narrow ? 11 : 12)),
                      ]),
                ),
              ),
            // The doors: where a choice that moves you goes, at the edge.
            Positioned(
              right: 0,
              top: narrow ? 98.0 : 122.0,
              child: _Door(
                label: s.destination ??
                    s.picks
                        .firstWhere((p) => p.moves,
                            orElse: () => const Pick('', Act.decide))
                        .leadsTo ??
                    '',
                lit: doorLit,
                show: s.picks.any((p) => p.moves),
              ),
            ),
          ]),
        ),
      ),
    ),
    const SizedBox(height: 8),
    Expanded(
      child: Stack(children: [
        // The thread from the hero down the tray.
        Positioned(
          left: narrow ? 40 : 64,
          top: 0,
          bottom: 0,
          child: Container(width: 2, color: ink.gold.withValues(alpha: 0.5)),
        ),
        ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(narrow ? 30 : 54, 2, 12, 8),
          children: [
            for (var i = 0; i < s.picks.length; i++)
              Bubble(s.picks[i],
                  selected: i == selected && !balloon,
                  dim: selected >= 0 && (i != selected || balloon)),
          ],
        ),
      ]),
    ),
  ]);
}

class _Door extends StatelessWidget {
  const _Door({required this.label, required this.lit, required this.show});

  final String label;
  final bool lit;
  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final tone = lit ? ink.gold : ink.ash;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF14121A).withValues(alpha: lit ? 0.95 : 0.7),
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
        border: Border.all(color: tone, width: lit ? 2 : 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: tone, fontWeight: FontWeight.w700)),
        const SizedBox(width: 3),
        Icon(Icons.arrow_forward, size: 14, color: tone),
      ]),
    );
  }
}
