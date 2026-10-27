// The scene's words as a band over a map or a street (v1.588, the user's call
// to open a hub as its map and a doorstep scene as its street;
// docs/proposals/ux-presentation-answers.md, 1 and 4): a few lines of the
// prose over a soft shade, and a tap (or a drag) opens the ArrivalSheet with
// the whole scene. The band is the sheet collapsed.
import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';

/// How many lines the band shows: three over a hub's map, four over a
/// street's sky.
const int hubBandLines = 3;
const int streetBandLines = 4;

/// The first paragraph of [text] (markup already stripped), for the band.
String bandTextOf(String text) {
  final first = text
      .split(RegExp(r'\n[ \t]*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .firstOrNull;
  return (first ?? '').replaceAll(RegExp(r'\s+'), ' ');
}

class SceneBand extends StatelessWidget {
  const SceneBand({
    super.key,
    required this.text,
    required this.onOpen,
    this.lines = hubBandLines,
    this.title = '',
    this.openTip = '',
  });

  /// The scene's words, plain.
  final String text;

  /// Opens the whole scene (the ArrivalSheet).
  final VoidCallback onOpen;
  final int lines;

  /// The place's name, small above the words (empty: none).
  final String title;

  /// What a screen reader says of the band.
  final String openTip;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final words = bandTextOf(text);
    if (words.isEmpty) return const SizedBox.shrink();
    return Semantics(
      button: true,
      label: openTip,
      child: GestureDetector(
        key: const Key('scene_band'),
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 120) onOpen();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xE617151B), Color(0xB317151B), Color(0x0017151B)],
              stops: [0, 0.7, 1],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title.isNotEmpty)
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: InkFonts.system,
                        fontSize: 11,
                        letterSpacing: 0.6,
                        color: ink.gold)),
              Text(words,
                  key: const Key('scene_band_text'),
                  maxLines: lines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: InkFonts.prose,
                      fontSize: 14,
                      height: 1.35,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFEDE3C8))),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.keyboard_arrow_down,
                    size: 16, color: ink.gold.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
