// The app's one chip (v1.878): a short word or two in a colour, on a tinted
// pill with a thin edge of the same colour. It replaces the square InkTag, the
// choice tag chip and the Tower's Material chips, which were three looks for
// the same thing.
import 'package:flutter/material.dart';

class InkChip extends StatelessWidget {
  const InkChip(
    this.label, {
    super.key,
    required this.color,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;

  /// A small picture before the words.
  final IconData? icon;

  /// A tighter chip, for a row of many.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: color, fontWeight: FontWeight.w700);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Flexible(child: Text(label, style: style)),
        ],
      ),
    );
  }
}
