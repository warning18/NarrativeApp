// The opening scene as an animation (version A, "La voix"): the first
// scene's text arrives one sentence at a time, word by word, instead of
// standing as a wall; each new sentence pushes the earlier ones up and dims
// them, the bold phrases are gold. When the last sentence ends the Grey
// Shroud's sigil (the title's standard) rises, a whisper behind the text,
// the text folds into a strip above the choice, and the sigil fades out as
// the choice settles. A tap finishes the sentence on screen; a second tap
// soon after jumps to the end. With reduced motion the whole text shows at
// once and only the choice fades in.
import 'package:flutter/material.dart';

import '../data/narration_clips.dart' show storyBodyFor;
import '../data/story_repository.dart';
import '../models/story_node.dart';
import '../theme/stitched_ink.dart';

/// Whether [node] is the story's first scene (the one that asks who the
/// character is), which opens as this animation.
bool isPrologueOpening(StoryNode node) =>
    node.id == StoryRepository.startNodeId &&
    node.choices.any((c) => c.opensCharacterCreation);

/// The sigil's asset: the title's own standard.
const String prologueSigilAsset = 'assets/visuals/banners/void_standard.png';

/// How much of the sigil shows at most: a whisper (8-15 %).
const double prologueSigilPeak = 0.12;

/// The sigil's opacity under reduced motion (still).
const double prologueSigilStill = 0.08;

/// Characters a second the text is told at.
const double _charsPerSecond = 46;
const double _sentenceGap = 0.35;
const double _paragraphGap = 0.8;
const double _minSentence = 0.8;

/// How long the sigil takes to rise at the end of the text, and how long
/// the fold and the sigil's fade take after it.
const double _sigilRise = 1.6;
const double _settleSeconds = 1.8;

/// Two taps closer than this: the second jumps to the end.
const Duration _doubleTap = Duration(milliseconds: 1500);

/// One sentence of the text: its plain characters, which are bold, and
/// whether it opens a paragraph.
class PrologueSentence {
  const PrologueSentence(this.text, this.bold, {required this.opensParagraph});

  final String text;
  final List<bool> bold;
  final bool opensParagraph;

  int get length => text.length;

  /// The sentence's runs (text, bold) cut after [chars] characters.
  List<({String text, bool bold})> runs([int? chars]) {
    final end = (chars ?? length).clamp(0, length);
    final out = <({String text, bool bold})>[];
    var from = 0;
    for (var i = 1; i <= end; i++) {
      if (i == end || bold[i] != bold[from]) {
        out.add((text: text.substring(from, i), bold: bold[from]));
        from = i;
      }
    }
    return out;
  }
}

final _sentenceEnd = RegExp(r'(?<=[.!?…])\s+');

/// [text] (a scene's narration, `**bold**` marked) cut into sentences, in
/// order, each knowing its bold characters.
List<PrologueSentence> prologueSentences(String text) {
  final out = <PrologueSentence>[];
  final paragraphs = storyBodyFor(text).split(RegExp(r'\n\s*\n'));
  for (final paragraph in paragraphs) {
    final plain = StringBuffer();
    final bold = <bool>[];
    var on = false;
    for (final part in paragraph.trim().split('**')) {
      for (final unit in part.runes) {
        plain.writeCharCode(unit);
        bold.add(on);
      }
      on = !on;
    }
    final all = plain.toString();
    var from = 0;
    var first = true;
    void add(int to) {
      if (to <= from) return;
      out.add(PrologueSentence(all.substring(from, to), bold.sublist(from, to),
          opensParagraph: first));
      first = false;
    }

    for (final m in _sentenceEnd.allMatches(all)) {
      add(m.start);
      from = m.end;
    }
    add(all.length);
  }
  return out;
}

/// When each sentence starts and ends, in seconds, and the whole length.
({List<double> starts, List<double> ends, double total}) prologueSchedule(
    List<PrologueSentence> sentences) {
  final starts = <double>[];
  final ends = <double>[];
  var t = 0.0;
  for (var i = 0; i < sentences.length; i++) {
    if (i > 0) t += sentences[i].opensParagraph ? _paragraphGap : _sentenceGap;
    starts.add(t);
    t += (sentences[i].length / _charsPerSecond).clamp(_minSentence, 60.0);
    ends.add(t);
  }
  return (starts: starts, ends: ends, total: t);
}

/// The characters of [s] shown [fraction] of the way through it: whole
/// words only, so the sentence is told word by word.
int prologueWordsShown(PrologueSentence s, double fraction) {
  if (fraction >= 1) return s.length;
  final reach = (fraction * s.length).floor();
  if (reach <= 0) return 0;
  final space = s.text.lastIndexOf(RegExp(r'\s'), reach - 1);
  return space < 0 ? 0 : space + 1;
}

class PrologueOpening extends StatefulWidget {
  const PrologueOpening({
    super.key,
    required this.text,
    required this.choices,
    this.told = false,
    this.onTold,
  });

  /// The text was told already (the page came back to): shown whole.
  final bool told;

  /// Called once, after a frame, when the text has been told (or was shown
  /// whole): the page's way back to the map waits for it.
  final VoidCallback? onTold;

  /// The scene's narration, `**bold**` marked.
  final String text;

  /// What the scene asks (the choice cards), shown once the text is told.
  final Widget choices;

  @override
  State<PrologueOpening> createState() => _PrologueOpeningState();
}

class _PrologueOpeningState extends State<PrologueOpening>
    with SingleTickerProviderStateMixin {
  late List<PrologueSentence> _sentences;
  late ({List<double> starts, List<double> ends, double total}) _plan;
  late final AnimationController _clock;
  bool _reduced = false;
  bool _started = false;
  bool _toldSent = false;
  DateTime? _lastTap;

  double get _length => _plan.total + _settleSeconds;

  /// Seconds into the whole animation.
  double get _now => _clock.value * _length;

  @override
  void initState() {
    super.initState();
    _prepare();
    _clock = AnimationController(vsync: this, duration: _duration());
  }

  Duration _duration() =>
      Duration(milliseconds: (_length * 1000).round().clamp(1, 1 << 30));

  void _prepare() {
    _sentences = prologueSentences(widget.text);
    _plan = prologueSchedule(_sentences);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_started) return;
    _started = true;
    if (_reduced || widget.told || _sentences.isEmpty) {
      _clock.value = 1;
    } else {
      _clock.forward();
    }
  }

  @override
  void didUpdateWidget(PrologueOpening old) {
    super.didUpdateWidget(old);
    if (old.text == widget.text) return;
    final ratio = _clock.value;
    _prepare();
    _clock.duration = _duration();
    _clock.value = ratio;
    if (ratio < 1) _clock.forward();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _jumpTo(double seconds) {
    _clock.forward(from: (seconds / _length).clamp(0.0, 1.0));
  }

  /// A tap finishes the sentence being told; a second one soon after jumps
  /// to the end.
  void _tap() {
    final s = _now;
    final total = _plan.total;
    if (s >= total || _sentences.isEmpty) return;
    final now = DateTime.now();
    final again = _lastTap != null && now.difference(_lastTap!) < _doubleTap;
    _lastTap = now;
    var k = 0;
    while (k + 1 < _sentences.length && _plan.starts[k + 1] <= s) {
      k++;
    }
    if (again || s >= _plan.ends[k]) {
      _jumpTo(total);
    } else {
      _jumpTo(_plan.ends[k]);
    }
  }

  double _sigilOpacity(double s) {
    final total = _plan.total;
    if (_reduced) return prologueSigilStill;
    if (s < total) {
      return prologueSigilPeak *
          ((s - (total - _sigilRise)) / _sigilRise).clamp(0.0, 1.0);
    }
    const held = _settleSeconds * 0.45;
    final out = ((s - total - held) / (_settleSeconds - held)).clamp(0.0, 1.0);
    return prologueSigilPeak * (1 - out);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final height = box.maxHeight.isFinite ? box.maxHeight : 600.0;
      final settledText = (height * 0.5).clamp(120.0, 360.0);
      final foldedHeight =
          settledText.clamp(80.0, (height - 120).clamp(80.0, height));
      return AnimatedBuilder(
        animation: _clock,
        builder: (context, _) {
          final s = _now;
          final total = _plan.total;
          if (s >= total && !_toldSent) {
            _toldSent = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onTold?.call();
            });
          }
          final settle = ((s - total) / _settleSeconds).clamp(0.0, 1.0);
          final fold =
              Curves.easeInOut.transform((settle / 0.45).clamp(0.0, 1.0));
          // The choice comes once the text has folded out of its way.
          final show =
              Curves.easeOut.transform(((settle - 0.35) / 0.4).clamp(0.0, 1.0));
          final done = s >= total;
          final textHeight = height + (foldedHeight - height) * fold;
          return Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Opacity(
                      key: const Key('prologue_sigil'),
                      opacity: _sigilOpacity(s),
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          0.33, 0.33, 0.33, 0, 40, //
                          0.33, 0.33, 0.33, 0, 40,
                          0.33, 0.33, 0.33, 0, 40,
                          0, 0, 0, 1, 0,
                        ]),
                        child: Image.asset(
                          prologueSigilAsset,
                          height: height * 0.62,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                          isAntiAlias: false,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: textHeight,
                child: GestureDetector(
                  key: const Key('prologue_text'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _tap,
                  child: _ToldText(
                    sentences: _sentences,
                    plan: _plan,
                    seconds: s,
                    fold: fold,
                    still: _reduced,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: !done,
                  child: Opacity(
                    key: const Key('prologue_choices'),
                    opacity: _reduced ? (done ? 1 : 0) : show,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: height * 0.4),
                      child: SingleChildScrollView(child: widget.choices),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

/// The sentences told so far, the newest in full and the older ones dimmer
/// the further back they are, the end of the column kept in view.
class _ToldText extends StatelessWidget {
  const _ToldText({
    required this.sentences,
    required this.plan,
    required this.seconds,
    required this.fold,
    required this.still,
  });

  final List<PrologueSentence> sentences;
  final ({List<double> starts, List<double> ends, double total}) plan;
  final double seconds;

  /// 0 while the text is told, 1 once it has folded above the choice.
  final double fold;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final base = theme.textTheme.bodyLarge?.copyWith(
          fontFamily: InkFonts.prose,
          fontSize: 19,
          height: 1.5,
          color: theme.colorScheme.onSurface,
        ) ??
        const TextStyle(fontSize: 19);
    var newest = -1;
    for (var i = 0; i < sentences.length; i++) {
      if (plan.starts[i] <= seconds) newest = i;
    }
    final children = <Widget>[];
    for (var i = 0; i <= newest; i++) {
      final s = sentences[i];
      final span = plan.ends[i] - plan.starts[i];
      final fraction = still || span <= 0
          ? 1.0
          : ((seconds - plan.starts[i]) / span).clamp(0.0, 1.0);
      final shown = prologueWordsShown(s, fraction);
      final back = newest - i;
      final dim = back == 0
          ? 1.0
          : back == 1
              ? 0.55
              : back == 2
                  ? 0.36
                  : 0.24;
      final opacity = still ? 1.0 : dim + (1 - dim) * fold;
      children.add(Padding(
        padding: EdgeInsets.only(top: i == 0 ? 0 : (s.opensParagraph ? 18 : 8)),
        child: Opacity(
          opacity: opacity,
          child: Text.rich(
            key: Key('prologue_sentence_$i'),
            TextSpan(children: [
              for (final run in s.runs(shown))
                TextSpan(
                    text: run.text,
                    style: run.bold
                        ? TextStyle(
                            fontWeight: FontWeight.w700, color: ink.gold)
                        : null),
              // The rest keeps its room, unseen, so the lines do not move.
              if (shown < s.length)
                TextSpan(
                    text: s.text.substring(shown),
                    style: const TextStyle(color: Colors.transparent)),
            ]),
            style: base,
          ),
        ),
      ));
    }
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
        stops: [0, 0.14],
      ).createShader(rect),
      child: LayoutBuilder(builder: (context, box) {
        return SingleChildScrollView(
          reverse: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        );
      }),
    );
  }
}
