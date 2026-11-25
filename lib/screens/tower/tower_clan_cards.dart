// The Tower's clan offer cards in the ink look (the user: "update the card
// design and look to match the ink design", then "too colourful: ink and paper
// only, the clan colour as one small spot"): the story's banner card laid out
// the same way (the clan's banner at the left, the gift's plate at the right,
// the name on a band, the tags, the standing, the clan's quote), drawn as the
// Tower draws: a black body, a hard paper line, an ink plate for the picture
// and the rarity as the tarot cards' wax seal. The clan's colour is one thin
// line under the name, and the banner's own. They are drawn at the story
// card's own 210 x 346 so the story's hand (clan_offer_gifts.dart,
// ClanHandFan) fans them.
import 'package:flutter/material.dart';

import '../../theme/stitched_ink.dart';
import 'ink/ink_kit.dart';
import 'ink/ink_palette.dart';
import 'tower_tarot_card.dart' show TowerSeal;

const double towerClanCardWidth = 210;
const double towerClanCardHeight = 346;

/// The text colour on a band of [colour]: ink on a light one, paper on a dark.
Color towerOnBand(Color colour) =>
    colour.computeLuminance() > 0.3 ? inkOnPaper : inkPaper;

/// One gift of a clan, as a card (fanned by `ClanHandFan`).
class TowerClanCard extends StatelessWidget {
  const TowerClanCard({
    super.key,
    required this.color,
    required this.flag,
    required this.icon,
    required this.name,
    required this.tags,
    required this.greeting,
    required this.clanName,
    this.backdropId,
    this.standing,
    this.rarity,
    this.lit = false,
  });

  final Color color;
  final Widget flag;
  final Widget icon;
  final String name;
  final List<Widget> tags;
  final String greeting;
  final String clanName;
  final String? backdropId;
  final String? standing;

  /// 0 to 4, the seal's pips; null draws none.
  final int? rarity;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: towerClanCardWidth,
      height: towerClanCardHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: inkBlack,
          border: Border.all(
              color: lit ? inkPaper : inkPaper.withValues(alpha: 0.45),
              width: lit ? 3 : 2),
          boxShadow: [
            BoxShadow(
                color: lit ? inkPaper : const Color(0xFF000000),
                offset: const Offset(4, 4)),
          ],
        ),
        child: Stack(children: [
          // The art zone: plain ink, the banner and the plate on it.
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 150,
            child: ColoredBox(color: inkDeep),
          ),
          Positioned(
              left: 14,
              top: 12,
              width: 64,
              height: 128,
              child: FittedBox(fit: BoxFit.contain, child: flag)),
          Positioned(
            right: 14,
            top: 38,
            width: 78,
            height: 78,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: inkBlack.withValues(alpha: 0.85),
                  border: Border.all(color: inkPaper, width: 1.5)),
              child: icon,
            ),
          ),
          if (rarity != null)
            Positioned(
                right: 8,
                bottom: 196,
                child: TowerSeal(rarity: rarity, size: 26)),
          // The name on its band, in the clan's colour.
          Positioned(
            left: 0,
            right: 0,
            top: 150,
            height: 34,
            child: Container(
              color: inkPaper,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(name,
                    maxLines: 1,
                    style: const TextStyle(
                        fontFamily: InkFonts.display,
                        fontSize: 19,
                        height: 1,
                        color: inkOnPaper)),
              ),
            ),
          ),
          // The clan's colour: one thin line under the name.
          Positioned(
              left: 0,
              right: 0,
              top: 184,
              height: 4,
              child: ColoredBox(color: color)),
          Positioned(
            left: 14,
            right: 14,
            top: 192,
            bottom: 14,
            child: Column(children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var i = 0; i < tags.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    tags[i],
                  ],
                ]),
              ),
              if (standing != null) ...[
                const SizedBox(height: 8),
                Text(standing!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: InkFonts.prose,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.1,
                        color: inkPaper)),
              ],
              const Spacer(),
              Container(height: 1, color: inkPaper.withValues(alpha: 0.3)),
              const SizedBox(height: 6),
              Text(greeting.isEmpty ? '' : '“$greeting”',
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: InkFonts.prose,
                      fontStyle: FontStyle.italic,
                      fontSize: 11.5,
                      height: 1.25,
                      color: inkPaper)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// A clan's oath, as a wide row under the hand.
class TowerClanOathRow extends StatelessWidget {
  const TowerClanOathRow({
    super.key,
    required this.color,
    required this.flag,
    required this.icon,
    required this.name,
    required this.tags,
    required this.text,
    required this.greeting,
    required this.clanName,
    required this.selected,
    required this.onTap,
    this.standing,
  });

  final Color color;
  final Widget flag;
  final Widget icon;
  final String name;
  final List<Widget> tags;
  final String text;
  final String greeting;
  final String clanName;
  final String? standing;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: inkBlack,
          border: Border.all(
              color: selected ? inkPaper : inkPaper.withValues(alpha: 0.45),
              width: selected ? 3 : 2),
          boxShadow: [
            BoxShadow(
                color: selected ? inkPaper : const Color(0xFF000000),
                offset: const Offset(3, 3)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // The banner on plain ink, the clan's colour one thin line beside it.
            Container(
              width: 4,
              color: color,
            ),
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: inkDeep,
              alignment: Alignment.center,
              child: SizedBox(
                  height: 88,
                  child: FittedBox(fit: BoxFit.contain, child: flag)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: inkDeep,
                                  border:
                                      Border.all(color: inkPaper, width: 1.2)),
                              child: FittedBox(child: icon),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontFamily: InkFonts.display,
                                            fontSize: 15,
                                            height: 1.05,
                                            color: inkPaper)),
                                    const SizedBox(height: 3),
                                    Wrap(
                                        spacing: 4,
                                        runSpacing: 2,
                                        children: tags),
                                  ]),
                            ),
                          ]),
                      const SizedBox(height: 6),
                      Text(text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: InkFonts.prose,
                              fontSize: 12,
                              height: 1.25,
                              color: inkPaper)),
                      if (standing != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(standing!,
                              style: const TextStyle(
                                  fontFamily: InkFonts.prose,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: inkPaper)),
                        ),
                      if (greeting.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('“$greeting”',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: InkFonts.prose,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 11.5,
                                  height: 1.25,
                                  color: inkPaper.withValues(alpha: 0.8))),
                        ),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// A gift's or an oath's small tag: paper text in a paper line (the ink look).
Widget towerClanTag(String text) => InkTag(text);
