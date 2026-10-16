// A written detour as a scene (docs/proposals/detours-wave11.md, "the
// exploration scene screen"): while the party plays one of detour_scenes.json's
// scenes, the Journey's map gives way to this band, as the exploration
// screens have a side-view scene over their words. The scene's title and
// the beat it is at ("2 / 3") sit over it, with the place the beat is set
// in; the beat's words and ways are the cards under it, as ever.
//
// The side-view kits that exist (the desert, the ruins) dress the biomes
// they fit; every other place gets a band tinted for its biome, with its
// glyph, so no scene waits on art.
import 'package:flutter/material.dart';

import '../data/detour_scenes.dart';
import '../theme/stitched_ink.dart';
import 'side_view/desert_kit.dart';
import 'side_view/ruins_kit.dart';
import 'side_view/side_view.dart';

/// The kit that dresses a scene of a biome, if there is one: the desert's
/// for the dry lands, the ruins' for the burned, torn and shattered ones.
enum DetourKit { desert, ruins }

DetourKit? detourKitOf(String? biome) => switch (biome) {
      'desert' || 'arid_coast' => DetourKit.desert,
      'ashlands' || 'tear' || 'volcanic' => DetourKit.ruins,
      _ => null,
    };

/// The two colours a biome's band runs between (top, ground), and its glyph.
(Color, Color, IconData) detourBiomeLook(String? biome) => switch (biome) {
      'fen' => (
          const Color(0xFF2A3F36),
          const Color(0xFF6C8A6E),
          Icons.grass_outlined
        ),
      'frost' => (
          const Color(0xFF6E8FA8),
          const Color(0xFFDCE8F0),
          Icons.ac_unit
        ),
      'sea_cliffs' || 'sea' => (
          const Color(0xFF274C63),
          const Color(0xFF8CB0BE),
          Icons.waves
        ),
      'jungle' => (
          const Color(0xFF1F3A25),
          const Color(0xFF5E9A5A),
          Icons.park_outlined
        ),
      'temperate' => (
          const Color(0xFF3B5367),
          const Color(0xFFA7B88F),
          Icons.landscape_outlined
        ),
      _ => (
          const Color(0xFF2B2438),
          const Color(0xFF7E6E8F),
          Icons.explore_outlined
        ),
    };

class DetourSceneBand extends StatelessWidget {
  const DetourSceneBand({
    super.key,
    required this.scene,
    required this.beat,
    required this.french,
    required this.detourLabel,
    this.text = '',
    this.note = '',
  });

  final DetourScene scene;

  /// The beat the party is at, from 0.
  final int beat;
  final bool french;

  /// "Detour", in the reader's language.
  final String detourLabel;

  /// The beat's words, under the scene (the Journey keeps a scene's text
  /// behind "Read", but a detour is its beats), and what the last choice did.
  final String text;
  final String note;

  @override
  Widget build(BuildContext context) {
    final count = scene.beats.length;
    final at = beat.clamp(0, count == 0 ? 0 : count - 1);
    final biome = scene.where.biomes.isEmpty ? null : scene.where.biomes.first;
    final kit = detourKitOf(biome);
    final (top, ground, glyph) = detourBiomeLook(biome);
    final ink = InkColors.dark;
    final step = scene.beats.isEmpty ? null : scene.beats[at];
    final place = step == null
        ? ''
        : (french && step.placeFr.isNotEmpty ? step.placeFr : step.place);
    final title =
        french && scene.titleFr.isNotEmpty ? scene.titleFr : scene.title;
    final progress = count <= 1 ? 1.0 : (at + 1) / count;
    final art = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LayoutBuilder(builder: (context, box) {
        final height = box.maxHeight.isFinite ? box.maxHeight : 190.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (kit != null)
              SideViewScene(
                layers: switch (kit) {
                  DetourKit.desert => desertLayers(progress: progress),
                  DetourKit.ruins => ruinsLayers(progress: progress),
                },
                moving: false,
                height: height,
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [top, ground],
                  ),
                ),
                child: Center(
                  child: Icon(glyph,
                      size: 96, color: Colors.white.withValues(alpha: 0.14)),
                ),
              ),
            Positioned(
              left: 8,
              top: 8,
              right: 96,
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 6, 12, 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141218).withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          scene.tags.contains(detourLandmarkTag)
                              ? Icons.star_outline
                              : Icons.explore_outlined,
                          size: 22,
                          color: ink.gold),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(detourLabel.toUpperCase(),
                                style: TextStyle(
                                    fontFamily: InkFonts.system,
                                    fontSize: 9.5,
                                    letterSpacing: 1,
                                    color: ink.gold)),
                            Text(title,
                                key: const Key('journey_detour_title'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontFamily: InkFonts.display,
                                    fontSize: 16,
                                    height: 1.1,
                                    color: Color(0xFFE9E3D5))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // The beat, as dots and as "2 / 3".
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                key: const Key('journey_detour_beat'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF141218).withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < count; i++)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i <= at ? ink.gold : Colors.transparent,
                              border: Border.all(color: ink.gold, width: 1.2),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('${at + 1} / $count',
                        style: const TextStyle(
                            fontFamily: InkFonts.system,
                            fontSize: 11,
                            color: Color(0xFFE9E3D5))),
                  ],
                ),
              ),
            ),
            if (place.isNotEmpty)
              Positioned(
                left: 8,
                bottom: 8,
                right: 8,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141218).withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 14, color: Color(0xFFA8A194)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(place,
                              key: const Key('journey_detour_place'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: InkFonts.system,
                                  fontSize: 11.5,
                                  color: Color(0xFFE9E3D5))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
    if (text.isEmpty && note.isEmpty) {
      return KeyedSubtree(key: const Key('journey_detour_scene'), child: art);
    }
    final theme = Theme.of(context);
    final ash = InkColors.of(context).ash;
    return LayoutBuilder(
      key: const Key('journey_detour_scene'),
      builder: (context, box) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: art),
          const SizedBox(height: 8),
          // The words take what they need, up to two fifths of the slot.
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: box.maxHeight * 0.42),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: SingleChildScrollView(
                key: const Key('journey_detour_text'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.isNotEmpty) ...[
                      Text(note,
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic, color: ash)),
                      const SizedBox(height: 6),
                    ],
                    Text(text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: InkFonts.prose, height: 1.4)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
