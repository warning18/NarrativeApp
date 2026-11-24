// The floor's two picture bands in ink (v1.1005, the approved floor): the
// foes standing on the floor's plate and the hero on his own, each in a
// slanted panel (the slant belongs to the picture only), a skewed black
// nameplate on every figure. The plates are the recoloured ones; the figures
// are the sprites in ink.
import 'package:flutter/material.dart';

import '../../../widgets/fight_sprites.dart';
import 'ink_figure.dart';
import 'ink_kit.dart';
import 'ink_palette.dart';

/// A skewed black nameplate: [child] on it, a paper bar on its left (red when
/// [lit]).
class InkNamePlate extends StatelessWidget {
  const InkNamePlate({super.key, required this.child, this.lit = false});

  final Widget child;
  final bool lit;

  @override
  Widget build(BuildContext context) => Transform(
        transform: Matrix4.skewX(-inkSkew),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 3, 8, 4),
          decoration: BoxDecoration(
            color: inkBlack,
            border: Border(
                left: BorderSide(color: lit ? inkRed : inkPaper, width: 3),
                bottom: BorderSide(color: lit ? inkRed : inkSlate)),
          ),
          child: Transform(
              transform: Matrix4.skewX(inkSkew),
              child: DefaultTextStyle.merge(
                  style: const TextStyle(color: inkPaper), child: child)),
        ),
      );
}

/// What a band shows for one foe.
class InkBandFoe {
  const InkBandFoe(this.id, this.name);

  final String id;
  final String name;
}

/// The slanted picture: [plate] cover-fitted, slanted top and bottom edges.
class _Band extends StatelessWidget {
  const _Band({
    super.key,
    required this.plate,
    required this.height,
    required this.slantTop,
    required this.slantBottom,
    required this.builder,
  });

  final String plate;
  final double height;
  final double slantTop, slantBottom;
  final Widget Function(double width) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        return InkSlantPanel(
          size: Size(w, height),
          points: [
            Offset(6, slantTop),
            Offset(w - 6, 6),
            Offset(w - 6, height - 6 - slantBottom),
            Offset(6, height - 6),
          ],
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(plate,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.none,
                errorBuilder: (c, e, s) => const ColoredBox(color: inkDeep)),
            builder(w),
          ]),
        );
      });
}

/// The foes standing in a row on [plate], each under its nameplate.
class InkFoeBand extends StatelessWidget {
  const InkFoeBand({
    super.key,
    required this.plate,
    required this.foes,
    this.lit = false,
  });

  final String plate;
  final List<InkBandFoe> foes;
  final bool lit;

  @override
  Widget build(BuildContext context) => _Band(
        plate: plate,
        height: 150,
        slantTop: 12,
        slantBottom: 0,
        builder: (w) {
          final n = foes.length.clamp(1, 3);
          final cell = (w - 24) / n;
          return Stack(children: [
            for (var i = 0; i < foes.length && i < 3; i++) ...[
              Positioned(
                left: 12 + i * cell,
                bottom: 8,
                width: cell,
                child: Center(
                  child: Builder(builder: (context) {
                    final set = enemyFightSprite(foes[i].id);
                    return KeyedSubtree(
                      key: i == 0 ? Key('tower_foe_${foes[i].id}') : null,
                      child: set == null
                          ? const SizedBox(height: 84)
                          : InkFigure(set, size: 84),
                    );
                  }),
                ),
              ),
              Positioned(
                left: 14 + i * cell,
                top: 20,
                width: cell - 8,
                child: InkNamePlate(
                  lit: lit,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(foes[i].name,
                        maxLines: 1,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: inkPaper)),
                  ),
                ),
              ),
            ],
          ]);
        },
      );
}

/// The hero standing on [plate], his health on a nameplate beside him.
class InkHeroBand extends StatelessWidget {
  const InkHeroBand({
    super.key,
    required this.plate,
    required this.sprite,
    required this.health,
    required this.healthText,
    required this.healthKey,
    required this.title,
  });

  final String plate;
  final FightSpriteSet sprite;
  final double health;
  final String healthText;
  final Key healthKey;
  final String title;

  @override
  Widget build(BuildContext context) => _Band(
        key: const Key('tower_hero_figure'),
        plate: plate,
        height: 118,
        slantTop: 0,
        slantBottom: 12,
        builder: (w) => Stack(children: [
          Positioned(left: 14, bottom: 8, child: InkFigure(sprite, size: 84)),
          Positioned(
            left: 108,
            right: 18,
            top: 30,
            child: InkNamePlate(
              lit: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: inkGrey, letterSpacing: 1)),
                  const SizedBox(height: 3),
                  InkBar(value: health, height: 6),
                  const SizedBox(height: 3),
                  Text(healthText,
                      key: healthKey,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: inkPaper)),
                ],
              ),
            ),
          ),
        ]),
      );
}
