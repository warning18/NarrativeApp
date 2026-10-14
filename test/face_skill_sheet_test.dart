// The face's skill sheet (board 9): each skill with the face now and the face
// after, the change as a pill; a tap lights a row and a bar offers "Set on this
// face"; a skill at its limit is dimmed and says "full"; nothing is set until
// the button is pressed.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/face_skill_sheet.dart';

FaceSkillOption _option(String id, FaceChange change,
        {bool allowed = true, String limit = 'on 0/2 faces'}) =>
    FaceSkillOption(
      id: id,
      name: 'Skill $id',
      icon: Icons.bolt,
      iconColour: Colors.red,
      rarityLabel: 'Common',
      rarityColour: Colors.grey,
      change: change,
      limitLine: limit,
      allowed: allowed,
    );

void main() {
  Future<List<String>> open(WidgetTester tester,
      {String? currentId, bool withReset = false}) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final log = <String>[];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(ColorScheme.fromSeed(
            seedColor: Colors.amber, brightness: Brightness.dark)),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showFaceSkillSheet(
                context,
                nowLine: 'Face 3 · now: Attack 5',
                note: 'The 70% rule.',
                currentId: currentId,
                options: [
                  _option(
                      'a',
                      const FaceChange(
                          before: 'Attack 5',
                          after: 'Attack 7 · Water',
                          kind: FaceChangeKind.gain,
                          delta: 2)),
                  _option(
                      'b',
                      const FaceChange(
                          before: 'Attack 5',
                          after: 'Mana +2 · Light',
                          kind: FaceChangeKind.kind)),
                  _option(
                      'c',
                      const FaceChange(
                          before: 'Attack 5',
                          after: 'Attack 12 · Fire',
                          kind: FaceChangeKind.gain,
                          delta: 7),
                      allowed: false,
                      limit: 'already on 1 faces of this die'),
                ],
                onSet: (id) => log.add('set $id'),
                onClear: withReset ? () => log.add('clear') : null,
                clearSubtitle: 'Attack 5',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    return log;
  }

  testWidgets('each skill says the face before and after, with its pill',
      (tester) async {
    await open(tester);
    expect(find.byKey(const Key('face_now')), findsOneWidget);
    expect(find.text('Attack 5 → Attack 7 · Water'), findsOneWidget);
    expect(find.text('Attack 5 → Mana +2 · Light'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('changes kind'), findsOneWidget);
    // The skill at its limit is dimmed and says it is full.
    expect(find.text('full'), findsOneWidget);
    expect(
        tester.widget<ListTile>(find.byKey(const Key('pick_skill_c'))).enabled,
        isFalse);
    expect(find.byKey(const Key('face_set_bar')), findsNothing);
  });

  testWidgets('a tap lights a row; nothing is set until the button is pressed',
      (tester) async {
    final log = await open(tester);
    await tester.tap(find.byKey(const Key('pick_skill_a')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('face_set_bar')), findsOneWidget);
    expect(log, isEmpty);

    // Tapping down the list compares: the bar follows, Cancel puts it away.
    await tester.tap(find.byKey(const Key('pick_skill_b')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        find.descendant(
            of: find.byKey(const Key('face_set_bar')),
            matching: find.text('Attack 5 → Mana +2 · Light')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('face_set_cancel')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('face_set_bar')), findsNothing);

    await tester.tap(find.byKey(const Key('pick_skill_a')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('face_set_button')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(log, ['set a']);
    expect(find.byKey(const Key('face_set_bar')), findsNothing,
        reason: 'the sheet closed');
  });

  testWidgets('the skill already on the face has no bar, the reset is offered',
      (tester) async {
    final log = await open(tester, currentId: 'a', withReset: true);
    await tester.tap(find.byKey(const Key('pick_skill_a')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('face_set_bar')), findsNothing);
    await tester.tap(find.byKey(const Key('face_reset')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(log, ['clear']);
  });
}
