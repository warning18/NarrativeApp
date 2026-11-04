// QA guard: no merge-conflict marker is committed anywhere in the repository.
//
// A slip reached main in #815: tool/gen_skill_glyphs.py kept the lines
// "<<<<<<< HEAD", "=======" and ">>>>>>> origin/main". The app and CI never run
// that script, so nothing failed; the markers sat there. The merge checks of
// the sessions looked at lib/, test/, CHANGELOG.md and pubspec.yaml only.
//
// This reads every tracked text file (git ls-files; binaries are skipped by
// extension and by a NUL byte in the first 8 KB) and names the file and line
// of: a line that starts with seven "<" and a space, a line that starts with
// seven ">" and a space, and a line that is exactly seven "=" when the same
// file also has an opening marker (a markdown table rule or an rst underline
// is seven "=" or more on its own and is let through).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The markers, built here so this file does not hold one itself.
final _open = '${'<' * 7} ';
final _close = '${'>' * 7} ';
final _middle = '=' * 7;

const _binary = {
  'png', 'jpg', 'jpeg', 'webp', 'gif', 'ico', 'bmp', 'pdf', 'ttf', 'otf',
  'woff', 'woff2', 'jar', 'zip', 'gz', 'keystore', 'jks', 'mp3', 'ogg',
  'wav', 'mp4', 'webm', 'so', 'a', 'dylib', 'bin', 'dat', 'db', 'sqlite',
  //
};

List<String> _trackedFiles() {
  final result =
      Process.runSync('git', ['ls-files', '-z'], stdoutEncoding: utf8);
  if (result.exitCode != 0) {
    fail('git ls-files failed (${result.exitCode}): ${result.stderr}');
  }
  return (result.stdout as String)
      .split('\u0000')
      .where((p) => p.isNotEmpty)
      .toList();
}

bool _isBinary(String path, List<int> head) {
  final dot = path.lastIndexOf('.');
  final ext = dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
  return _binary.contains(ext) || head.contains(0);
}

/// "file:line: text" for each marker found in [path], or nothing.
List<String> markersIn(String path, List<int> bytes) {
  if (_isBinary(path, bytes.take(8192).toList())) return const [];
  final lines =
      const LineSplitter().convert(utf8.decode(bytes, allowMalformed: true));
  final found = <(int, String)>[];
  var hasOpen = false;
  final middles = <int>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith(_open) || line == _open.trimRight()) {
      hasOpen = true;
      found.add((i, '$path:${i + 1}: $line'));
    } else if (line.startsWith(_close) || line == _close.trimRight()) {
      found.add((i, '$path:${i + 1}: $line'));
    } else if (line == _middle) {
      middles.add(i);
    }
  }
  if (hasOpen) {
    for (final i in middles) {
      found.add((i, '$path:${i + 1}: $_middle'));
    }
  }
  found.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final f in found) f.$2];
}

void main() {
  test('no conflict marker in any tracked file', () {
    final files = _trackedFiles();
    expect(files.length, greaterThan(500), reason: 'the repo is listed');
    final found = <String>[];
    for (final path in files) {
      final file = File(path);
      if (!file.existsSync()) continue; // deleted in the working tree
      found.addAll(markersIn(path, file.readAsBytesSync()));
    }
    expect(found, isEmpty,
        reason: 'Conflict markers were committed. Resolve them, keeping both '
            'sides\' work:\n${found.join('\n')}');
  });

  test('the checker sees markers and lets table rules through', () {
    List<String> check(String text) => markersIn('x.md', utf8.encode(text));
    expect(check('a\n${'<' * 7} HEAD\nb\n$_middle\n${'>' * 7} origin/main\n'), [
      'x.md:2: ${'<' * 7} HEAD',
      'x.md:4: $_middle',
      'x.md:5: ${'>' * 7} origin/main'
    ]);
    // A rule or an underline alone is not a conflict.
    expect(check('Title\n$_middle\n\n| a |\n|=======|\n'), isEmpty);
    // A longer run of "<" or "=" is not a marker.
    expect(check('${'<' * 8} no\n${'=' * 9}\n'), isEmpty);
    // A bare opening marker line (no label) is one.
    expect(check('${'<' * 7}\n'), ['x.md:1: ${'<' * 7}']);
    // A binary file is not read.
    expect(
        markersIn('a.png', [0, 1, 2, ...utf8.encode('${'<' * 7} x')]), isEmpty);
  });
}
