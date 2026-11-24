// The clan offer's gifts (UX, the user's call "build the clan offer, use tiers
// and add epic and legendary"): what is NEW is a card in a fanned hand, what
// RAISES something the hero already has (an ascension, a perk rank, a
// specialisation's rank II or upgrade) is a row under the hand. The frames are
// Art's PixelLab tiers (assets/visuals/cards/): iron, bronze, silver with a
// blue gem, gilded with purple gems, gold with a crown of rays. The clan's
// colour stays on the name band and the banner.
//
// These widgets only draw. What a card says, which gift is picked and what a
// tap does stay with the offer dialog (offer_dialog.dart).
import 'package:flutter/material.dart';

import '../data/offers.dart';
import '../data/signs.dart' show SignRarity;
import '../combat/dice_faces.dart' show SkillRarity;
import '../combat/spec_variants.dart' show SpecVariantInfo, SpecVariantKind;
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../theme/pixel_chip.dart';
import '../theme/stitched_ink.dart';
import 'pixel_banner.dart';

/// A card's tier: the frame, the plate and the backdrop it wears.
enum CardTier { common, uncommon, rare, epic, legendary }

/// The tier of a skill's own rarity.
CardTier tierOfSkill(SkillRarity r) => switch (r) {
      SkillRarity.common => CardTier.common,
      SkillRarity.uncommon => CardTier.uncommon,
      SkillRarity.rare => CardTier.rare,
      SkillRarity.epic => CardTier.epic,
      SkillRarity.legendary => CardTier.legendary,
    };

/// The tier of any other gift, from the rarity the offer gave it (signs'
/// scale: common, rare, epic, heroic).
CardTier tierOfGiftRarity(SignRarity r) => switch (r) {
      SignRarity.common => CardTier.common,
      SignRarity.rare => CardTier.rare,
      SignRarity.epic => CardTier.epic,
      SignRarity.heroic => CardTier.legendary,
    };

/// Whether [gift] raises something the hero already has (a row under the hand)
/// rather than being new (a card in it): an ascension, a perk rank, a
/// specialisation's rank II or upgrade.
bool giftRaises(
  OfferGift gift, {
  required Map<String, dynamic> skills,
  required Map<String, SpecVariantInfo> specVariants,
}) {
  switch (gift.kind) {
    case GiftKind.perk:
      return true;
    case GiftKind.skill:
      final skill = skills[gift.id];
      return skill is Map &&
          (skill['ascendsSkillID']?.toString() ?? '').isNotEmpty;
    case GiftKind.spec:
      final kind = specVariants[gift.id]?.kind;
      return kind == SpecVariantKind.rank || kind == SpecVariantKind.upgrade;
    case GiftKind.sign:
    case GiftKind.object:
    case GiftKind.title:
    case GiftKind.sworn:
    case GiftKind.die:
      return false;
  }
}

const Color _outline = Palette.apolloOutline;
const Color _night = Color(0xFF10141F);
const Color _navy = Color(0xFF172038);
const Color _cream = Palette.apolloCream;
const Color _gold = Color(0xFFE8C170);
const Color _core = Color(0xFFF2C14E);

String _asset(String piece, CardTier tier) =>
    'assets/visuals/cards/${piece}_${tier.name}.png';

/// The card's size in dp (the frame is 104 x 172 art pixels at 2 dp each).
const double _clanCardWidth = 210;
const double _clanCardHeight = 346;

Widget _art(String path, {double? width, double? height}) => Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );

/// One gift as a card: the tier's backdrop under the clan's banner and the
/// gift's plate, the name band in the clan's colour, the tags, the first
/// standing it moves, the clan's words, the clan's name; the tier's frame over
/// it all. [lit] is the card in hand: its frame glows.
class ClanCardView extends StatelessWidget {
  const ClanCardView({
    super.key,
    required this.tier,
    required this.color,
    required this.flag,
    required this.icon,
    required this.name,
    required this.tags,
    required this.greeting,
    required this.clanName,
    this.effect,
    this.backdropId,
    this.standing,
    this.standingGood = true,
    this.lit = false,
    this.risky = false,
  });

  final CardTier tier;

  /// The clan's colour: the name band and the tint over the backdrop.
  final Color color;

  /// The clan's banner (or a plain flag), drawn at the art's left.
  final Widget flag;

  /// The gift's own picture, on the tier's plate.
  final Widget icon;
  final String name;

  /// The kind tag and the rarity chip, in a row under the band.
  final List<Widget> tags;
  final String greeting;
  final String clanName;
  final String? standing;
  final bool standingGood;
  final bool lit;
  final bool risky;

  /// What the gift does, in one line (a skill's damage or healing, an object's
  /// stats...), gold under the tags.
  final String? effect;

  /// The clan's own backdrop (`assets/visuals/cards/clans/backdrop_<id>.png`,
  /// PixelLab, in the clan's colours with a motif of its banner), in place of
  /// the tier's; null, or a clan without one, keeps the tier's.
  final String? backdropId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glow = lit ? _core : color;
    return SizedBox(
      width: _clanCardWidth,
      height: _clanCardHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: lit ? 0.6 : 0.22),
              blurRadius: lit ? 18 : 8,
            ),
          ],
        ),
        child: Stack(
          children: [
            // The card's body: the tier's backdrop with the clan's tint.
            const Positioned(
              left: 1,
              top: 1,
              right: 1,
              bottom: 1,
              child: ColoredBox(color: _navy),
            ),
            Positioned(
              left: 1,
              top: 1,
              child: _ClanBackdrop(tier: tier, color: color, id: backdropId),
            ),
            Positioned(
              left: 18,
              top: 12,
              width: 64,
              height: 128,
              child: FittedBox(fit: BoxFit.contain, child: flag),
            ),
            Positioned(
              right: 16,
              top: 36,
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _art(_asset('plate', tier), width: 80, height: 80),
                  icon,
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 152,
              height: 30,
              child: Container(
                color: color,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: InkFonts.display,
                      fontSize: 18,
                      height: 1,
                      color: _outline,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              top: 188,
              bottom: 16,
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < tags.length; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          tags[i],
                        ],
                      ],
                    ),
                  ),
                  if (effect != null && effect!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      effect!,
                      key: const Key('offer_card_effect'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: InkFonts.system,
                        fontSize: 12,
                        height: 1.2,
                        color: _gold,
                      ),
                    ),
                  ],
                  if (standing != null) ...[
                    SizedBox(height: effect == null ? 6 : 2),
                    Text(
                      standing!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: InkFonts.system,
                        fontSize: 12,
                        height: 1.2,
                        color: standingGood ? _core : scheme.error,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Container(height: 1, color: color.withValues(alpha: 0.55)),
                  const SizedBox(height: 6),
                  Text(
                    greeting.isEmpty ? '' : '“$greeting”',
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: InkFonts.prose,
                      fontStyle: FontStyle.italic,
                      fontSize: 11.5,
                      height: 1.25,
                      color: _cream,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    clanName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InkFonts.system,
                      fontSize: 9.5,
                      color: Color.lerp(color, _cream, 0.45),
                    ),
                  ),
                ],
              ),
            ),
            // The tier's frame over it all (its centre is transparent).
            Positioned(
              left: 1,
              top: 1,
              child: _art(_asset('frame', tier), width: 208, height: 344),
            ),
          ],
        ),
      ),
    );
  }
}

/// The art zone's backdrop: the clan's own picture when it has one, else the
/// tier's under the clan's tint.
class _ClanBackdrop extends StatelessWidget {
  const _ClanBackdrop({required this.tier, required this.color, this.id});

  final CardTier tier;
  final Color color;
  final String? id;

  @override
  Widget build(BuildContext context) {
    final fallback = Stack(
      children: [
        _art(_asset('backdrop', tier), width: 208, height: 152),
        Container(
          width: 208,
          height: 152,
          color: color.withValues(alpha: 0.18),
        ),
      ],
    );
    if (id == null) return fallback;
    return Image.asset(
      'assets/visuals/cards/clans/backdrop_$id.png',
      width: 208,
      height: 152,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

/// The new gifts as a fanned hand: the cards overlap a little, the [lit] one
/// rises out of the fan and comes in front. A tap on a card is [onTap]'s.
class ClanHandFan extends StatelessWidget {
  const ClanHandFan({
    super.key,
    required this.cards,
    required this.keys,
    required this.lit,
    required this.onTap,
    this.dimOthers = true,
  });

  /// The cards, left to right ([ClanCardView]s drawn at their own size).
  final List<Widget> cards;

  /// One key per card, for taps and for the tests.
  final List<Key> keys;

  /// The index of the card in hand, or -1.
  final int lit;
  final void Function(int index)? onTap;
  final bool dimOthers;

  static const double _rest = 0.66;
  static const double _up = 0.84;

  /// The hand's height: a card in hand, lifted; at rest the hand takes only
  /// what the three resting cards need (and grows, with a short ease, when
  /// one is touched), so no empty band sits above it.
  static double get liftedHeight => _clanCardHeight * _up + 42;
  static double get restHeight => _clanCardHeight * _rest + 22;

  @override
  Widget build(BuildContext context) {
    final n = cards.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth;
          const restW = _clanCardWidth * _rest;
          const upW = _clanCardWidth * _up;
          final step =
              n <= 1 ? 0.0 : ((width - restW) / (n - 1)).clamp(0.0, 104.0);
          final total = restW + step * (n - 1);
          final left0 = (width - total) / 2;
          Widget one(int i) {
            final isUp = lit == i;
            final k = isUp ? _up : _rest;
            final centre = (n - 1) / 2;
            final angle = (i - centre) * 0.11 * (isUp ? 0.25 : 1);
            final dim = dimOthers && lit >= 0 && !isUp;
            final left = (left0 + step * i - (isUp ? (upW - restW) / 2 : 0))
                .clamp(0.0, width - upW);
            return AnimatedPositioned(
              key: ValueKey('hand_slot_$i'),
              duration: Motion.fast,
              curve: Curves.easeOut,
              left: left,
              bottom: isUp ? 24 : 0,
              child: GestureDetector(
                key: keys[i],
                behavior: HitTestBehavior.opaque,
                onTap: onTap == null ? null : () => onTap!(i),
                child: AnimatedOpacity(
                  duration: Motion.fast,
                  opacity: dim ? 0.72 : 1,
                  child: Transform.rotate(
                    angle: angle,
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: _clanCardWidth * k,
                      height: _clanCardHeight * k,
                      child: FittedBox(child: cards[i]),
                    ),
                  ),
                ),
              ),
            );
          }

          final order = [
            for (var i = 0; i < n; i++)
              if (i != lit) i,
            if (lit >= 0 && lit < n) lit,
          ];
          return AnimatedContainer(
            duration: Motion.fast,
            curve: Curves.easeOut,
            height: lit >= 0 ? liftedHeight : restHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [for (final i in order) one(i)],
            ),
          );
        },
      ),
    );
  }
}

/// One gift that raises something the hero has, as a row: the clan's banner at
/// the left, the gift's plate, its name, its tags, what it raises, the clan's
/// words (in full once picked). A tap picks it.
class ClanRaiseRow extends StatelessWidget {
  const ClanRaiseRow({
    super.key,
    required this.tier,
    required this.color,
    required this.flag,
    required this.icon,
    required this.name,
    required this.tags,
    required this.raises,
    required this.greeting,
    required this.clanName,
    required this.selected,
    required this.onTap,
    this.standing,
    this.standingGood = true,
  });

  final CardTier tier;
  final Color color;
  final Widget flag;
  final Widget icon;
  final String name;
  final List<Widget> tags;

  /// What it raises: "Raises Inner Fire to its ascended form."
  final String raises;
  final String greeting;
  final String clanName;
  final String? standing;
  final bool standingGood;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final frame = selected ? _core : color;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: selected ? Color.lerp(_navy, _core, 0.1) : _navy,
          shape: PixelChipBorder(
            side: BorderSide(color: frame, width: selected ? 2.5 : 1.5),
            step: 2,
            steps: 2,
          ),
          shadows: [
            if (selected)
              BoxShadow(color: _core.withValues(alpha: 0.4), blurRadius: 10),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(_night, color, 0.55)!,
                      Color.lerp(_night, color, 0.12)!,
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: SizedBox(
                  height: 84,
                  child: FittedBox(fit: BoxFit.contain, child: flag),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _art(
                                  _asset('plate', tier),
                                  width: 44,
                                  height: 44,
                                ),
                                FittedBox(child: icon),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: InkFonts.display,
                                    fontSize: 16,
                                    height: 1.1,
                                    color: _cream,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Wrap(spacing: 4, runSpacing: 3, children: tags),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        raises,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: InkFonts.system,
                          fontSize: 11,
                          height: 1.2,
                          color: _gold,
                        ),
                      ),
                      if (standing != null)
                        Text(
                          standing!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: InkFonts.system,
                            fontSize: 11,
                            height: 1.2,
                            color: standingGood ? _core : scheme.error,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${clanName.toUpperCase()}  ·  “$greeting”',
                        maxLines: selected ? 4 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: InkFonts.prose,
                          fontSize: 11,
                          height: 1.25,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The clan's own banner for a card or a row: its pixel banner, or [plain]
/// (the Wayfarer's pennant) when it has none.
Widget clanCardFlag(String? bannerId, {required Widget plain}) =>
    bannerId == null
        ? plain
        : SizedBox(
            width: pixelBannerSize.width,
            height: pixelBannerSize.height,
            child: PixelBanner(id: bannerId, scale: 1),
          );
