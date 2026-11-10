// The shared palette (v1.885, lib/theme/palette.dart): the values are the
// ones the game always drew with, the theme's tokens come from it, and a colour
// that two files draw with lives there, not in a literal of its own.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/palette.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

void main() {
  test('the role colours are the Material colours they stand for', () {
    expect(Palette.good, Colors.green);
    expect(Palette.goodDeep, Colors.green.shade700);
    expect(Palette.goodStrong, Colors.green.shade600);
    expect(Palette.amberDeep, Colors.amber.shade800);
    expect(Palette.goldDeep, Colors.amber.shade700);
    expect(Palette.danger, Colors.red.shade700);
    expect(Palette.alert, Colors.red);
    expect(Palette.hot, Colors.deepOrange);
    expect(Palette.arcane, Colors.deepPurple);
  });

  test('the theme tokens are the palette tokens', () {
    expect(InkColors.dark.gold, Palette.goldDark);
    expect(InkColors.light.gold, Palette.goldLight);
    expect(InkColors.dark.seam, Palette.seamDark);
    expect(InkColors.light.ash, Palette.ashLight);
  });

  test('no colour two files draw with is written as a literal', () {
    final literal = RegExp(r'Color\(0x([0-9A-Fa-f]{8})\)');
    final files = <String, Set<String>>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('theme/palette.dart')) continue;
      for (final m in literal.allMatches(f.readAsStringSync())) {
        files.putIfAbsent(m.group(1)!.toUpperCase(), () => {}).add(f.path);
      }
    }
    final shared = {
      for (final e in files.entries)
        if (e.value.length >= 2) '0x${e.key}': e.value.length
    };
    expect(shared, isEmpty,
        reason: 'these colours are drawn in 2+ files: add them to '
            'lib/theme/palette.dart and use the name');
  });
}
