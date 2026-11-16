// Three card directions for the skills and the level-up pick (UX_SHOTS=<folder>):
// the skill tree and list, a skill's detail, the level-up offer (a skill to
// learn, a merge, a tier to raise) with its hover and picked states, and a
// strip of frames for a short gif of the pick. Real skills from skills.json
// and skill_trees.json, the game's theme and fonts, the harmonised skill icons,
// the Apollo palette (docs/art/palette-apollo.md). Mock only: nothing here is
// used by the app. Drawn only with UX_SHOTS (UX_DIR = a, b or c).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/screens/skills/skills_view_model.dart';
import 'package:narrative_data_app/theme/pixel_chip.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';

import 'support/fonts.dart';

// ---------------------------------------------------------------- tokens ---
// Apollo (docs/art/palette-apollo.md): the colours of the skill icons.
const _apOutline = Color(0xFF090A14);
const _apNight = Color(0xFF10141F);
const _apNavy = Color(0xFF172038);
const _apInk = Color(0xFF202E37);
const _apGold = Color(0xFFE8C170);
const _apCore = Color(0xFFF2C14E);
const _apCream = Color(0xFFEBEDE9);

Color _element(String e) => switch (e) {
      'Fire' => const Color(0xFFCF573C),
      'Water' => const Color(0xFF4F8FBA),
      'Wind' => const Color(0xFFA4DDDB),
      'Earth' => const Color(0xFFAD7757),
      'Electricity' => const Color(0xFFE8C170),
      'Void' => const Color(0xFFA23E8C),
      'Light' => const Color(0xFFD0DA91),
      _ => const Color(0xFF819796),
    };

Color _rarity(String r) => switch (r) {
      'uncommon' => const Color(0xFF75A743),
      'rare' => const Color(0xFF4F8FBA),
      'epic' => const Color(0xFFA23E8C),
      'legendary' => const Color(0xFFDE9E41),
      _ => const Color(0xFF819796),
    };

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ------------------------------------------------------------------ data ---
enum St { known, ready, locked }

class Sk {
  Sk(this.id, this.rec, this.st, {this.tier = 0}) : name = skillDisplayName(id);
  final String id;
  final String name;
  final Map<String, dynamic> rec;
  final St st;
  final int tier;
  String get element => rec['element']?.toString() ?? 'None';
  String get rarity => rec['rarity']?.toString() ?? 'common';
  int get cost => (rec['cost'] as num?)?.toInt() ?? 0;
  String get desc => rec['description']?.toString() ?? '';

  /// "+6 damage · ×1.4" at [t] (the tier), built from the game's own numbers.
  String effect([int? t]) {
    final s = applySkillTier(rec, t ?? tier);
    final dmg = (s['damageMod'] as num?)?.toInt() ?? 0;
    final mul = (s['damageMultiplier'] as num?)?.toDouble() ?? 1.0;
    final heal = (s['healAmount'] as num?)?.toInt() ?? 0;
    return [
      if (dmg > 0) '+$dmg damage',
      if (mul > 1.0) '×${mul.toStringAsFixed(1)}',
      if (heal > 0) 'heals $heal',
    ].join(' · ');
  }

  List<({String key, List<String> values})> table() => tierTable(rec);
}

late Map<String, dynamic> _skills;
late Map<String, dynamic> _trees;

Sk sk(String id, St st, {int tier = 0}) =>
    Sk(id, _skills[id] as Map<String, dynamic>, st, tier: tier);

class Branch {
  Branch(this.name, this.blurb, this.skills);
  final String name;
  final String blurb;
  final List<Sk> skills;
}

List<Branch> _mageBranches() => [
      Branch('Evocation', _trees['mage_evocation']['description'] as String, [
        sk('mage_arcane_missile', St.known, tier: 1),
        sk('fireball', St.ready),
        sk('inner_fire', St.locked),
        sk('mage_meteor', St.locked),
      ]),
      Branch('Tempest', _trees['mage_tempest']['description'] as String, [
        sk('focus_mind', St.known),
        sk('mage_frost_nova', St.ready),
        sk('adrenaline_surge', St.locked),
        sk('mage_teleport_strike', St.locked),
      ]),
      Branch('Aegis', _trees['mage_aegis']['description'] as String, [
        sk('mage_channel', St.known, tier: 2),
        sk('mage_mana_shield', St.ready),
        sk('mending_touch', St.locked),
        sk('cauterize_wound', St.locked),
      ]),
    ];

enum Kind { learn, merge, upgrade }

class Offer {
  Offer(this.kind, this.skill,
      {this.from, this.partner, this.clan, this.essence = 0});
  final Kind kind;
  final Sk skill; // what you get (or what is raised)
  final Sk? from; // merge: first input
  final Sk? partner; // merge: second input
  final String? clan;
  final int essence;
}

List<Offer> _offers() {
  final fireball = sk('fireball', St.ready);
  final missile = sk('mage_arcane_missile', St.known, tier: 1);
  final blazing = sk('blazing_shadow', St.locked);
  return [
    Offer(Kind.learn, fireball, clan: 'The Cinder Compact'),
    Offer(Kind.merge, blazing,
        from: sk('fireball', St.known), partner: sk('shadow_step', St.known)),
    Offer(Kind.upgrade, missile, essence: skillTierUpgradeCost(1)),
  ];
}

// ----------------------------------------------------------- shared bits ---
class Plate extends StatelessWidget {
  const Plate(this.s, {super.key, this.size = 56, this.dim = false});
  final Sk s;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final tint = _element(s.element);
    return Opacity(
      opacity: dim ? 0.45 : 1,
      child: Container(
        width: size,
        height: size,
        decoration: ShapeDecoration(
          shape: PixelChipBorder(
              side: const BorderSide(color: _apOutline, width: 1.5),
              step: size > 70 ? 3 : 2),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(_apNavy, tint, 0.38)!,
              Color.lerp(_apNight, tint, 0.14)!,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: SkillPixelIcon(s.id, size: size * 0.72),
      ),
    );
  }
}

class Pips extends StatelessWidget {
  const Pips(this.tier, {super.key, this.size = 6, this.show = true});
  final int tier;
  final double size;
  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < maxSkillTier; i++)
        Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: i < tier ? _apCore : Colors.transparent,
            border: Border.all(
                color: i < tier ? _apGold : const Color(0xFF577277), width: 1),
          ),
        ),
    ]);
  }
}

class Tag extends StatelessWidget {
  const Tag(this.label, this.color, {super.key, this.fill = false, this.dot});
  final String label;
  final Color color;
  final bool fill;
  final bool? dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: ShapeDecoration(
        color:
            fill ? color.withValues(alpha: 0.9) : color.withValues(alpha: 0.14),
        shape: PixelChipBorder(
            side: BorderSide(color: color.withValues(alpha: 0.9), width: 1),
            step: 1.5,
            steps: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot == true) ...[
          Container(width: 6, height: 6, color: color),
          const SizedBox(width: 4),
        ],
        Text(label,
            style: TextStyle(
                fontFamily: InkFonts.system,
                fontSize: 10,
                height: 1.1,
                color: fill ? _apOutline : color)),
      ]),
    );
  }
}

class Cost extends StatelessWidget {
  const Cost(this.n, {super.key, this.size = 22});
  final int n;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: _apNavy,
        shape: PixelChipBorder(
            side: const BorderSide(color: Color(0xFF4F8FBA), width: 1.5),
            step: 2,
            steps: 2),
      ),
      alignment: Alignment.center,
      child: Text('$n',
          style: TextStyle(
              fontFamily: InkFonts.system,
              fontSize: size * 0.55,
              color: const Color(0xFFA4DDDB))),
    );
  }
}

TextStyle _name(BuildContext c, {double size = 14, Color? color}) => TextStyle(
    fontFamily: InkFonts.display,
    fontSize: size,
    height: 1.1,
    color: color ?? Theme.of(c).colorScheme.onSurface);

TextStyle _body(BuildContext c, {double size = 12, Color? color}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: size,
    height: 1.25,
    color: color ?? Theme.of(c).colorScheme.onSurfaceVariant);

TextStyle _sys(BuildContext c, {double size = 11, Color? color}) => TextStyle(
    fontFamily: InkFonts.system,
    fontSize: size,
    height: 1.2,
    color: color ?? Theme.of(c).colorScheme.onSurfaceVariant);

/// The phone's frame: the app bar of the real Skills screen over the page.
class Phone extends StatelessWidget {
  const Phone({super.key, required this.title, required this.child, this.sub});
  final String title;
  final String? sub;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(sub ?? '',
                  style:
                      theme.textTheme.labelMedium?.copyWith(color: ink.gold)),
            ),
          ),
        ],
      ),
      body: child,
    );
  }
}

Widget pickerHeader(BuildContext context, {int level = 7, String hint = ''}) {
  final ink = InkColors.of(context);
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: ink.seam),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text('Level $level',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontFamily: InkFonts.display)),
      const Spacer(),
      Text(hint, style: _sys(context, color: ink.ash)),
    ]),
  );
}

// =============================================================== DIRECTION A
// "Playing cards": a portrait card, the picture on top like a held card.

enum CardState { idle, hover, picked, dim }

class ACard extends StatelessWidget {
  const ACard(this.s,
      {super.key,
      this.w = 150,
      this.h = 196,
      this.state = CardState.idle,
      this.kind,
      this.nameSize = 15,
      this.extra});
  final Sk s;
  final double w, h;
  final CardState state;
  final Kind? kind;
  final double nameSize;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final rar = _rarity(s.rarity);
    final picked = state == CardState.picked;
    final hover = state == CardState.hover;
    final locked = s.st == St.locked;
    final frame = picked ? _apCore : rar;
    Widget card = Container(
      width: w,
      height: h,
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 6),
      decoration: ShapeDecoration(
        color: Color.lerp(
            Theme.of(context).colorScheme.surfaceContainerHigh, _apNavy, 0.35),
        shape: PixelChipBorder(
            side: BorderSide(color: frame, width: picked ? 3 : 2),
            step: 3,
            steps: 3),
        shadows: [
          if (hover || picked)
            BoxShadow(color: frame.withValues(alpha: 0.55), blurRadius: 14),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          if (kind != null)
            Tag(
                switch (kind!) {
                  Kind.learn => 'LEARN',
                  Kind.merge => 'MERGE',
                  Kind.upgrade => 'RAISE',
                },
                frame,
                fill: true)
          else
            Cost(s.cost, size: 20),
          const Spacer(),
          if (locked)
            Icon(Icons.lock_outline, size: 14, color: ink.ash)
          else
            Pips(s.tier,
                size: 6, show: s.st == St.known || kind == Kind.upgrade),
        ]),
        const SizedBox(height: 5),
        Expanded(
          flex: 5,
          child: Center(
              child: extra ??
                  Plate(s, size: (h * 0.36).clamp(48, 84), dim: locked)),
        ),
        const SizedBox(height: 4),
        Text(s.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _name(context, size: nameSize)),
        const SizedBox(height: 3),
        Expanded(
          flex: 3,
          child: Text(s.effect().isEmpty ? s.desc : '${s.effect()}\n${s.desc}',
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: _body(context, size: 10.5)),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (s.element != 'None')
              Tag(s.element, _element(s.element), dot: true),
            const SizedBox(width: 4),
            Tag(_cap(s.rarity), rar),
          ]),
        ),
      ]),
    );
    card = Transform.translate(offset: Offset(0, hover ? -8 : 0), child: card);
    return Opacity(opacity: state == CardState.dim ? 0.4 : 1, child: card);
  }
}

Widget aList(BuildContext context) {
  final branches = _mageBranches();
  final ink = InkColors.of(context);
  return ListView(padding: const EdgeInsets.fromLTRB(12, 8, 12, 20), children: [
    for (final b in branches.take(2)) ...[
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Row(children: [
          Text(b.name.toUpperCase(),
              style: _sys(context, size: 12, color: ink.gold)),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: ink.seam)),
        ]),
      ),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final s in b.skills) ACard(s, w: 163, h: 214),
      ]),
    ],
  ]);
}

Widget aDetail(BuildContext context) {
  final s = sk('fireball', St.ready);
  final ink = InkColors.of(context);
  final rows = s.table();
  return ListView(padding: const EdgeInsets.all(14), children: [
    Center(child: ACard(s, w: 230, h: 320, extra: Plate(s, size: 118))),
    const SizedBox(height: 14),
    Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: ink.seam),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BY TIER', style: _sys(context, color: ink.gold)),
        const SizedBox(height: 6),
        Table(columnWidths: const {
          0: FlexColumnWidth(1.3)
        }, children: [
          TableRow(children: [
            const SizedBox(),
            for (final t in ['Base', 'I', 'II', 'III'])
              Text(t, style: _sys(context, color: ink.ash)),
          ]),
          for (final r in rows)
            TableRow(children: [
              Text(
                  r.key == 'heal_amount'
                      ? 'Heal'
                      : r.key.startsWith('damage_mult')
                          ? 'Multiplier'
                          : 'Damage',
                  style: _body(context)),
              for (final v in r.values)
                Text(v, style: _sys(context, size: 12, color: _apCream)),
            ]),
        ]),
      ]),
    ),
    const SizedBox(height: 10),
    FilledButton(onPressed: () {}, child: const Text('Ask the Cinder Compact')),
  ]);
}

Widget aOffer(BuildContext context, {int? hover, int? picked}) {
  final offers = _offers();
  Widget card(int i) {
    final o = offers[i];
    final state = picked != null
        ? (picked == i ? CardState.picked : CardState.dim)
        : hover == i
            ? CardState.hover
            : CardState.idle;
    Widget? extra;
    if (o.kind == Kind.merge) {
      extra = Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Plate(o.from!, size: 30),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Text('+', style: TextStyle(color: _apGold, fontSize: 14))),
          Plate(o.partner!, size: 30),
        ]),
        const Icon(Icons.arrow_downward, size: 12, color: _apGold),
        Plate(o.skill, size: 40),
      ]);
    } else if (o.kind == Kind.upgrade) {
      extra = Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Plate(o.skill, size: 54),
        const SizedBox(height: 4),
        Text('I  >  II', style: _sys(context, size: 13, color: _apCore)),
        Text('${o.essence} essence',
            style: _sys(context, size: 10, color: const Color(0xFFA4DDDB))),
      ]);
    }
    return ACard(
      o.skill,
      w: 104,
      h: 232,
      nameSize: 12.5,
      kind: o.kind,
      state: state,
      extra: extra,
    );
  }

  return ListView(padding: const EdgeInsets.all(14), children: [
    pickerHeader(context, hint: picked == null ? 'Choose one' : 'Taken'),
    const SizedBox(height: 16),
    SizedBox(
      height: 252,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [for (var i = 0; i < 3; i++) card(i)]),
    ),
    const SizedBox(height: 14),
    Text(
        picked == null
            ? 'Three offers: a skill from the Cinder Compact, a merge from the Skillwright, a tier for 2,000 essence. One only.'
            : 'Fireball is yours. The other two go back to the table.',
        style: _body(context)),
    const SizedBox(height: 14),
    FilledButton(
        onPressed: picked == null ? null : () {},
        child: Text(picked == null ? 'Take the picked card' : 'Continue')),
  ]);
}

// =============================================================== DIRECTION B
// "Ledger rows": a card is a wide row; the tree is a rail of rows.

class BRow extends StatelessWidget {
  const BRow(this.s,
      {super.key,
      this.state = CardState.idle,
      this.kind,
      this.expanded = false,
      this.offer,
      this.railTop = false,
      this.railBottom = false,
      this.rail = false});
  final Sk s;
  final CardState state;
  final Kind? kind;
  final bool expanded;
  final Offer? offer;
  final bool rail, railTop, railBottom;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final rar = _rarity(s.rarity);
    final picked = state == CardState.picked;
    final hover = state == CardState.hover;
    final locked = s.st == St.locked;
    final frame = picked ? _apCore : (hover ? _apGold : ink.seam);
    final body = AnimatedContainer(
      duration: Duration.zero,
      margin: EdgeInsets.only(left: hover ? 6 : 0),
      padding: const EdgeInsets.all(8),
      decoration: ShapeDecoration(
        color: picked
            ? Color.lerp(_apNavy, _apCore, 0.12)
            : Theme.of(context).colorScheme.surfaceContainerLow,
        shape: PixelChipBorder(
            side: BorderSide(color: frame, width: picked ? 2.5 : 1.5),
            step: 2,
            steps: 2),
        shadows: [
          if (hover || picked)
            BoxShadow(color: frame.withValues(alpha: 0.35), blurRadius: 10),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Plate(s, size: 52, dim: locked),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (kind != null) ...[
                  Tag(
                      switch (kind!) {
                        Kind.learn => 'LEARN',
                        Kind.merge => 'MERGE',
                        Kind.upgrade => 'RAISE',
                      },
                      picked ? _apCore : rar,
                      fill: true),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _name(context, size: 16)),
                ),
              ]),
              const SizedBox(height: 3),
              Text(s.effect().isEmpty ? s.desc : s.effect(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      _body(context, size: 12, color: locked ? ink.ash : null)),
              const SizedBox(height: 4),
              Row(children: [
                if (s.element != 'None') ...[
                  Tag(s.element, _element(s.element), dot: true),
                  const SizedBox(width: 4),
                ],
                Tag(_cap(s.rarity), rar),
              ]),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            locked
                ? Icon(Icons.lock_outline, size: 16, color: ink.ash)
                : Cost(s.cost),
            const SizedBox(height: 6),
            Pips(s.tier,
                size: 6, show: s.st == St.known || kind == Kind.upgrade),
          ]),
        ]),
        if (expanded && offer != null) ...[
          const SizedBox(height: 8),
          Divider(height: 1, color: ink.seam),
          const SizedBox(height: 8),
          if (offer!.kind == Kind.merge)
            Row(children: [
              Plate(offer!.from!, size: 28),
              Text('  ${offer!.from!.name}  +  ',
                  style: _body(context, size: 11)),
              Plate(offer!.partner!, size: 28),
              Text('  ${offer!.partner!.name}',
                  style: _body(context, size: 11)),
            ])
          else if (offer!.kind == Kind.upgrade)
            Text(
                'Tier I to II: ${s.effect(1)}  to  ${s.effect(2)}\n${offer!.essence} essence',
                style: _body(context, size: 12))
          else
            Text('${s.desc}\nOffered by ${offer!.clan}.',
                style: _body(context, size: 12)),
        ],
      ]),
    );
    if (!rail) return body;
    return IntrinsicHeight(
      child: Row(children: [
        SizedBox(
          width: 22,
          child: CustomPaint(
              painter: _RailPainter(ink.seam, railTop, railBottom,
                  s.st == St.known ? _apGold : ink.seam)),
        ),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3), child: body)),
      ]),
    );
  }
}

class _RailPainter extends CustomPainter {
  _RailPainter(this.line, this.top, this.bottom, this.node);
  final Color line, node;
  final bool top, bottom;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xFF577277)
      ..strokeWidth = 2;
    final x = s.width / 2;
    c.drawLine(Offset(x, top ? 0 : s.height / 2),
        Offset(x, bottom ? s.height : s.height / 2), p);
    final r =
        Rect.fromCenter(center: Offset(x, s.height / 2), width: 10, height: 10);
    c.drawRect(r, Paint()..color = _apNight);
    c.drawRect(
        r,
        Paint()
          ..color = node
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    if (node == _apGold) c.drawRect(r.deflate(3), Paint()..color = _apCore);
  }

  @override
  bool shouldRepaint(_) => true;
}

Widget bList(BuildContext context) {
  final ink = InkColors.of(context);
  final branches = _mageBranches();
  return ListView(padding: const EdgeInsets.fromLTRB(12, 6, 12, 20), children: [
    for (final b in branches.take(2)) ...[
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: Row(children: [
          Text(b.name.toUpperCase(),
              style: _sys(context, size: 12, color: ink.gold)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(b.blurb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _body(context, size: 11))),
        ]),
      ),
      for (var i = 0; i < b.skills.length; i++)
        BRow(b.skills[i],
            rail: true, railTop: i > 0, railBottom: i < b.skills.length - 1),
    ],
  ]);
}

Widget bDetail(BuildContext context) {
  final s = sk('fireball', St.ready);
  final ink = InkColors.of(context);
  return ListView(padding: const EdgeInsets.all(12), children: [
    BRow(s),
    const SizedBox(height: 10),
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border.all(color: ink.seam),
          color: Theme.of(context).colorScheme.surfaceContainerLow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.desc, style: _body(context, size: 14)),
        const SizedBox(height: 10),
        Text('BY TIER', style: _sys(context, color: ink.gold)),
        const SizedBox(height: 6),
        for (final r in s.table())
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              SizedBox(
                  width: 78,
                  child: Text(
                      r.key == 'heal_amount'
                          ? 'Heal'
                          : r.key.startsWith('damage_mult')
                              ? 'Multiplier'
                              : 'Damage',
                      style: _body(context))),
              for (var t = 0; t < r.values.length; t++)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: t == 0 ? _apNavy : _apInk.withValues(alpha: 0.6),
                    alignment: Alignment.center,
                    child: Text(r.values[t],
                        style: _sys(context, size: 12, color: _apCream)),
                  ),
                ),
            ]),
          ),
        const SizedBox(height: 10),
        Text('Offered by the Cinder Compact, from Known. Fights on Fire dice.',
            style: _body(context, size: 12)),
      ]),
    ),
    const SizedBox(height: 10),
    FilledButton(onPressed: () {}, child: const Text('Ask the Cinder Compact')),
  ]);
}

Widget bOffer(BuildContext context, {int? hover, int? picked, int open = -1}) {
  final offers = _offers();
  final sel = picked ?? open;
  return ListView(padding: const EdgeInsets.all(14), children: [
    pickerHeader(context, hint: picked == null ? 'Choose one of 3' : 'Taken'),
    const SizedBox(height: 12),
    for (var i = 0; i < 3; i++)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: BRow(
          offers[i].skill,
          kind: offers[i].kind,
          offer: offers[i],
          expanded: sel == i,
          state: picked != null
              ? (picked == i ? CardState.picked : CardState.dim)
              : hover == i
                  ? CardState.hover
                  : CardState.idle,
        ),
      ),
    const SizedBox(height: 6),
    FilledButton(
        onPressed: sel < 0 ? null : () {},
        child: Text(picked != null
            ? 'Continue'
            : sel < 0
                ? 'Pick a card'
                : 'Take ${offers[sel].skill.name}')),
  ]);
}

// =============================================================== DIRECTION C
// "Tiles and one big card": icon-first tiles; the offer is a carousel.

class CTile extends StatelessWidget {
  const CTile(this.s, {super.key, this.size = 104});
  final Sk s;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final rar = _rarity(s.rarity);
    final locked = s.st == St.locked;
    final known = s.st == St.known;
    return Container(
      width: size,
      decoration: ShapeDecoration(
        color: _apNight,
        shape: PixelChipBorder(
            side: BorderSide(
                color: known ? _apGold : (locked ? ink.seam : rar), width: 2),
            step: 3,
            steps: 3),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 3),
          child: Stack(alignment: Alignment.topCenter, children: [
            Container(
              height: size - 36,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(_apNavy, _element(s.element), 0.35)!,
                      _apNight
                    ]),
              ),
              alignment: Alignment.center,
              child: Opacity(
                  opacity: locked ? 0.4 : 1,
                  child: SkillPixelIcon(s.id, size: size - 52)),
            ),
            Positioned(left: 3, top: 3, child: Cost(s.cost, size: 18)),
            Positioned(
                right: 3,
                top: 4,
                child: locked
                    ? Icon(Icons.lock_outline, size: 13, color: ink.ash)
                    : Pips(s.tier, size: 5, show: known)),
          ]),
        ),
        Container(
          height: 26,
          alignment: Alignment.center,
          color: rar.withValues(alpha: locked ? 0.18 : 0.85),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(s.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: InkFonts.display,
                  fontSize: 12,
                  color: locked ? ink.ash : _apOutline)),
        ),
      ]),
    );
  }
}

Widget cList(BuildContext context) {
  final ink = InkColors.of(context);
  final branches = _mageBranches();
  return ListView(padding: const EdgeInsets.fromLTRB(12, 6, 12, 20), children: [
    Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(children: [
        for (final b in branches)
          Expanded(
              child: Text(b.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: _sys(context, size: 11, color: ink.gold))),
      ]),
    ),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final b in branches)
        Expanded(
          child: Column(children: [
            for (var i = 0; i < b.skills.length; i++) ...[
              if (i > 0) Container(width: 2, height: 10, color: ink.seam),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: CTile(b.skills[i], size: 100),
              ),
            ],
          ]),
        ),
    ]),
  ]);
}

Widget cDetail(BuildContext context) {
  final s = sk('fireball', St.ready);
  final ink = InkColors.of(context);
  final tint = _element(s.element);
  return ListView(padding: EdgeInsets.zero, children: [
    Container(
      height: 210,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(_apNavy, tint, 0.55)!,
              Color.lerp(_apNight, tint, 0.1)!
            ]),
      ),
      child: Stack(alignment: Alignment.center, children: [
        SkillPixelIcon(s.id, size: 150),
        Positioned(left: 14, top: 12, child: Cost(s.cost, size: 30)),
        Positioned(
            right: 14,
            top: 14,
            child: Tag(_cap(s.rarity), _rarity(s.rarity), fill: true)),
      ]),
    ),
    Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(s.name, style: _name(context, size: 24))),
          Tag(s.element, tint, dot: true),
        ]),
        const SizedBox(height: 6),
        Text(s.desc, style: _body(context, size: 14)),
        const SizedBox(height: 12),
        Row(children: [
          for (final r in s.table())
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: ShapeDecoration(
                    color: _apInk.withValues(alpha: 0.6),
                    shape: PixelChipBorder(
                        side: BorderSide(color: ink.seam), step: 2, steps: 2)),
                child: Column(children: [
                  Text(r.values.first,
                      style: _sys(context, size: 16, color: _apCream)),
                  const SizedBox(height: 2),
                  Text(
                      r.key == 'heal_amount'
                          ? 'Heal'
                          : r.key.startsWith('damage_mult')
                              ? 'Multiplier'
                              : 'Damage',
                      style: _sys(context, size: 10, color: ink.ash)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Text('TIERS', style: _sys(context, color: ink.gold)),
        const SizedBox(height: 6),
        Row(children: [
          for (var t = 0; t <= 3; t++)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: t == 0 ? _apNavy : _apInk.withValues(alpha: 0.5),
                alignment: Alignment.center,
                child: Column(children: [
                  Text(t == 0 ? 'Base' : ['', 'I', 'II', 'III'][t],
                      style: _sys(context, size: 10, color: ink.ash)),
                  Text(s.effect(t),
                      style: _sys(context, size: 10, color: _apCream)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        FilledButton(
            onPressed: () {}, child: const Text('Ask the Cinder Compact')),
      ]),
    ),
  ]);
}

Widget cBig(BuildContext context, Offer o,
    {required double w, required double h, CardState state = CardState.idle}) {
  final s = o.skill;
  final rar = _rarity(s.rarity);
  final picked = state == CardState.picked;
  final frame = picked ? _apCore : rar;
  final tint = _element(s.element);
  Widget art;
  if (o.kind == Kind.merge) {
    art = Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Plate(o.from!, size: 50),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('+', style: TextStyle(color: _apGold, fontSize: 22))),
        Plate(o.partner!, size: 50),
      ]),
      const Icon(Icons.arrow_downward, size: 18, color: _apGold),
      SkillPixelIcon(s.id, size: 88),
    ]);
  } else {
    art = SkillPixelIcon(s.id, size: 112);
  }
  return Transform.translate(
    offset: Offset(0, state == CardState.hover ? -6 : 0),
    child: Opacity(
      opacity: state == CardState.dim ? 0.2 : 1,
      child: Container(
        width: w,
        height: h,
        decoration: ShapeDecoration(
          color: _apNight,
          shape: PixelChipBorder(
              side: BorderSide(color: frame, width: picked ? 3.5 : 2.5),
              step: 4,
              steps: 3),
          shadows: [
            if (state == CardState.hover || picked)
              BoxShadow(color: frame.withValues(alpha: 0.5), blurRadius: 16),
          ],
        ),
        child: Column(children: [
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.all(6),
              width: double.infinity,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.lerp(_apNavy, tint, 0.45)!, _apNight])),
              child: Stack(alignment: Alignment.center, children: [
                art,
                Positioned(
                    left: 6,
                    top: 6,
                    child: Tag(
                        switch (o.kind) {
                          Kind.learn => 'LEARN',
                          Kind.merge => 'MERGE',
                          Kind.upgrade => 'RAISE I TO II',
                        },
                        frame,
                        fill: true)),
                Positioned(right: 6, top: 6, child: Cost(s.cost, size: 24)),
              ]),
            ),
          ),
          Container(
            width: double.infinity,
            color: rar.withValues(alpha: 0.9),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(s.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: InkFonts.display,
                    fontSize: 18,
                    color: _apOutline)),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Column(children: [
                Text(
                    o.kind == Kind.upgrade
                        ? '${s.effect(1)}  to  ${s.effect(2)}'
                        : (s.effect().isEmpty ? s.desc : s.effect()),
                    textAlign: TextAlign.center,
                    style: _sys(context, size: 12, color: _apCream)),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                      o.kind == Kind.upgrade
                          ? '${o.essence} essence'
                          : o.kind == Kind.merge
                              ? 'Both skills are spent.'
                              : '${s.desc}  Offered by ${o.clan}.',
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: _body(context, size: 11)),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (s.element != 'None') Tag(s.element, tint, dot: true),
                  const SizedBox(width: 4),
                  Tag(_cap(s.rarity), rar),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    ),
  );
}

Widget cOffer(BuildContext context,
    {int focus = 0, int? picked, bool pressing = false}) {
  final offers = _offers();
  final ink = InkColors.of(context);
  return ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(14),
    children: [
      pickerHeader(context,
          hint: picked == null ? 'Swipe · choose one' : 'Taken'),
      const SizedBox(height: 14),
      SizedBox(
        height: 372,
        child: Stack(alignment: Alignment.center, children: [
          // The peeking neighbours, then the focused card on top.
          for (final i
              in [for (var k = 0; k < 3; k++) k].where((k) => k != focus))
            Positioned(
              left: i < focus ? -150 : null,
              right: i > focus ? -150 : null,
              child: Transform.scale(
                scale: 0.88,
                child: cBig(context, offers[i],
                    w: 230,
                    h: 340,
                    state: picked != null ? CardState.dim : CardState.idle),
              ),
            ),
          cBig(context, offers[focus],
              w: 250,
              h: 360,
              state: picked == focus
                  ? CardState.picked
                  : pressing
                      ? CardState.hover
                      : CardState.idle),
        ]),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: i == focus ? 16 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            color: i == focus ? _apCore : ink.seam,
          ),
      ]),
      const SizedBox(height: 12),
      FilledButton(
          onPressed: () {},
          child: Text(picked != null
              ? 'Continue'
              : 'Take ${offers[focus].skill.name}')),
    ],
  );
}

// ------------------------------------------------------------------ test ---
void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final dir = Platform.environment['UX_DIR'] ?? 'a';

  testWidgets('skill card directions', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    _skills = jsonDecode(File('assets/gamedata/skills.json').readAsStringSync())
        as Map<String, dynamic>;
    _trees =
        jsonDecode(File('assets/gamedata/skill_trees.json').readAsStringSync())
            as Map<String, dynamic>;
    Directory(shots!).createSync(recursive: true);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);
    addTearDown(tester.view.reset);
    final key = GlobalKey();

    Future<void> shot(String name, Widget Function(BuildContext) build,
        {String title = 'Skills', String? sub, bool dark = true}) async {
      final scheme = AppPalette.stitchedInk
          .schemeFor(dark ? Brightness.dark : Brightness.light);
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(scheme),
          home: Builder(
              builder: (c) => Phone(title: title, sub: sub, child: build(c))),
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
        final image = await b.toImage(pixelRatio: 2);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
      });
      File('$shots/$dir-$name.png').writeAsBytesSync(bytes);
    }

    const essence = '2,350 essence';
    switch (dir) {
      case 'a':
        final aFrames = <({int? hover, int? picked})>[
          (hover: null, picked: null),
          (hover: 0, picked: null),
          (hover: 1, picked: null),
          (hover: 0, picked: null),
          (hover: null, picked: 0),
          (hover: null, picked: 0),
        ];
        for (final (i, f) in aFrames.indexed) {
          await shot('f$i', (c) => aOffer(c, hover: f.hover, picked: f.picked),
              title: 'Level up');
        }
        await shot('1-tree', aList, sub: essence);
        await shot('2-detail', aDetail, title: 'Fireball');
        await shot('3-offer', (c) => aOffer(c, hover: 0), title: 'Level up');
        await shot('4-picked', (c) => aOffer(c, picked: 0), title: 'Level up');
      case 'b':
        final bFrames = <({int? hover, int? picked, int open})>[
          (hover: null, picked: null, open: -1),
          (hover: 0, picked: null, open: -1),
          (hover: null, picked: null, open: 0),
          (hover: 1, picked: null, open: 0),
          (hover: null, picked: null, open: 0),
          (hover: null, picked: 0, open: 0),
          (hover: null, picked: 0, open: 0),
        ];
        for (final (i, f) in bFrames.indexed) {
          await shot('f$i',
              (c) => bOffer(c, hover: f.hover, picked: f.picked, open: f.open),
              title: 'Level up');
        }
        await shot('1-tree', bList, sub: essence);
        await shot('2-detail', bDetail, title: 'Fireball');
        await shot('3-offer', (c) => bOffer(c, hover: 1, open: 0),
            title: 'Level up');
        await shot('4-picked', (c) => bOffer(c, picked: 0), title: 'Level up');
      case 'c':
        final cFrames = <({int focus, bool press, int? picked})>[
          (focus: 0, press: false, picked: null),
          (focus: 1, press: false, picked: null),
          (focus: 2, press: false, picked: null),
          (focus: 0, press: false, picked: null),
          (focus: 0, press: true, picked: null),
          (focus: 0, press: false, picked: 0),
          (focus: 0, press: false, picked: 0),
        ];
        for (final (i, f) in cFrames.indexed) {
          await shot('f$i',
              (c) => cOffer(c, focus: f.focus, pressing: f.press, picked: f.picked),
              title: 'Level up');
        }
        await shot('1-tree', cList, sub: essence);
        await shot('2-detail', cDetail, title: 'Fireball');
        await shot('3-offer', (c) => cOffer(c, pressing: true),
            title: 'Level up');
        await shot('4-picked', (c) => cOffer(c, picked: 0), title: 'Level up');
    }
  });
}
