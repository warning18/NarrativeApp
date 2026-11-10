// The frames of the look (v1.901, lib/theme/ink_frames.dart): the A panel's
// double ink line, the C button's bevel, and the corner tokens they keep.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/ink_frames.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/ink_panel.dart';

Widget _app(Widget child, {Brightness brightness = Brightness.dark}) =>
    MaterialApp(
      theme: buildAppTheme(brightness == Brightness.dark
          ? const ColorScheme.dark()
          : const ColorScheme.light()),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('an InkPanel is a double ink line, gold inside when lit',
      (tester) async {
    await tester.pumpWidget(_app(const Column(children: [
      InkPanel(key: Key('plain'), child: Text('a')),
      InkPanel(key: Key('lit'), lit: true, child: Text('b')),
    ])));
    InkPanelBorder shapeOf(String key) {
      final box = tester.widget<Container>(find
          .descendant(
              of: find.byKey(Key(key)), matching: find.byType(Container))
          .first);
      return (box.decoration! as ShapeDecoration).shape as InkPanelBorder;
    }

    expect(shapeOf('plain').radius, 10, reason: 'the 10 dp corner token');
    expect(shapeOf('plain').outer, inkOutlineDark);
    expect(shapeOf('lit').inner, isNot(shapeOf('plain').inner));
  });

  testWidgets('the buttons are bevel frames, flat when disabled, pressed swaps',
      (tester) async {
    await tester.pumpWidget(_app(Column(children: [
      FilledButton(
          key: const Key('on'), onPressed: () {}, child: const Text('Go')),
      const FilledButton(key: Key('off'), onPressed: null, child: Text('No')),
    ])));
    OutlinedBorder? shape(String key, Set<WidgetState> states) {
      final style = tester.widget<FilledButton>(find.byKey(Key(key))).style ??
          Theme.of(tester.element(find.byKey(Key(key))))
              .filledButtonTheme
              .style;
      final theme = Theme.of(tester.element(find.byKey(Key(key))))
          .filledButtonTheme
          .style!;
      return (style ?? theme).shape!.resolve(states);
    }

    final normal = shape('on', {}) as InkButtonBorder;
    expect(normal.radius, 4, reason: 'the 4 dp corner token');
    expect(normal.flat, isFalse);
    expect(normal.pressed, isFalse);
    expect((shape('on', {WidgetState.pressed}) as InkButtonBorder).pressed,
        isTrue);
    expect(
        (shape('off', {WidgetState.disabled}) as InkButtonBorder).flat, isTrue);
  });

  testWidgets('the parchment theme uses the parchment ink', (tester) async {
    await tester.pumpWidget(_app(
        const InkPanel(key: Key('p'), child: Text('x')),
        brightness: Brightness.light));
    final box = tester.widget<Container>(find
        .descendant(
            of: find.byKey(const Key('p')), matching: find.byType(Container))
        .first);
    expect(((box.decoration! as ShapeDecoration).shape as InkPanelBorder).outer,
        inkOutlineParchment);
  });
}
