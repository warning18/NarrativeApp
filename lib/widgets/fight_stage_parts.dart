// The small pieces of the fight's stage (docs/proposals/fight-fixed-sizes.md):
// the health bar over a figure's box, and the disc that stands in the box of
// an ally (who has no sprite yet: the initial on the member's own colour).
import 'package:flutter/material.dart';

/// A thin health bar [width] wide, over a box. Green while the figure is
/// well, amber when hurt, red when low; nothing when it has no health left.
class StageBar extends StatelessWidget {
  const StageBar({
    super.key,
    required this.current,
    required this.max,
    required this.width,
  });

  final int current;
  final int max;
  final double width;

  static const double height = 6;

  @override
  Widget build(BuildContext context) {
    final fraction = max <= 0 ? 0.0 : (current / max).clamp(0.0, 1.0);
    final colour = fraction > 0.5
        ? const Color(0xFF4CAF50)
        : fraction > 0.25
            ? const Color(0xFFE0A030)
            : const Color(0xFFD94B3B);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.centerLeft,
      child: Container(
        width: width * fraction,
        height: height,
        decoration: BoxDecoration(
          color: colour,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

/// An ally's mark in its box: a disc of [accent] with the member's initial,
/// dimmed when knocked out.
class StageDisc extends StatelessWidget {
  const StageDisc({
    super.key,
    required this.initial,
    required this.accent,
    required this.diameter,
    this.alive = true,
  });

  final String initial;
  final Color accent;
  final double diameter;
  final bool alive;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: alive ? 1 : 0.4,
        child: Container(
          width: diameter,
          height: diameter,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF1E8D2),
            border: Border.all(color: accent, width: 3),
          ),
          child: Text(
            initial,
            style: TextStyle(
              color: const Color(0xFF3A2E1E),
              fontSize: diameter * 0.45,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}
