// The app's one waiting state (v1.892, lib/widgets/ink_loading.dart): a ring
// around the lantern, a quiet line only after two seconds, and no bare
// CircularProgressIndicator() left in the screens.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/ink_loading.dart';

void main() {
  testWidgets('the ring shows at once, the line only after two seconds',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: Scaffold(body: InkLoading()))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    double opacity() => tester
        .widget<AnimatedOpacity>(find.byType(AnimatedOpacity))
        .opacity;
    expect(opacity(), 0);
    await tester.pump(const Duration(milliseconds: 1900));
    expect(opacity(), 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacity(), 1);
    // Nothing is left pending once the page goes.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  test('no screen draws a bare CircularProgressIndicator()', () {
    final bare = RegExp(r'CircularProgressIndicator\(\s*\)');
    final found = <String>[];
    for (final file in Directory('lib/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      if (bare.hasMatch(file.readAsStringSync())) found.add(file.path);
    }
    expect(found, isEmpty,
        reason: 'use InkLoading (lib/widgets/ink_loading.dart): $found');
  });
}
