// The scene in small, above a panel's choices (in-place choices, the scene
// panel, v1.686): you and the one the scene faces on one ground line, and
// the question the scene ends on. With four choices, or a long one, it folds
// to one line (their head, their name, the question) so the cards keep the
// room. A scene with no one faced shows a voice's icon in place of a head.
import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';

/// Who the scene faces: [name], their [role] if known, and [headAsset] (a
/// head from assets/visuals/heads) when there is one.
class SceneFaced {
  const SceneFaced({required this.id, required this.name, this.role = ''});

  final String id;
  final String name;
  final String role;

  String get headAsset => 'assets/visuals/heads/$id.png';
}

class SceneVignette extends StatelessWidget {
  const SceneVignette({
    super.key,
    required this.heroName,
    required this.prompt,
    this.faced,
    this.folded = false,
  });

  final String heroName;

  /// The scene's question ('' for none).
  final String prompt;

  /// The one the scene faces; null for a voice, or no one.
  final SceneFaced? faced;

  /// One line instead of the two-figure scene.
  final bool folded;

  static const String _heroHead = 'assets/visuals/heads/hero.png';

  Widget _head(BuildContext context, String? asset, String name,
      {double size = 40}) {
    final scheme = Theme.of(context).colorScheme;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final fallback = Center(
      child: asset == null
          ? Icon(Icons.record_voice_over_outlined,
              size: size * 0.55, color: scheme.onSurfaceVariant)
          : CircleAvatar(
              radius: size * 0.32,
              backgroundColor: scheme.primary,
              child: Text(initial,
                  style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: size * 0.36,
                      fontWeight: FontWeight.bold)),
            ),
    );
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: asset == null
          ? fallback
          : Image.asset(asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) => fallback),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final who = faced;
    final question = prompt.isEmpty
        ? const SizedBox.shrink()
        : Text(prompt,
            key: const Key('scene_prompt'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontStyle: FontStyle.italic, color: ink.ash));
    return Container(
      key: Key(folded ? 'scene_vignette_folded' : 'scene_vignette'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ink.seam),
      ),
      child: folded
          ? Row(
              children: [
                _head(context, who?.headAsset, who?.name ?? '', size: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (who != null)
                        Text(who.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge),
                      question,
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _head(context, _heroHead, heroName),
                    // One ground line between the two.
                    Expanded(
                      child: Container(
                        height: 1,
                        margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                        color: ink.seam,
                      ),
                    ),
                    _head(context, who?.headAsset, who?.name ?? ''),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(heroName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: ink.ash)),
                    ),
                    if (who != null)
                      Flexible(
                        child: Text(
                          who.role.isEmpty
                              ? who.name
                              : '${who.name} · ${who.role}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                if (prompt.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  question,
                ],
              ],
            ),
    );
  }
}
