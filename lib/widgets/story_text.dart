// The text of a scene (docs/proposals/story-markup.md): paragraphs, key facts
// in bold, the names of people, places and clans in a colour of their own,
// and, when the scene is new, writing itself out quickly. One tap shows all
// of it; the next tap goes on as it always did. With reduce motion (or
// animations off) the text is there at once, and so is a scene read before.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/story_markup.dart';
import '../providers/story_text_provider.dart';
import '../theme/stitched_ink.dart';
import '../l10n/app_locale.dart';

/// Whether new scenes write themselves out. The tests turn it off (see
/// test/flutter_test_config.dart), the ones about the typewriter back on.
bool storyTypewriterOn = true;

/// Whether scene text is shown whole at once here: the typewriter is off (the
/// tests), or the player asked for reduced motion.
bool storyTextShownAtOnce(BuildContext context) =>
    !storyTypewriterOn || MediaQuery.of(context).disableAnimations;

/// The colour of a name of [kind], readable on the page of either theme.
Color storyNameColor(StoryNameKind kind, InkColors ink) => switch (kind) {
      StoryNameKind.person => ink.ember,
      StoryNameKind.place => ink.tide,
      StoryNameKind.clan => ink.voidColor,
    };

/// How long a text of [length] characters takes to write itself out: about
/// 175 characters a second (a third slower than the first 260), never under
/// 0.6 s nor over 6 s.
Duration storyTypeDuration(int length) =>
    Duration(milliseconds: (length * 1000 / 175).clamp(600, 6000).round());

class StoryText extends ConsumerStatefulWidget {
  const StoryText({
    super.key,
    required this.text,
    required this.style,
    this.revealKey,
    this.firstSentenceBold = true,
    this.textAlign = TextAlign.start,
    this.paragraphGap = 12,
  });

  /// The scene's words, with their markup.
  final String text;
  final TextStyle style;

  /// Names the scene being read: the text writes itself out the first time
  /// it is shown under this key, and reports it has finished (see
  /// [storyTextDoneProvider]). Null: shown at once, always.
  final String? revealKey;

  /// A text with no markup at all keeps the look it had before it was marked:
  /// its first sentence in bold.
  final bool firstSentenceBold;
  final TextAlign textAlign;
  final double paragraphGap;

  @override
  ConsumerState<StoryText> createState() => _StoryTextState();
}

class _StoryTextState extends ConsumerState<StoryText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this);
  bool _typing = false;
  String? _startedFor;

  @override
  void initState() {
    super.initState();
    // Run out or shown all by a tap: written, whichever it was.
    _anim.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      if (_typing) setState(() => _typing = false);
      _markDone();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _markDone() {
    final key = widget.revealKey;
    if (key == null) return;
    Future.microtask(() {
      if (!mounted) return;
      ref.read(storyTextDoneProvider.notifier).update((done) {
        if (done.contains(key)) return done;
        final next = {...done, key};
        return next.length > 40 ? next.skip(next.length - 40).toSet() : next;
      });
    });
  }

  /// Decides, once for each reveal key, whether the text writes itself out.
  void _start(int length) {
    final key = widget.revealKey;
    if (_startedFor == key && _startedFor != null) return;
    _startedFor = key;
    final already =
        key != null && ref.read(storyTextDoneProvider).contains(key);
    if (key == null ||
        already ||
        storyTextShownAtOnce(context) ||
        length == 0) {
      _typing = false;
      _anim.value = 1;
      _markDone();
      return;
    }
    _typing = true;
    _anim.duration = storyTypeDuration(length);
    _anim.forward(from: 0);
  }

  void _skip() {
    if (!_typing) return;
    _anim.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    final french = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final names = ref.watch(storyNameMatcherProvider(french));
    final paragraphs = parseStoryText(widget.text,
        names: names, firstSentenceBold: widget.firstSentenceBold);
    final total = storyTextLength(paragraphs);
    _start(total);
    ref.listen<int>(storyTextSkipProvider, (_, __) => _skip());
    final ink = InkColors.of(context);
    final base = widget.style;

    List<InlineSpan> spans(List<StoryRun> runs, int shown, int offset) {
      final out = <InlineSpan>[];
      var at = offset;
      for (final r in runs) {
        final TextStyle style = base.copyWith(
          fontWeight: r.bold ? FontWeight.w700 : null,
          fontStyle: r.italic ? FontStyle.italic : null,
          color: r.kind == null ? null : storyNameColor(r.kind!, ink),
        );
        final visible = (shown - at).clamp(0, r.text.length);
        if (visible >= r.text.length) {
          out.add(TextSpan(text: r.text, style: style));
        } else {
          // Not written yet: there for the layout, but not seen.
          if (visible > 0) {
            out.add(TextSpan(text: r.text.substring(0, visible), style: style));
          }
          out.add(TextSpan(
              text: r.text.substring(visible),
              style: style.copyWith(color: Colors.transparent)));
        }
        at += r.text.length;
      }
      return out;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _typing ? _skip : null,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final shown =
              _anim.value >= 1 ? total : (total * _anim.value).floor();
          var offset = 0;
          return Column(
            key: const Key('story_text'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, runs) in paragraphs.indexed) ...[
                if (i > 0) SizedBox(height: widget.paragraphGap),
                () {
                  final start = offset;
                  offset += runs.fold(0, (s, r) => s + r.text.length);
                  return Text.rich(
                    TextSpan(children: spans(runs, shown, start)),
                    textAlign: widget.textAlign,
                  );
                }(),
              ],
            ],
          );
        },
      ),
    );
  }
}
