// The fonts were cut to the letters the game uses (v1.868,
// tool/subset_fonts.py). Every character the texts draw that a font had must
// still be in it, or the engine falls back to the system font for it: a
// letter in another face in the middle of a word.
//
// A failure here means a new character came into a text: run
// `python3 tool/subset_fonts.py --src DIR` with the full fonts (the files of
// commit 60522342e, `git show 60522342e:assets/fonts/NAME.ttf`) and commit
// what it writes.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// The code points of a TrueType font's best cmap (formats 4 and 12).
Set<int> _cmap(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final tables = data.getUint16(4);
  var cmapAt = -1;
  for (var i = 0; i < tables; i++) {
    final at = 12 + i * 16;
    if (String.fromCharCodes(bytes.sublist(at, at + 4)) == 'cmap') {
      cmapAt = data.getUint32(at + 8);
    }
  }
  expect(cmapAt, isNonNegative, reason: 'no cmap table');
  final out = <int>{};
  final count = data.getUint16(cmapAt + 2);
  for (var i = 0; i < count; i++) {
    final platform = data.getUint16(cmapAt + 4 + i * 8);
    final encoding = data.getUint16(cmapAt + 4 + i * 8 + 2);
    final sub = cmapAt + data.getUint32(cmapAt + 4 + i * 8 + 4);
    final unicode =
        platform == 0 || (platform == 3 && (encoding == 1 || encoding == 10));
    if (!unicode) continue;
    final format = data.getUint16(sub);
    if (format == 4) {
      final segs = data.getUint16(sub + 6) ~/ 2;
      final ends = sub + 14;
      final starts = ends + segs * 2 + 2;
      final deltas = starts + segs * 2;
      final offsets = deltas + segs * 2;
      for (var s = 0; s < segs; s++) {
        final end = data.getUint16(ends + s * 2);
        final start = data.getUint16(starts + s * 2);
        if (start == 0xFFFF) continue;
        for (var c = start; c <= end; c++) {
          final ro = data.getUint16(offsets + s * 2);
          if (ro == 0) {
            if (((c + data.getInt16(deltas + s * 2)) & 0xFFFF) != 0) out.add(c);
          } else {
            final g = offsets + s * 2 + ro + (c - start) * 2;
            if (g + 2 <= bytes.length && data.getUint16(g) != 0) out.add(c);
          }
        }
      }
    } else if (format == 12) {
      final groups = data.getUint32(sub + 12);
      for (var g = 0; g < groups; g++) {
        final at = sub + 16 + g * 12;
        for (var c = data.getUint32(at); c <= data.getUint32(at + 4); c++) {
          out.add(c);
        }
      }
    }
  }
  return out;
}

Set<int> _usedChars() {
  final chars = <int>{};
  void read(File f) {
    try {
      chars.addAll(f.readAsStringSync().runes);
    } on FormatException {
      // not text
    }
  }

  for (final f in Directory('assets/gamedata').listSync().whereType<File>()) {
    if (f.path.endsWith('.json')) read(f);
  }
  read(File('assets/Cleaned_Narrative_DAG.json'));
  for (final f
      in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (f.path.endsWith('.dart')) read(f);
  }
  return chars.where((c) => c >= 0x20 && c != 0x7F).toSet();
}

void main() {
  final manifest =
      jsonDecode(File('assets/fonts/GLYPHS.json').readAsStringSync())
          as Map<String, dynamic>;
  final used = _usedChars();

  for (final entry in manifest.entries) {
    test('${entry.key} keeps every character the texts use', () {
      final cmap = _cmap(File('assets/fonts/${entry.key}').readAsBytesSync());
      final absent = {
        for (final h in (entry.value['absent_in_source'] as List))
          int.parse(h as String, radix: 16)
      };
      final lost = [
        for (final c in used)
          if (!absent.contains(c) && !cmap.contains(c)) c
      ];
      expect(
          lost
              .map((c) => 'U+${c.toRadixString(16).toUpperCase()} '
                  '${String.fromCharCode(c)}')
              .toList(),
          isEmpty,
          reason: 'cut by the subset: run tool/subset_fonts.py again');
    });

    test('${entry.key} still has the French and English letters', () {
      final cmap = _cmap(File('assets/fonts/${entry.key}').readAsBytesSync());
      const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
          '0123456789 .,;:!?\'"()-+/%&*';
      const french = 'àâäçéèêëîïôöùûüÿÀÂÇÉÈÊËÎÏÔÙÛÜ«»';
      for (final c in (letters + french).runes) {
        expect(cmap.contains(c), isTrue,
            reason: 'U+${c.toRadixString(16)} ${String.fromCharCode(c)}');
      }
    });
  }
}
