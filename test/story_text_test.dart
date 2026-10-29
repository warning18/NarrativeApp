// The story text on screen (lib/widgets/story_text.dart): paragraphs, bold,
// names in their colours, and the typewriter: it writes the text out, a tap
// shows it all (and says it is done, so the choices can come), a scene read
// before is shown at once, and so is everything with reduced motion.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/story_markup.dart';
import 'package:narrative_data_app/providers/story_text_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/story_text.dart';
import 'support/pump.dart';

const _text =
    'Aurel Vane held **forty crowns** for the Lantern Dominion.\n\nIn Saltmouth, nobody asked why.';

ProviderContainer _container() => ProviderContainer(overrides: [
      storyNameMatcherProvider.overrideWith((ref, french) => StoryNameMatcher({
            'Aurel Vane': StoryNameKind.person,
            'Saltmouth': StoryNameKind.place,
            'Lantern Dominion': StoryNameKind.clan,
          })),
    ]);

Widget _app(String? key,
        {String text = _text, required ProviderContainer container}) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(ColorScheme.fromSeed(seedColor: Colors.brown)),
        home: Scaffold(
          body: SingleChildScrollView(
            child: StoryText(
              text: text,
              style: const TextStyle(fontSize: 17),
              revealKey: key,
              firstSentenceBold: false,
            ),
          ),
        ),
      ),
    );

/// The spans of the story text, with their colours.
List<TextSpan> _spans(WidgetTester tester) {
  final out = <TextSpan>[];
  for (final r in tester.widgetList<RichText>(find.descendant(
      of: find.byType(StoryText), matching: find.byType(RichText)))) {
    r.text.visitChildren((s) {
      if (s is TextSpan && s.text != null) out.add(s);
      return true;
    });
  }
  return out;
}

bool _hidden(TextSpan s) => s.style?.color == Colors.transparent;

void main() {
  testWidgets('paragraphs, bold facts and the names in their colours',
      (tester) async {
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(null, container: c));
    final ink = InkColors.of(tester.element(find.byType(StoryText)));
    // Two paragraphs, a gap between them.
    expect(
        find.descendant(
            of: find.byType(StoryText), matching: find.byType(RichText)),
        findsNWidgets(2));
    final spans = _spans(tester);
    TextSpan span(String text) => spans.firstWhere((s) => s.text == text);
    expect(span('forty crowns').style?.fontWeight, FontWeight.w700);
    expect(span('Aurel Vane').style?.color,
        storyNameColor(StoryNameKind.person, ink));
    expect(span('Saltmouth').style?.color,
        storyNameColor(StoryNameKind.place, ink));
    expect(span('Lantern Dominion').style?.color,
        storyNameColor(StoryNameKind.clan, ink));
    // One colour for each kind, and none the same as another.
    expect({
      for (final k in StoryNameKind.values) storyNameColor(k, ink),
    }, hasLength(3));
    // No sign of the markup, and nothing hidden.
    expect(spans.map((s) => s.text).join(), isNot(contains('**')));
    expect(spans.any(_hidden), isFalse);
  });

  testWidgets('the typewriter writes the text out; a tap shows it all',
      (tester) async {
    storyTypewriterOn = true;
    addTearDown(() => storyTypewriterOn = false);
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(_app('scene-1', container: container));
    // Under way: part of it written, the rest there for the layout but not
    // seen, and the scene not done.
    await tester.pump(const Duration(milliseconds: 150));
    expect(_spans(tester).any(_hidden), isTrue);
    expect(_spans(tester).any((s) => !_hidden(s)), isTrue);
    expect(container.read(storyTextDoneProvider), isEmpty);

    // One tap shows it all, and says it is done.
    await tester.tap(find.byType(StoryText));
    await tester.pump();
    await tester.pump();
    expect(_spans(tester).any(_hidden), isFalse);
    expect(container.read(storyTextDoneProvider), contains('scene-1'));

    // Shown again under the same key: at once.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app('scene-1', container: container));
    expect(_spans(tester).any(_hidden), isFalse);

    // A new scene types again, and runs out by itself.
    await tester.pumpWidget(_app('scene-2', container: container));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_spans(tester).any(_hidden), isTrue);
    await tester.pump(const Duration(seconds: 5));
    expect(_spans(tester).any(_hidden), isFalse);
    expect(container.read(storyTextDoneProvider), contains('scene-2'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a Continue pressed too early shows the rest first',
      (tester) async {
    storyTypewriterOn = true;
    addTearDown(() => storyTypewriterOn = false);
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(_app('scene-3', container: container));
    await tester.pump(const Duration(milliseconds: 150));
    expect(_spans(tester).any(_hidden), isTrue);
    container.read(storyTextSkipProvider.notifier).state++;
    await tester.pump();
    await tester.pump();
    expect(_spans(tester).any(_hidden), isFalse);
    expect(container.read(storyTextDoneProvider), contains('scene-3'));
  });

  testWidgets('reduced motion shows the text at once', (tester) async {
    storyTypewriterOn = true;
    addTearDown(() => storyTypewriterOn = false);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(_app('scene-4', container: container));
    expect(_spans(tester).any(_hidden), isFalse);
    await tester.pump();
    expect(container.read(storyTextDoneProvider), contains('scene-4'));
  });

  // Not a check: the picture the author looks at (UX_SHOTS=<folder>), with
  // the app's own fonts, the text half written and then whole.
  testWidgets('picture', (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    for (final (family, files) in [
      ('PixelifySans', ['PixelifySans-Regular.ttf']),
      (
        'Spectral',
        ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
      ),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(Future.value(
            ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
      }
      await loader.load();
    }
    storyTypewriterOn = true;
    addTearDown(() => storyTypewriterOn = false);
    usePhone(tester, const Size(360, 520));
    const long =
        'The Eel came into **Saltmouth** on the evening tide, and **Aurel Vane** was waiting on the quay with the Lantern Dominion\'s seal.\n\nHe owed the crew **forty crowns** and a **debt of silence**. Nobody on the wharf asked which was worse.\n\n"Come ashore," he said. "Before the **third bell**."';
    final key = GlobalKey();
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          theme: buildAppTheme(ColorScheme.fromSeed(seedColor: Colors.brown)),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(18),
              child: StoryText(
                text: long,
                style: TextStyle(
                    fontFamily: 'Spectral', fontSize: 17, height: 1.55),
                revealKey: 'shot',
                firstSentenceBold: false,
              ),
            ),
          ),
        ),
      ),
    ));
    Future<void> save(String name) => tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        });
    await tester.pump(const Duration(milliseconds: 500));
    await save('story-text-writing');
    await tester.pump(const Duration(seconds: 5));
    await save('story-text-done');
  });
}
