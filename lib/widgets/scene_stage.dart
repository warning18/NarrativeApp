// Stage mode (in-place choices, PR B, v1.687): a scene with a fight among its
// choices, facing someone who has a standing sprite, plays on a small stage
// instead of a panel -- you on the left, the one you face on the right, one
// ground line between, their name over them and the scene's question under.
// A choice picked puts its words in a balloon over you; one that moves you
// lights the door at the stage's edge with the place it leads to. The choices
// themselves are the cards under it (the Journey's).
import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';
import 'fight_sprites.dart';

/// The ids of those who have a standing sprite, for [sceneChoiceMode].
bool sceneHasSprite(String facingId) => enemyFightSprite(facingId) != null;

class SceneStage extends StatelessWidget {
  const SceneStage({
    super.key,
    required this.foeId,
    required this.foeName,
    required this.prompt,
    this.balloon = '',
    this.doorName = '',
    this.doorLit = false,
  });

  final String foeId;
  final String foeName;

  /// The scene's question ('' for none).
  final String prompt;

  /// What the picked choice says, over the hero ('' when none is picked).
  final String balloon;

  /// The place the picked choice leads to, when it moves the party.
  final String doorName;
  final bool doorLit;

  /// The stage's height at [width]: 150 at a narrow phone, up to 210.
  static double heightFor(double width) => (width * 0.5).clamp(150.0, 210.0);

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final theme = Theme.of(context);
    final still = MediaQuery.of(context).disableAnimations;
    return LayoutBuilder(builder: (context, box) {
      final h = heightFor(box.maxWidth);
      final scale = ((h - 44) / 48).clamp(2.0, 3.2);
      final foe = enemyFightSprite(foeId);
      return Container(
        key: const Key('scene_stage'),
        height: h,
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ink.seam),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A2735), Color(0xFF1B1924)],
          ),
        ),
        child: Stack(
          children: [
            // The ground line the two stand on.
            Positioned(
              left: 0,
              right: 0,
              bottom: 22,
              child: Container(height: 1, color: const Color(0x66FFFFFF)),
            ),
            Positioned(
              left: 18,
              bottom: 22,
              child: _Figure(set: roninSprite, scale: scale, keyName: 'hero'),
            ),
            if (foe != null)
              Positioned(
                right: 18,
                bottom: 22,
                child: _Figure(set: foe, scale: scale, keyName: 'foe'),
              ),
            // Their name over them.
            Positioned(
              right: 12,
              top: 8,
              child: Container(
                key: const Key('scene_stage_foe'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(foeName,
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
            // The picked choice's words, in a balloon over the hero.
            Positioned(
              left: 8,
              top: 8,
              width: box.maxWidth * 0.5,
              child: AnimatedOpacity(
                duration:
                    still ? Duration.zero : const Duration(milliseconds: 200),
                opacity: balloon.isEmpty ? 0 : 1,
                child: balloon.isEmpty
                    ? const SizedBox.shrink()
                    : Container(
                        key: const Key('scene_stage_balloon'),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1E9D6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(balloon,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF2A2420),
                                fontFamily: InkFonts.prose)),
                      ),
              ),
            ),
            // The door: where the picked choice leads, dim until one does.
            if (doorName.isNotEmpty)
              Positioned(
                right: 0,
                top: h * 0.42,
                child: Opacity(
                  opacity: doorLit ? 1 : 0.35,
                  child: Container(
                    key: const Key('scene_stage_door'),
                    padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
                    decoration: BoxDecoration(
                      color: ink.gold.withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(doorName,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 3),
                        const Icon(Icons.arrow_forward,
                            size: 12, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ),
            // The question, at the foot of the stage.
            if (prompt.isNotEmpty)
              Positioned(
                left: 10,
                right: 10,
                bottom: 2,
                child: Text(prompt,
                    key: const Key('scene_prompt'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic, color: Colors.white70)),
              ),
          ],
        ),
      );
    });
  }
}

/// A figure's standing frame, [scale] times its size (hard pixels), mirrored
/// when its art faces the other way than it should on this side.
class _Figure extends StatelessWidget {
  const _Figure(
      {required this.set, required this.scale, required this.keyName});

  final FightSpriteSet set;
  final double scale;
  final String keyName;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: FightSpriteImages.loaded,
      builder: (context, _, __) {
        final use = FightSpriteImages.effective(set);
        final w = use.frameWidth * scale;
        final h = use.frameHeight * scale;
        return SizedBox(
          key: Key('scene_stage_$keyName'),
          width: w,
          height: h,
          child: CustomPaint(painter: _FigurePainter(set)),
        );
      },
    );
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter(this.set) : super(repaint: FightSpriteImages.loaded);

  final FightSpriteSet set;

  @override
  void paint(Canvas canvas, Size size) {
    final image = FightSpriteImages.idleOf(set);
    if (image == null) return;
    final use = FightSpriteImages.effective(set);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
          0, 0, use.frameWidth.toDouble(), use.frameHeight.toDouble()),
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(_FigurePainter old) => old.set != set;
}
