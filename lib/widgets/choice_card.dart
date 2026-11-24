// A choice acted out where the party stands (design 1 of
// docs/proposals/inplace-choices.md): the action's icon in its colour, the
// choice's words, a note line (who is faced, where the aftermath leads) and
// one tag at the right (a price, an alignment shift, a check). Picked, the
// card shows Go in place of the tag; a second tap does it too, as a pin does.
import 'package:flutter/material.dart';

import '../data/story_plates.dart' show ChoiceWeight;
import '../theme/stitched_ink.dart';
import 'clan_offer_gifts.dart' show CardTier;
import 'ink_chip.dart';
import 'story_panel.dart';
import '../theme/icon_sizes.dart';

/// The one tag a card carries: "30 gold", "Good +2", "CHA DC 12", "Fight".
class ChoiceTag {
  const ChoiceTag(this.label, this.color);

  final String label;
  final Color color;
}

class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    required this.goLabel,
    this.notes = const [],
    this.leadsTo,
    this.tag,
    this.selected = false,
    this.locked = false,
    this.busy = false,
    this.onTap,
    this.onGo,
    this.goKey,
    this.leading,
    this.weight = ChoiceWeight.plain,
    this.clanColor,
    this.richTier = CardTier.epic,
  });

  final IconData icon;
  final Color color;
  final String text;
  final String goLabel;

  /// Short lines under the text: who is faced.
  final List<String> notes;

  /// Where the aftermath takes the party, when it is not here.
  final String? leadsTo;
  final ChoiceTag? tag;
  final bool selected;

  /// A shut way: its lock for an icon, its reason for the text, no Go.
  final bool locked;
  final bool busy;
  final VoidCallback? onTap;
  final VoidCallback? onGo;
  final Key? goKey;

  /// Worn instead of the round icon (the Journey's ways wear their banner).
  final Widget? leading;

  /// How much the choice weighs (lib/data/story_plates.dart): a [plain] one
  /// is the card as it was, a [weighty] one wears the clan's accent in the
  /// quiet frame, a [major] one the rich metal ([richTier]: gilded, or gold
  /// for a banner piece). [clanColor] is the clan it touches, if any.
  final ChoiceWeight weight;
  final Color? clanColor;
  final CardTier richTier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final tone = locked ? ink.ash : color;
    final framed = weight != ChoiceWeight.plain && !locked;
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      child: Row(
        children: [
          if (leading != null && !locked)
            SizedBox(width: 34, height: 38, child: Center(child: leading))
          else
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? tone : theme.colorScheme.surface,
                border: Border.all(color: tone, width: 2),
              ),
              child: Icon(
                locked ? Icons.lock_outline : icon,
                size: IconSize.s16,
                color: selected ? theme.colorScheme.surface : tone,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Opacity(
              opacity: locked ? 0.6 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: InkFonts.prose,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                  for (final note in notes)
                    Text(
                      note,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: ink.ash,
                      ),
                    ),
                  if (leadsTo != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          size: IconSize.inline,
                          color: ink.ash,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            leadsTo!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: ink.ash,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (selected && !locked) ...[
            const SizedBox(width: 8),
            FilledButton(
              key: goKey,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              onPressed: busy ? null : onGo,
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(goLabel),
            ),
          ] else if (tag != null) ...[
            const SizedBox(width: 8),
            ChoiceTagChip(tag: tag!, locked: locked),
          ],
        ],
      ),
    );
    if (framed) {
      // A weight shows in the frame: the clan's accent, or the rich metal.
      return Material(
        color: Colors.transparent,
        child: storyWeightFrame(
          weight: weight,
          clan: clanColor ?? tone,
          rich: richTier,
          child: InkWell(
            onTap: onTap,
            child: selected
                ? ColoredBox(color: tone.withValues(alpha: 0.12), child: row)
                : row,
          ),
        ),
      );
    }
    return Material(
      color: selected
          ? Color.alphaBlend(
              tone.withValues(alpha: 0.12),
              theme.colorScheme.surfaceContainer,
            )
          : theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? tone : theme.colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: row,
      ),
    );
  }
}

/// A card's tag as a chip; the Journey's pins and rows wear it too (v1.854).
/// Since v1.882 it is the app's one [InkChip]; a locked card's tag is ash.
class ChoiceTagChip extends StatelessWidget {
  const ChoiceTagChip({super.key, required this.tag, this.locked = false});

  final ChoiceTag tag;
  final bool locked;

  @override
  Widget build(BuildContext context) =>
      InkChip(tag.label, color: locked ? InkColors.of(context).ash : tag.color);
}
