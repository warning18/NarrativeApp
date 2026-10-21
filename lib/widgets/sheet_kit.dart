// The parts the app's small sheets share: the camp's build sheet, the town's
// service and temple sheets. A header (an icon, the name, one italic line
// under it), rows (an icon, a name with an optional small label, its lines,
// a price), the price written one way, and the buttons (the main one carries
// its price, Close under it). Each sheet used to draw its own; one set of
// parts means a wrap bug on a 320 px phone is fixed once.
import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';

/// A sheet's title: [icon] (gold), [title], and under it one italic
/// [caption] (a keeper's or a builder's word), when there is one.
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    this.icon,
    this.caption,
    this.titleKey,
    this.captionKey,
  });

  final String title;
  final IconData? icon;
  final String? caption;
  final Key? titleKey;
  final Key? captionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final word = caption;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: ink.gold),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(title,
                    key: titleKey, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          if (word != null && word.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(word,
                key: captionKey,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

/// A price as the sheets and cards write it: a gold G and the amount, in
/// red when the player is [short] of it.
class PriceChip extends StatelessWidget {
  const PriceChip(this.amount, {super.key, this.short = false});

  final int amount;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('G',
            style: theme.textTheme.labelMedium?.copyWith(color: ink.gold)),
        const SizedBox(width: 3),
        Text('$amount',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: short ? ink.ember : ink.ash)),
      ],
    );
  }
}

/// One row of a sheet: a [leading] icon, a [title] (with a small [label]
/// above it when the thing has a kind to name), its [price] and [lines]
/// under it, and at the right a [trailing] mark (a chevron for a row that
/// opens something).
class SheetRow extends StatelessWidget {
  const SheetRow({
    super.key,
    required this.title,
    this.leading,
    this.label,
    this.lines = const [],
    this.price,
    this.trailing,
    this.enabled = true,
    this.onTap,
    this.titleKey,
    this.maxLines,
  });

  final String title;
  final Widget? leading;
  final String? label;
  final List<String> lines;
  final int? price;
  final Widget? trailing;
  final bool enabled;
  final VoidCallback? onTap;
  final Key? titleKey;

  /// Cuts the lines at this many, with an ellipsis; null shows them whole.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = [
      for (final l in lines)
        if (l.isNotEmpty) l
    ];
    return ListTile(
      leading: leading,
      title: label == null
          ? Text(title, key: titleKey)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label!, style: theme.textTheme.labelSmall),
                Text(title, key: titleKey),
              ],
            ),
      // The price leads the lines, so a narrow phone keeps the whole width
      // for the name.
      subtitle: shown.isEmpty && price == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (price != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: PriceChip(price!),
                  ),
                if (shown.isNotEmpty)
                  Text(shown.join('\n'),
                      maxLines: maxLines,
                      overflow:
                          maxLines == null ? null : TextOverflow.ellipsis),
              ],
            ),
      trailing: trailing,
      enabled: enabled,
      onTap: onTap,
    );
  }
}

/// The sheet's buttons: the main one, with its [price] in it when it has
/// one ("Build · 280 G"), and Close under it.
class SheetButtons extends StatelessWidget {
  const SheetButtons({
    super.key,
    required this.primaryLabel,
    required this.closeLabel,
    required this.onClose,
    this.price,
    this.onPrimary,
    this.primaryKey,
    this.closeKey,
  });

  final String primaryLabel;
  final String closeLabel;
  final VoidCallback onClose;
  final int? price;

  /// Null greys the main button out.
  final VoidCallback? onPrimary;
  final Key? primaryKey;
  final Key? closeKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: primaryKey,
          onPressed: onPrimary,
          child:
              Text(price == null ? primaryLabel : '$primaryLabel · $price G'),
        ),
        const SizedBox(height: 6),
        OutlinedButton(
            key: closeKey, onPressed: onClose, child: Text(closeLabel)),
      ],
    );
  }
}
