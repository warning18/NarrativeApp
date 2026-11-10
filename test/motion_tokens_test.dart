// The interface's transitions keep to three paces (v1.886,
// lib/theme/motion.dart): the implicit animations (a fade, a switch, a resize)
// take their duration from Motion, not from a number of their own.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/motion.dart';

void main() {
  test('the three paces are ordered and fixed', () {
    expect(Motion.fast < Motion.base, isTrue);
    expect(Motion.base < Motion.slow, isTrue);
    expect(Motion.fast.inMilliseconds, 160);
    expect(Motion.base.inMilliseconds, 240);
    expect(Motion.slow.inMilliseconds, 400);
  });

  test('an implicit animation does not carry a duration of its own', () {
    final implicit = RegExp(
        'Animated(Opacity|Switcher|Container|Rotation|Positioned|Size|Align|'
        r'Padding|Scale|Slide|CrossFade|DefaultTextStyle)\(\s*'
        r'(?:[^()]|\([^()]*\))*?duration:\s*(?:const\s+)?Duration\(milliseconds:\s*(\d+)\)',
        multiLine: true);
    final own = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('theme/motion.dart')) continue;
      for (final m in implicit.allMatches(f.readAsStringSync())) {
        // Over half a second is a reveal, a choreography: its own timing.
        if (int.parse(m.group(2)!) <= 520) own.add('${f.path}: ${m.group(1)}');
      }
    }
    expect(own, isEmpty,
        reason: 'use Motion.fast / base / slow for a UI transition');
  });
}
