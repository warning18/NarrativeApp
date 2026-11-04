// The slow-frames meter (v1.765): counts the frames that took too long, per
// screen, so someone with only the phone can say what stutters. It does
// nothing until started: no callback, no timer. Flutter's frame timings are
// there in a release build too.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// What the Journey is showing ('reading page' or 'map'), set by the Journey
/// while it is on screen so the report can tell the two apart; null otherwise.
/// A plain variable: writing it costs nothing and nothing listens to it.
String? slowFrameHint;

/// A frame is slow when it took longer than this, in milliseconds (one frame
/// at 60 Hz is 16.7).
const double slowFrameMs = 17;

/// How many of the worst frames the report lists.
const int worstFramesListed = 5;

/// What one screen drew: its frames, how many were slow, the longest.
class SlowFrameStat {
  int frames = 0;
  int slow = 0;
  double worstMs = 0;
}

/// One slow frame, kept for the report: where it was, its total and the two
/// halves of it (the UI thread's build and the raster thread's drawing).
class SlowFrame {
  const SlowFrame(this.screen, this.totalMs, this.buildMs, this.rasterMs);

  final String screen;
  final double totalMs;
  final double buildMs;
  final double rasterMs;
}

class SlowFrameMeter {
  SlowFrameMeter({required this.screen});

  /// The name of the screen being played, asked when a batch of frames
  /// arrives.
  final String Function() screen;

  /// Per screen, in the order each was first seen.
  final Map<String, SlowFrameStat> stats = {};

  /// The slowest frames, worst first.
  final List<SlowFrame> worst = [];

  /// Bumped (at most twice a second, and only when something changed) so a
  /// counter on screen can follow without being a frame cost of its own.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  bool _running = false;
  bool _dirty = false;
  Timer? _publish;

  bool get running => _running;

  /// Starts counting; a second call does nothing.
  void start() {
    if (_running) return;
    _running = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _publish =
        Timer.periodic(const Duration(milliseconds: 500), (_) => _flush());
  }

  /// Stops counting and lets go of everything it held; what was counted stays
  /// until [reset].
  void stop() {
    if (!_running) return;
    _running = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _publish?.cancel();
    _publish = null;
  }

  void reset() {
    stats.clear();
    worst.clear();
    _dirty = false;
    changes.value++;
  }

  void _flush() {
    if (!_dirty) return;
    _dirty = false;
    changes.value++;
  }

  void _onTimings(List<ui.FrameTiming> timings) {
    final label = screen();
    for (final timing in timings) {
      addFrame(
        label,
        totalMs: timing.totalSpan.inMicroseconds / 1000,
        buildMs: timing.buildDuration.inMicroseconds / 1000,
        rasterMs: timing.rasterDuration.inMicroseconds / 1000,
      );
    }
  }

  /// Counts one frame of [label] (the timings callback's work, apart so a test
  /// can feed it).
  void addFrame(String label,
      {required double totalMs,
      required double buildMs,
      required double rasterMs}) {
    final stat = stats.putIfAbsent(label, SlowFrameStat.new);
    stat.frames++;
    if (totalMs > stat.worstMs) stat.worstMs = totalMs;
    if (totalMs > slowFrameMs) {
      stat.slow++;
      worst.add(SlowFrame(label, totalMs, buildMs, rasterMs));
      worst.sort((a, b) => b.totalMs.compareTo(a.totalMs));
      if (worst.length > worstFramesListed) worst.removeLast();
    }
    _dirty = true;
  }

  /// The words to paste to the team: the numbers per screen, then the worst
  /// frames with the two halves of each. [device] is a line about the phone
  /// and the build (the version, the system, the screen).
  String report({required String device}) {
    final buffer = StringBuffer()
      ..writeln('Slow frames (over ${slowFrameMs.round()} ms) / frames drawn')
      ..writeln(device)
      ..writeln();
    if (stats.isEmpty) {
      buffer.writeln('Nothing counted yet.');
    }
    for (final entry in stats.entries) {
      final s = entry.value;
      buffer.write('${entry.key}: ${s.slow} / ${s.frames}');
      if (s.slow > 0) {
        buffer.write(', worst ${s.worstMs.toStringAsFixed(0)} ms');
      }
      buffer.writeln();
    }
    if (worst.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Worst frames: total = build + raster (ms), where');
      for (final frame in worst) {
        buffer.writeln('${frame.totalMs.toStringAsFixed(1)} total = '
            '${frame.buildMs.toStringAsFixed(1)} build + '
            '${frame.rasterMs.toStringAsFixed(1)} raster, ${frame.screen}');
      }
    }
    return buffer.toString().trimRight();
  }
}
