// The first-launch intro (v1.579, lib/screens/intro_screen.dart): four lines
// over eight beats, a tap skips, reduced motion shows the title over the die
// and then the last line, it is remembered once played, and Settings replays
// it.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/screens/intro_screen.dart';
import 'package:narrative_data_app/screens/settings_screen.dart';

String _line(int n) => trFor(AppLanguage.en, 'intro_line_$n');

/// A host that opens the intro on a button, so that its end (a pop) is seen.
Widget _host({bool reduced = false, ValueChanged<bool?>? onResult}) =>
    ProviderScope(
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open_intro'),
                onPressed: () async {
                  final r = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const IntroScreen()),
                  );
                  onResult?.call(r);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open_intro')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the four lines and the Settings row exist in both languages', () {
    for (final k in [
      for (var i = 1; i <= 4; i++) 'intro_line_$i',
      'intro_skip',
      'intro_replay_title',
      'intro_replay_desc',
    ]) {
      expect(trFor(AppLanguage.en, k), isNot(k), reason: k);
      expect(trFor(AppLanguage.fr, k), isNot(k), reason: k);
    }
  });

  test('the beats run in order inside the 15 seconds', () {
    expect(introBeatStarts.length, 8);
    for (var i = 1; i < introBeatStarts.length; i++) {
      expect(introBeatStarts[i], greaterThan(introBeatStarts[i - 1]));
    }
    expect(introBeatStarts.last, lessThan(introSeconds));
  });

  test('the seen flag is remembered', () async {
    expect(await introSeen(), isFalse);
    await markIntroSeen();
    expect(await introSeen(), isTrue);
  });

  testWidgets('the lines come in order, then it ends and is marked seen',
      (tester) async {
    bool? result;
    await tester.pumpWidget(_host(onResult: (r) => result = r));
    await _open(tester);
    expect(find.byKey(const Key('intro')), findsOneWidget);

    // Line 1 over the burning Shroud (the typewriter is off in tests).
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(_line(1)), findsOneWidget);
    expect(find.text(_line(2)), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text(_line(2)), findsOneWidget);
    expect(find.text(_line(1)), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text(_line(3)), findsOneWidget);

    // The last line comes in after the title, as it fades.
    await tester.pump(const Duration(seconds: 7));
    expect(find.text(_line(4)), findsOneWidget);
    expect(find.text(_line(3)), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('intro')), findsNothing);
    expect(result, isTrue);
    expect(await introSeen(), isTrue);
  });

  testWidgets('a tap goes to the last beat, a second tap ends it',
      (tester) async {
    bool? result;
    await tester.pumpWidget(_host(onResult: (r) => result = r));
    await _open(tester);
    expect(find.text(_line(4)), findsNothing);

    await tester.tap(find.byKey(const Key('intro_tap')));
    await tester.pump();
    // 350 ms to the last beat; its line starts writing 0.3 s into it.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(); // the clock goes on from there
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(_line(4)), findsOneWidget);
    expect(find.byKey(const Key('intro')), findsOneWidget);

    await tester.tap(find.byKey(const Key('intro_tap')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('intro')), findsNothing);
    expect(result, isTrue);
    expect(await introSeen(), isTrue);
  });

  testWidgets('with reduced motion: the title over the die, then line 4',
      (tester) async {
    bool? result;
    await tester.pumpWidget(_host(reduced: true, onResult: (r) => result = r));
    await _open(tester);
    // The still frame: no line yet, nothing moving to wait for.
    expect(find.text(_line(1)), findsNothing);
    expect(find.text(_line(4)), findsNothing);

    await tester.pump(const Duration(milliseconds: 2800));
    expect(find.text(_line(4)), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('intro')), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('Settings has a row that plays the intro again', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SettingsScreen())));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    final row = find.byKey(const Key('intro_replay'), skipOffstage: false);
    await tester.scrollUntilVisible(row, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(row);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('intro')), findsOneWidget);
  });
}
