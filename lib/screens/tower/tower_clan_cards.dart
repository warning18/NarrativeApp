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
import 'ink/ink_palette.dart';
import 'tower_tarot_card.dart' show TowerSeal;

const double towerClanCardWidth = 210;
const double towerClanCardHeight = 346;

/// The text colour on a band of [colour]: ink on a light one, paper on a dark.
Color towerOnBand(Color colour) =>
    colour.computeLuminance() > 0.3 ? inkOnPaper : inkPaper;

/// The Ashen Ink card corner (docs: radius-card 12) and its plate (6).
const double towerCardRadius = 12;
const double towerPlateRadius = 6;

/// A tag on paper: ink words in a one-pixel ink line (the dark chip's twin).
class _PaperTag extends StatelessWidget {
  const _PaperTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
            border: Border.all(color: inkOnPaper, width: 1),
            borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            maxLines: 1,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: inkOnPaper, fontWeight: FontWeight.w700)),
      );
}

/// One gift of a clan, as a card (fanned by `ClanHandFan`). Design A, rounder
/// (the user, 25 Nov): paper, the gift on a black plate, the name in small
/// caps, the clan's hue once (a short line under the name), the wax seal, and
/// all the information on the card: tags, standing, what it moves, the quote.
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
    this.ripple = '',
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

  /// What the gift moves, clan by clan ("Mire +2 · Dominion -1").
  final String ripple;
  final String? backdropId;
  final String? standing;

  /// 0 to 4, the seal's pips; null draws none.
  final int? rarity;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    const prose = TextStyle(
        fontFamily: InkFonts.prose,
        fontSize: 11.5,
        height: 1.2,
        color: inkOnPaper);
    return Container(
      width: towerClanCardWidth,
      height: towerClanCardHeight,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(towerCardRadius + 4),
          border: Border.all(
              color: lit ? inkPaper : const Color(0x00000000), width: 2)),
      child: DecoratedBox(
        decoration: BoxDecoration(
            color: inkPaper,
            borderRadius: BorderRadius.circular(towerCardRadius),
            border: Border.all(color: inkBlack, width: 2)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(children: [
            Stack(alignment: Alignment.center, children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                    color: inkBlack,
                    borderRadius: BorderRadius.circular(towerPlateRadius)),
                alignment: Alignment.center,
                child: SizedBox(
                    width: 72,
                    height: 72,
                    child: FittedBox(fit: BoxFit.contain, child: icon)),
              ),
              if (rarity != null)
                Align(
                    alignment: Alignment.topRight,
                    child: TowerSeal(rarity: rarity, size: 24)),
            ]),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(name.toUpperCase(),
                  maxLines: 1,
                  style: const TextStyle(
                      fontFamily: InkFonts.display,
                      fontSize: 17,
                      height: 1.05,
                      color: inkOnPaper)),
            ),
            const SizedBox(height: 4),
            // The clan's hue, once.
            Container(
                width: 44,
                height: 3,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < tags.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  tags[i],
                ],
              ]),
            ),
            const SizedBox(height: 4),
            Text([clanName, if (standing != null) standing!].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: prose.copyWith(
                    fontSize: 12.5, fontWeight: FontWeight.w700)),
            if (ripple.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(ripple,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: prose.copyWith(
                      color: inkOnPaper.withValues(alpha: 0.75))),
            ],
            const Spacer(),
            Container(height: 1, color: inkOnPaper.withValues(alpha: 0.25)),
            const SizedBox(height: 5),
            Text(greeting.isEmpty ? '' : '“$greeting”',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: prose.copyWith(fontStyle: FontStyle.italic)),
          ]),
        ),
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
    // The same spirit as the cards: paper, the clan's banner on a black
    // plate, the name in ink, the late-oath line or motto in italic.
    const ink = TextStyle(
        fontFamily: InkFonts.prose,
        fontSize: 12,
        height: 1.25,
        color: inkOnPaper);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(towerCardRadius + 4),
            border: Border.all(
                color: selected ? inkPaper : const Color(0x00000000),
                width: 2)),
        child: DecoratedBox(
          decoration: BoxDecoration(
              color: inkPaper,
              borderRadius: BorderRadius.circular(towerCardRadius),
              border: Border.all(color: inkBlack, width: 2)),
          child: IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                width: 64,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: inkBlack,
                    borderRadius: BorderRadius.circular(towerPlateRadius)),
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                child: SizedBox(
                    height: 88,
                    child: FittedBox(fit: BoxFit.contain, child: flag)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: InkFonts.display,
                                fontSize: 15,
                                height: 1.05,
                                color: inkOnPaper)),
                        const SizedBox(height: 4),
                        Wrap(spacing: 4, runSpacing: 2, children: tags),
                        const SizedBox(height: 4),
                        Text(text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ink),
                        if (standing != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(standing!,
                                style:
                                    ink.copyWith(fontWeight: FontWeight.w700)),
                          ),
                        if (greeting.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('“$greeting”',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: ink.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: inkOnPaper.withValues(alpha: 0.8))),
                          ),
                      ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// A gift's or an oath's small tag: paper text in a paper line (the ink look).
Widget towerClanTag(String text) => _PaperTag(text);
