// The icon scale (v1.905, lib/theme/icon_sizes.dart): an Icon or a pixel icon
// asked for with a number in lib/ takes a size of the scale (IconSize.inline,
// s16, s32, s48, s64) or a whole multiple of 16 above that; never 14, 18, 20,
// 22, 26, 28... so a 16-pixel icon is never drawn at 1.4x or 1.75x.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/icon_sizes.dart';

final _ctor = RegExp(
    r'\b(Icon|PixelIcon|SkillPixelIcon|ItemPixelIcon|EnemyPixelIcon|ShopPixelIcon)\(');

int _closing(String s, int open) {
  var depth = 0;
  for (var i = open; i < s.length; i++) {
    if (s[i] == '(') depth++;
    if (s[i] == ')' && --depth == 0) return i;
  }
  return -1;
}

void main() {
  test('the scale', () {
    expect(IconSize.snap(18), IconSize.s16);
    expect(IconSize.snap(20), IconSize.s16);
    expect(IconSize.snap(26), IconSize.s32);
    expect(IconSize.snap(44), IconSize.s48);
    expect(IconSize.snap(12), IconSize.inline);
  });

  test('no icon in lib/ is asked for with a size off the scale', () {
    final off = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final s = f.readAsStringSync();
      for (final m in _ctor.allMatches(s)) {
        final end = _closing(s, m.end - 1);
        if (end < 0) continue;
        final body = s.substring(m.end, end);
        var depth = 0;
        for (var k = 0; k < body.length; k++) {
          final c = body[k];
          if ('([{'.contains(c)) depth++;
          if (')]}'.contains(c)) depth--;
          if (depth == 0 &&
              body.startsWith('size:', k) &&
              (k == 0 || !RegExp('[A-Za-z]').hasMatch(body[k - 1]))) {
            final n = RegExp(r'size:\s*([0-9]+(?:\.[0-9]+)?)\s*(?:[,)\n]|$)')
                .matchAsPrefix(body, k);
            if (n != null) {
              final v = double.parse(n.group(1)!);
              final ok =
                  v == 12 || v == 16 || v == 32 || (v >= 48 && v % 16 == 0);
              if (!ok) off.add('${f.path}: ${m.group(1)}(size: $v)');
            }
            break;
          }
        }
      }
    }
    expect(off, isEmpty, reason: off.join('\n'));
  });
}
