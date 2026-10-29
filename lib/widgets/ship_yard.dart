// The shipwright's yard (v1.226): the Eel from above on a patch of sea, as
// she would look with what is tried on her, and the shelf of looks (paint,
// cloth, figurehead, flag) to try. See harbor_screen.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/ship_battle.dart';
import '../combat/ship_combat.dart';
import '../data/ship_forms.dart';
import '../data/ship_looks.dart';
import '../l10n/app_strings.dart';
import '../theme/stitched_ink.dart';
import 'sea_battlefield.dart';
import 'ship_dress.dart';
import 'side_view/sea_kit.dart' show SeaSideScene;

/// How a rarity is told apart on a card: common grey to legendary amber.
Color rarityColor(String rarity) => switch (rarity) {
      'uncommon' => const Color(0xFF66BB6A),
      'rare' => const Color(0xFF4FC3F7),
      'epic' => const Color(0xFFB388FF),
      'legendary' => const Color(0xFFFFB74D),
      _ => const Color(0xFF9AA0A6),
    };

/// A version number as a Roman numeral (1 to 9; more as digits).
String romanVersion(int n) {
  const numerals = ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX'];
  return n >= 1 && n < numerals.length ? numerals[n] : '$n';
}

/// The Eel from the side on the open sea, in [dress] on [form] (see
/// side_ship.dart): the elevation to the plan below it.
class ShipYardSideView extends StatelessWidget {
  const ShipYardSideView({
    super.key,
    required this.dress,
    this.form,
    this.height = 124,
  });

  final ShipDress dress;
  final ShipForm? form;
  final double height;

  @override
  Widget build(BuildContext context) => SeaSideScene(
        key: const Key('yard_side_preview'),
        waters: SeaWaters.open,
        ship: form,
        dress: dress,
        height: height,
      );
}

/// The Eel from above on the open sea, in [dress], gently afloat (still
/// with reduced motion).
class ShipYardPreview extends StatefulWidget {
  const ShipYardPreview({
    super.key,
    required this.dress,
    this.form,
    this.height = 176,
    this.refit = 0,
  });

  final ShipDress dress;

  /// The hull to draw her on (see ship_forms.dart); the sloop when null.
  final ShipForm? form;
  final double height;
  final int refit;

  @override
  State<ShipYardPreview> createState() => _ShipYardPreviewState();
}

class _ShipYardPreviewState extends State<ShipYardPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: const Duration(seconds: 12));
  bool _started = false;

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    if (!still && !_started) {
      _started = true;
      _clock.repeat();
    } else if (still && _started) {
      _started = false;
      _clock.stop();
    }
    final look = (widget.form == null
            ? TopShipLook.rustyEel
            : TopShipLook.player(widget.form!))
        .dressed(widget.dress);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        key: const Key('yard_preview'),
        height: widget.height,
        child: AnimatedBuilder(
          animation: _clock,
          builder: (context, _) {
            final t = still ? 1.3 : _clock.value * 12;
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: SeaSurfacePainter(
                        waters: SeaWaters.open, weather: SeaWeather.calm, t: t),
                  ),
                ),
                LayoutBuilder(builder: (context, c) {
                  final width = ((c.maxWidth - 36) * 0.86).clamp(180.0, 400.0);
                  final box = topShipBoxHeight(width, look);
                  return Center(
                    child: SizedBox(
                      width: width,
                      height: box,
                      child: CustomPaint(
                        painter: TopShipPainter(
                          look: look,
                          flip: false,
                          facingDown: false,
                          t: t,
                          layers: 0,
                          maxLayers: 0,
                          battered: false,
                          down: const {},
                          burning: const {},
                          water: 0,
                          shield: const Color(0xFF80D8FF),
                          foam: const Color(0xFFE6F2F4),
                          roomColors: {
                            for (final r in ShipRoom.values)
                              r: const Color(0xFFAAAAAA)
                          },
                          refit: widget.refit,
                          speed: 0.6,
                          dress: widget.dress,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One look in miniature, as it would show on the ship.
class LookSwatchPainter extends CustomPainter {
  const LookSwatchPainter(this.look);
  final ShipLook look;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w / 2, h / 2);
    switch (look.category) {
      case 'hull':
        // A hull from above: the hull, the deck inside it, the trim line.
        final hull = Path()
          ..moveTo(w * 0.08, h * 0.3)
          ..lineTo(w * 0.62, h * 0.18)
          ..quadraticBezierTo(w * 0.95, h * 0.5, w * 0.62, h * 0.82)
          ..lineTo(w * 0.08, h * 0.7)
          ..close();
        canvas.drawPath(hull, Paint()..color = look.color ?? Colors.brown);
        final deck = Path()
          ..moveTo(w * 0.14, h * 0.36)
          ..lineTo(w * 0.6, h * 0.27)
          ..quadraticBezierTo(w * 0.84, h * 0.5, w * 0.6, h * 0.73)
          ..lineTo(w * 0.14, h * 0.64)
          ..close();
        canvas.drawPath(deck, Paint()..color = look.color2 ?? Colors.brown);
        canvas.drawPath(
            deck,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6
              ..color = look.color3 ?? Colors.red);
      case 'sail':
        final sail = Path()
          ..moveTo(w * 0.34, h * 0.1)
          ..quadraticBezierTo(w * 0.86, h * 0.5, w * 0.34, h * 0.9)
          ..quadraticBezierTo(w * 0.52, h * 0.5, w * 0.34, h * 0.1)
          ..close();
        canvas.drawPath(sail, Paint()..color = look.color ?? Colors.white);
        paintCloth(
            canvas,
            sail,
            Rect.fromLTRB(w * 0.34, h * 0.1, w * 0.8, h * 0.9),
            look.pattern,
            look.color2 ?? Colors.brown);
        canvas.drawPath(
            sail,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = look.color3 ?? Colors.brown);
        canvas.drawLine(
            Offset(w * 0.34, h * 0.06),
            Offset(w * 0.34, h * 0.94),
            Paint()
              ..color = const Color(0xFF3A2818)
              ..strokeWidth = 2);
      case 'figurehead':
        if (look.pattern == 'none') {
          canvas.drawLine(
              Offset(w * 0.2, h / 2),
              Offset(w * 0.8, h / 2),
              Paint()
                ..color = const Color(0xFF6B4A2E)
                ..strokeWidth = 4
                ..strokeCap = StrokeCap.round);
        } else {
          paintFigurehead(
              canvas,
              Offset(w * 0.62, h / 2),
              h * 0.52,
              ShipDress(
                  figurehead: look.pattern,
                  figureheadColor: look.color,
                  figureheadEye: look.color2),
              0);
        }
      case 'ensign':
        canvas.drawLine(
            Offset(w * 0.12, h * 0.1),
            Offset(w * 0.12, h * 0.9),
            Paint()
              ..color = const Color(0xFF3A2818)
              ..strokeWidth = 2);
        // The flag streams aft in the ship's own drawing; here it is
        // mirrored to fly to the right of its pole.
        canvas.save();
        canvas.translate(w * 0.12, 0);
        canvas.scale(-1, 1);
        paintEnsign(
            canvas,
            Offset(0, h / 2),
            w * 0.74,
            ShipDress(
                ensign: look.pattern,
                ensignColor: look.color,
                ensignDevice: look.color2),
            const Color(0xFFB0472E),
            0.6);
        canvas.restore();
      default:
        canvas.drawCircle(c, h * 0.2, Paint()..color = Colors.grey);
    }
  }

  @override
  bool shouldRepaint(covariant LookSwatchPainter old) => old.look != look;
}

/// The shelf of looks: a tab per category, a tile per look, and the
/// chosen look's words and button.
class LookShelf extends ConsumerWidget {
  const LookShelf({
    super.key,
    required this.looks,
    required this.category,
    required this.onCategory,
    required this.worn,
    required this.previewed,
    required this.onTry,
    required this.owned,
    required this.chapter,
    required this.slain,
    required this.beastNames,
    required this.gold,
    required this.onWear,
  });

  final Map<String, ShipLook> looks;
  final String category;
  final ValueChanged<String> onCategory;

  /// The look worn in each category (id), as the ship wears it now.
  final Map<String, String> worn;

  /// The look being tried in each category (id), if any.
  final Map<String, String> previewed;
  final ValueChanged<ShipLook> onTry;
  final Set<String> owned;
  final int chapter;
  final Set<String> slain;

  /// Beast id to name, for a trophy's note.
  final Map<String, String> beastNames;
  final int gold;
  final void Function(ShipLook look) onWear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final inCategory = [
      for (final look in looks.values)
        if (look.category == category) look,
    ];
    final tried = previewed[category];
    final selectedId = tried ?? worn[category];
    final selected = looks[selectedId];
    String stateLine(ShipLook look) {
      if (worn[category] == look.id) return tr(ref, 'look_worn_label');
      if (look.isDefault || owned.contains(look.id)) {
        return tr(ref, 'free_label');
      }
      if (look.trophyOf.isNotEmpty) {
        return slain.contains(look.trophyOf)
            ? tr(ref, 'free_label')
            : tr(ref, 'look_trophy_locked');
      }
      if (chapter < look.unlockChapter) {
        return tr(ref, 'look_locked_note')
            .replaceAll('{n}', '${look.unlockChapter}');
      }
      return '${look.cost} ${tr(ref, 'gold_label')}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final cat in shipLookCategories)
              ChoiceChip(
                key: Key('look_tab_$cat'),
                label: Text(tr(ref, 'look_category_$cat')),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                selected: category == cat,
                onSelected: (_) => onCategory(cat),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final look in inCategory)
              _LookTile(
                key: Key('look_${look.id}'),
                look: look,
                name: look.name,
                state: stateLine(look),
                isWorn: worn[category] == look.id,
                isTried: tried == look.id,
                locked: !lookOffered(look,
                    chapter: chapter, slain: slain, owned: owned),
                onTap: () => onTry(look),
              ),
          ],
        ),
        if (selected != null) ...[
          const SizedBox(height: 10),
          Text(selected.name, style: theme.textTheme.titleSmall),
          if (selected.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(selected.description,
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
            ),
          if (selected.trophyOf.isNotEmpty &&
              !slain.contains(selected.trophyOf) &&
              !owned.contains(selected.id))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                  tr(ref, 'look_trophy_note').replaceAll(
                      '{beast}', beastNames[selected.trophyOf] ?? '?'),
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: _wearButton(context, ref, selected),
          ),
        ],
      ],
    );
  }

  Widget _wearButton(BuildContext context, WidgetRef ref, ShipLook look) {
    final isWorn = worn[category] == look.id;
    final isOwned = look.isDefault || owned.contains(look.id);
    final offered =
        lookOffered(look, chapter: chapter, slain: slain, owned: owned);
    final price = isOwned || look.trophyOf.isNotEmpty ? 0 : look.cost;
    final label = isWorn
        ? tr(ref, 'look_worn_label')
        : price == 0
            ? tr(ref, 'look_wear_button')
            : '${tr(ref, 'look_buy_button')} ($price ${tr(ref, 'gold_label')})';
    return ElevatedButton(
      key: Key('wear_${look.id}'),
      onPressed: isWorn || !offered || gold < price ? null : () => onWear(look),
      child: Text(label),
    );
  }
}

class _LookTile extends StatelessWidget {
  const _LookTile({
    super.key,
    required this.look,
    required this.name,
    required this.state,
    required this.isWorn,
    required this.isTried,
    required this.locked,
    required this.onTap,
  });

  final ShipLook look;
  final String name;
  final String state;
  final bool isWorn;
  final bool isTried;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final edge = isTried
        ? ink.gold
        : isWorn
            ? ink.heal
            : rarityColor(look.rarity).withValues(alpha: 0.6);
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: edge, width: isTried || isWorn ? 2 : 1),
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.4),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 46,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C3A4A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CustomPaint(painter: LookSwatchPainter(look)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium),
              Text(state,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: isWorn ? ink.heal : ink.ash, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A hull in miniature, from above: its outline and rig on the sea.
class HullThumb extends StatelessWidget {
  const HullThumb({super.key, required this.form, this.width = 120});

  final ShipForm form;
  final double width;

  @override
  Widget build(BuildContext context) {
    final look = TopShipLook.player(form);
    final height = topShipBoxHeight(width, look);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height + 10,
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(
                painter: SeaSurfacePainter(
                    waters: SeaWaters.open, weather: SeaWeather.calm, t: 1.3),
              ),
            ),
            Positioned(
              left: 0,
              top: 5,
              width: width,
              height: height,
              child: CustomPaint(
                painter: TopShipPainter(
                  look: look,
                  flip: false,
                  facingDown: false,
                  t: 1.3,
                  layers: 0,
                  maxLayers: 0,
                  battered: false,
                  down: const {},
                  burning: const {},
                  water: 0,
                  shield: const Color(0xFF80D8FF),
                  foam: const Color(0xFFE6F2F4),
                  roomColors: {
                    for (final r in ShipRoom.values) r: const Color(0xFFAAAAAA)
                  },
                  speed: 0.2,
                  pixel: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
