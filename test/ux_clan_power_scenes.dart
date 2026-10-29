// The places of the clan power sign mock (ux_clan_power_mock_test.dart): the
// clan list, a clan's page, the clan banner chip and the district view, each
// drawn for one of the three ideas (and today's cloth for the compare board)
// at a given width, from the real banners, standing discs and the app's own
// theme. Mock only; nothing here ships.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:narrative_data_app/widgets/pixel_banner.dart';
import 'package:narrative_data_app/data/factions.dart';

import 'ux_clan_power_parts.dart';

const _boardInk = Color(0xFFEDE6DC);

/// A caption above a place, then the place on the app's parchment at [w].
Widget place(BuildContext context, String caption, double w, Widget child) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(caption,
              style: const TextStyle(
                  fontFamily: 'Spectral',
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFFB9B0C2))),
        ),
        Container(
          width: w,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF3A3642), width: 2),
          ),
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ],
    ),
  );
}

/// Idea [idea]'s mark of [c] for a list row's right side.
Widget rowMark(Idea idea, SampleClan c) {
  switch (idea) {
    case Idea.cloth:
      return Text(tierName(c.power), style: px(10, c: ash));
    case Idea.ranking:
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Plate(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('#${rankOf(c)}', style: px(11, c: gold)),
              const SizedBox(width: 3),
              Trend(c.delta, size: 8, onDark: true),
            ]),
          ),
          const SizedBox(height: 3),
          Text('${c.power}  ${signed(c.delta)}', style: px(10, c: ash)),
        ],
      );
    case Idea.torches:
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Torches(c.power, height: 20),
          const SizedBox(height: 2),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Trend(c.delta, size: 7),
            const SizedBox(width: 3),
            Text(tierName(c.power), style: px(9, c: ash)),
          ]),
        ],
      );
    case Idea.skyline:
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Trend(c.delta, size: 8),
        const SizedBox(width: 3),
        Text('${c.power}', style: px(12)),
      ]);
  }
}

const _listClans = ['dominion', 'crows', 'compact', 'vigil', 'kindly'];

/// The clan list: a banner with its standing disc, the name and standing
/// words, and the power sign of the idea at the right.
Widget clanList(BuildContext context, Idea idea, double w) {
  final theme = Theme.of(context);
  final narrow = w < 360;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Clans', style: theme.textTheme.titleMedium),
      if (idea == Idea.skyline) ...[
        const SizedBox(height: 6),
        Text('STRENGTH OF THE CLANS',
            style: px(9, c: ash).copyWith(letterSpacing: 1)),
        const SizedBox(height: 2),
        Skyline(width: w - 24, height: 90),
      ],
      const SizedBox(height: 6),
      for (final id in _listClans)
        _listRow(context, idea, clanById(id), narrow),
    ],
  );
}

Widget _listRow(BuildContext context, Idea idea, SampleClan c, bool narrow) {
  final theme = Theme.of(context);
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
    decoration: BoxDecoration(
      color: c.color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: c.color.withValues(alpha: 0.7)),
    ),
    child: Row(children: [
      bannerWithDisc(c, 46, cloth: idea == Idea.cloth, disc: 22),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall),
            Text(_standingWord(c.standing),
                style: theme.textTheme.labelSmall?.copyWith(
                    color: Color(tierColor(c.standing) | 0xFF000000),
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      rowMark(idea, c),
    ]),
  );
}

String _standingWord(StandingTier t) =>
    '${t.name[0].toUpperCase()}${t.name.substring(1)}';

/// A clan's page (the clan card): banner and disc, name, standing, then the
/// power block of the idea.
Widget clanPage(BuildContext context, Idea idea, double w, SampleClan c) {
  final theme = Theme.of(context);
  final narrow = w < 360;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        bannerWithDisc(c, 76, cloth: idea == Idea.cloth, disc: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name,
                  style: theme.textTheme.titleMedium?.copyWith(color: c.color)),
              Text(_standingWord(c.standing),
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: Color(tierColor(c.standing) | 0xFF000000),
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('“Blood and one road.”',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ]),
      const SizedBox(height: 10),
      _powerBlock(context, idea, w - 24, c, narrow),
    ],
  );
}

Widget _heading(String s) =>
    Text(s, style: px(10, c: ash).copyWith(letterSpacing: 1));

Widget _powerBlock(
    BuildContext context, Idea idea, double w, SampleClan c, bool narrow) {
  final theme = Theme.of(context);
  switch (idea) {
    case Idea.cloth:
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading('POWER'),
          const SizedBox(height: 4),
          Text('${tierName(c.power)} · ${c.power}',
              style: theme.textTheme.labelMedium),
        ],
      );
    case Idea.ranking:
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _heading('STRENGTH'),
            const Spacer(),
            Plate(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('#${rankOf(c)} of ${sampleClans.length}',
                    style: px(11, c: gold)),
                const SizedBox(width: 4),
                Trend(c.delta, size: 8, onDark: true),
                const SizedBox(width: 3),
                Text(signed(c.delta), style: px(11, c: gold)),
              ]),
            ),
          ]),
          const SizedBox(height: 6),
          RankedBars(highlight: c.id, width: w),
          const SizedBox(height: 6),
          Text(
              narrow
                  ? 'Ticks: Rising 25 · Dominant 50 · Ascendant 75.\nDashed: can attack (10+). Arrow: since last chapter.'
                  : 'Ticks mark Rising 25, Dominant 50, Ascendant 75; the dashed line is the 10 a clan needs to attack; the arrow is how it moved since the last chapter.',
              style: theme.textTheme.labelSmall?.copyWith(color: ash)),
        ],
      );
    case Idea.torches:
      final rank = rankOf(c);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading('MUSTER'),
          const SizedBox(height: 6),
          Row(children: [
            Torches(c.power, height: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${tierName(c.power)} · ${c.power}',
                      style: theme.textTheme.titleSmall),
                  Row(children: [
                    Trend(c.delta, size: 9),
                    const SizedBox(width: 4),
                    Text('${signed(c.delta)} since last chapter',
                        style: theme.textTheme.labelSmall),
                  ]),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 8),
          _line(
              context,
              Icons.local_fire_department,
              c.power >= attackPower
                  ? 'Can attack (10 power or more)'
                  : 'Too weak to attack (needs 10)'),
          _line(context, Icons.emoji_events_outlined,
              '${_ordinal(rank)} of ${sampleClans.length}: stronger than ${sampleClans.length - rank} clans'),
          _line(context, Icons.flag_outlined,
              'Next torch is full at ${((c.power ~/ 25) + 1) * 25}'),
        ],
      );
    case Idea.skyline:
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _heading('STRENGTH'),
            const Spacer(),
            Trend(c.delta, size: 9),
            const SizedBox(width: 4),
            Text('${tierName(c.power)} · ${c.power}  ${signed(c.delta)}',
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Skyline(width: w, height: 120, highlight: c.id),
          const SizedBox(height: 6),
          Text(
              narrow
                  ? 'Tall is strong. Dotted: Rising, Dominant, Ascendant.\nDashed: can attack (10+). Gold edge: grew; dashed outline: shrank.'
                  : 'The taller the banner the stronger the clan. Dotted lines: Rising, Dominant, Ascendant; dashed: the 10 power to attack. A gold edge is what it gained since the last chapter, a dashed outline what it lost.',
              style: theme.textTheme.labelSmall?.copyWith(color: ash)),
        ],
      );
  }
}

String _ordinal(int n) => switch (n) {
      1 => '1st',
      2 => '2nd',
      3 => '3rd',
      _ => '${n}th',
    };

Widget _line(BuildContext context, IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(children: [
        Icon(icon, size: 14, color: goldDeep),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text, style: Theme.of(context).textTheme.labelSmall)),
      ]),
    );

/// The mark of the idea at a banner chip's end.
Widget chipMark(Idea idea, SampleClan c) {
  switch (idea) {
    case Idea.cloth:
      return const SizedBox.shrink();
    case Idea.ranking:
      return Plate(
        pad: 2,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('#${rankOf(c)}', style: px(10, c: gold)),
          const SizedBox(width: 2),
          Trend(c.delta, size: 7, onDark: true),
        ]),
      );
    case Idea.torches:
      return Torches(c.power, height: 14);
    case Idea.skyline:
      return Row(mainAxisSize: MainAxisSize.min, children: [
        MiniSky(highlight: c.id),
        const SizedBox(width: 3),
        Trend(c.delta, size: 7),
      ]);
  }
}

/// Ten little bars, the clans from the strongest down, this clan's in gold:
/// where it stands in the pack, at a chip's size.
class MiniSky extends StatelessWidget {
  const MiniSky({super.key, required this.highlight});

  final String highlight;

  @override
  Widget build(BuildContext context) {
    final clans = byStrength();
    return SizedBox(
      width: clans.length * 4.0,
      height: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final c in clans)
            Padding(
              padding: const EdgeInsets.only(right: 1),
              child: Container(
                width: 3,
                height: 3 + 13 * c.power / 60,
                color: c.id == highlight ? gold : ash.withValues(alpha: 0.55),
              ),
            ),
        ],
      ),
    );
  }
}

Widget chip(Idea idea, SampleClan c, {bool dark = false}) => Container(
      padding: const EdgeInsets.fromLTRB(5, 3, 7, 3),
      decoration: BoxDecoration(
        color: c.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.color.withValues(alpha: 0.75)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        idea == Idea.cloth
            ? clothFlag(c, 22)
            : ClanFlag(factionId: c.id, height: 22),
        const SizedBox(width: 5),
        Text(c.name,
            style: const TextStyle(
                fontFamily: 'Spectral', fontSize: 12, color: ink)),
        if (idea != Idea.cloth) const SizedBox(width: 6),
        chipMark(idea, c),
      ]),
    );

/// The banner chip where clans are named in lines of text (an offer's giver,
/// a piece of news): three chips, one rising, one falling, one weak.
Widget chipRow(BuildContext context, Idea idea, double w) {
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Offered by', style: theme.textTheme.bodySmall),
            chip(idea, clanById('crows')),
          ]),
      const SizedBox(height: 8),
      Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            chip(idea, clanById('vigil')),
            Text('lost ground to', style: theme.textTheme.bodySmall),
            chip(idea, clanById('kindly')),
          ]),
    ],
  );
}

class _Cell {
  const _Cell(this.name, this.holder, this.rect);

  final String name;
  final String holder;
  final Rect rect;
}

/// The district view where clans hold land: six districts washed in their
/// holder's colour, the holder's banner at each seat with the idea's power
/// sign, and under it the line a siege reads from.
Widget districtView(BuildContext context, Idea idea, double w) {
  final theme = Theme.of(context);
  final inner = w - 24;
  final h = inner * 0.62;
  const cells = [
    _Cell('Candlehold', 'dominion', Rect.fromLTWH(0, 0, 0.42, 0.5)),
    _Cell('Old Wall', 'vigil', Rect.fromLTWH(0.42, 0, 0.3, 0.5)),
    _Cell('Tide Steps', 'tidekin', Rect.fromLTWH(0.72, 0, 0.28, 0.5)),
    _Cell('Lower Town', 'compact', Rect.fromLTWH(0, 0.5, 0.36, 0.5)),
    _Cell('Salt Quay', 'crows', Rect.fromLTWH(0.36, 0.5, 0.36, 0.5)),
    _Cell('The Fen', 'mire', Rect.fromLTWH(0.72, 0.5, 0.28, 0.5)),
  ];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Saltmouth', style: theme.textTheme.titleMedium),
      const SizedBox(height: 6),
      SizedBox(
        width: inner,
        height: h,
        child: Stack(children: [
          for (final c in cells) _cell(context, idea, c, inner, h),
        ]),
      ),
      const SizedBox(height: 8),
      Row(children: [
        chip(idea, clanById('crows')),
        const SizedBox(width: 6),
        Expanded(
          child: Text('holds Salt Quay and may attack Compass-held Lower Town',
              style: theme.textTheme.labelSmall),
        ),
      ]),
    ],
  );
}

Widget _cell(BuildContext context, Idea idea, _Cell cell, double w, double h) {
  final c = clanById(cell.holder);
  final r = cell.rect;
  final rect = Rect.fromLTWH(r.left * w, r.top * h, r.width * w, r.height * h);
  final cellH = rect.height;
  Widget seat;
  switch (idea) {
    case Idea.cloth:
      seat = clothFlag(c, math.min(cellH - 22, 44));
    case Idea.ranking:
      seat = Column(mainAxisSize: MainAxisSize.min, children: [
        ClanFlag(factionId: c.id, height: math.min(cellH - 32, 34)),
        const SizedBox(height: 2),
        Plate(
          pad: 1,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('#${rankOf(c)}', style: px(9, c: gold)),
            const SizedBox(width: 2),
            Trend(c.delta, size: 6, onDark: true),
          ]),
        ),
      ]);
    case Idea.torches:
      seat = Column(mainAxisSize: MainAxisSize.min, children: [
        ClanFlag(factionId: c.id, height: math.min(cellH - 28, 34)),
        const SizedBox(height: 2),
        Torches(c.power, height: 11),
      ]);
    case Idea.skyline:
      // The banner planted at the seat stands as high as the clan's power.
      seat = SizedBox(
        height: cellH - 8,
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (c.delta != 0) Trend(c.delta, size: 7),
          ClanFlag(
              factionId: c.id, height: Skyline.heightOf(c.power, cellH - 18)),
        ]),
      );
  }
  return Positioned(
    left: rect.left,
    top: rect.top,
    width: rect.width,
    height: rect.height,
    child: Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: c.color.withValues(alpha: 0.22),
        border: Border.all(color: c.color.withValues(alpha: 0.85), width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(children: [
        Positioned(
          left: 6,
          top: 3,
          child: Text(cell.name,
              style: const TextStyle(
                  fontFamily: 'Spectral', fontSize: 10, color: ink)),
        ),
        Align(alignment: const Alignment(0, 0.6), child: seat),
      ]),
    ),
  );
}

// ------------------------------------------------------------- the boards

Widget titleBar(String title, String note) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Spectral',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: _boardInk)),
          const SizedBox(height: 4),
          Text(note,
              style: const TextStyle(
                  fontFamily: 'Spectral',
                  fontSize: 13,
                  height: 1.3,
                  color: Color(0xFFB9B0C2))),
        ],
      ),
    );

/// The four places of [idea] at [w] px.
Widget placesColumn(BuildContext context, Idea idea, double w) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${w.round()} px',
            style: const TextStyle(
                fontFamily: 'PixelifySans', fontSize: 14, color: gold)),
        const SizedBox(height: 6),
        place(context, 'The clan list', w, clanList(context, idea, w)),
        place(context, 'A clan\'s page (Crows)', w,
            clanPage(context, idea, w, clanById('crows'))),
        place(context, 'The banner chip (an offer, the news)', w,
            chipRow(context, idea, w)),
        place(context, 'The district view', w, districtView(context, idea, w)),
      ],
    );

Widget board(BuildContext context, Idea idea, String title, String note) =>
    Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 760, child: titleBar(title, note)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              placesColumn(context, idea, 412),
              const SizedBox(width: 28),
              placesColumn(context, idea, 320),
            ],
          ),
        ],
      ),
    );

/// The compare board: today's cloth at three sizes with what is unclear
/// about it, then four clans four ways.
Widget compareBoard(BuildContext context) {
  final note = const TextStyle(
      fontFamily: 'Spectral', fontSize: 13, height: 1.35, color: _boardInk);
  Widget sizes() => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final id in ['dominion', 'vigil', 'crows', 'kindly'])
            Padding(
              padding: const EdgeInsets.only(right: 22),
              child: Column(children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  clothFlag(clanById(id), 128),
                  const SizedBox(width: 8),
                  clothFlag(clanById(id), 64),
                  const SizedBox(width: 8),
                  clothFlag(clanById(id), 34),
                ]),
                const SizedBox(height: 6),
                Text('${clanById(id).name} ${clanById(id).power}',
                    style: note.copyWith(fontSize: 12)),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 22),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final id in ['choir', 'pit'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClanFlag(factionId: id, height: 64),
                  ),
              ]),
              const SizedBox(height: 6),
              Text('Choir, Pit: no power', style: note.copyWith(fontSize: 12)),
            ]),
          ),
        ],
      );
  const issues = [
    'It reads as a loading bar or as damage, not as strength: nothing on it says "power", and the gold hairline looks like a tear line.',
    'Four steps only: a clan at 26 and one at 49 look the same, so do 0 and 24. It cannot say "rising" or "falling".',
    'A weak clan loses its sign: the banner is black cloth with cream marks, and the cloth hides everything above the level, so a Minor clan shows only its foot. Kindly Ones and Oni, the clans the player must still recognise, become unreadable, most of all at 34 px.',
    'Clans with no power (the Choir, the Pit, the Open Hand) keep a whole banner, so they look like the strongest.',
    'It cannot be compared: you have to open every clan to rank them, and nothing marks the 10 power a clan needs to attack.',
    'Two gauges on one banner: the cloth and the standing disc both read as "how full", so strength gets mixed up with how the clan likes you.',
  ];
  Widget cell(Widget child) =>
      SizedBox(width: 168, child: Center(child: child));
  Widget four(SampleClan c) => Row(children: [
        SizedBox(
            width: 90,
            child: Text('${c.name}\n${c.power} (${signed(c.delta)})',
                style: note.copyWith(fontSize: 12))),
        cell(clothFlag(c, 44)),
        cell(Row(mainAxisSize: MainAxisSize.min, children: [
          ClanFlag(factionId: c.id, height: 44),
          const SizedBox(width: 6),
          Plate(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('#${rankOf(c)}', style: px(12, c: gold)),
            const SizedBox(width: 3),
            Trend(c.delta, size: 9, onDark: true),
          ])),
        ])),
        cell(Row(mainAxisSize: MainAxisSize.min, children: [
          ClanFlag(factionId: c.id, height: 44),
          const SizedBox(width: 6),
          Torches(c.power, height: 26),
        ])),
        cell(Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClanFlag(factionId: c.id, height: Skyline.heightOf(c.power, 60)),
              const SizedBox(width: 4),
              Trend(c.delta, size: 8),
            ])),
      ]);
  return Padding(
    padding: const EdgeInsets.all(24),
    child: SizedBox(
      width: 1000,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBar('Clan power: today\'s cloth, and three other ways',
              'The banner fills from the foot in a quarter for each of Minor, Rising, Dominant, Ascendant (v1.576). Below: what it looks like, and what is unclear about it.'),
          sizes(),
          const SizedBox(height: 14),
          for (final line in issues)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('•  $line', style: note),
            ),
          const SizedBox(height: 18),
          Text('The same four clans, five ways',
              style: note.copyWith(fontSize: 16, color: gold)),
          const SizedBox(height: 10),
          Row(children: [
            const SizedBox(width: 90),
            for (final t in const [
              'Today: the cloth',
              'A. Ranking',
              'B. Torches',
              'C. Skyline'
            ])
              cell(Text(t, style: note.copyWith(color: gold))),
          ]),
          const SizedBox(height: 6),
          for (final id in ['dominion', 'crows', 'vigil', 'kindly'])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: four(clanById(id)),
            ),
        ],
      ),
    ),
  );
}
