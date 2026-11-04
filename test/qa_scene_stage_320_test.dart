// QA guard (#688): on a 320 px stage the door tab hangs under the foe's name
// and stays inside the stage.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/scene_stage.dart';

void main() {
  testWidgets('320 px: the door does not cover the foe name', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: SceneStage(
            foeId: 'slum_thug',
            foeName: 'Slum thug',
            prompt: 'What do you do?',
            doorName: 'The Drowned Stair of the Ashen Quarter',
            doorLit: true,
          ),
        ),
      ),
    ));
    final door = tester.getRect(find.byKey(const Key('scene_stage_door')));
    final name = tester.getRect(find.byKey(const Key('scene_stage_foe')));
    final stage = tester.getRect(find.byKey(const Key('scene_stage')));
    expect(door.overlaps(name), isFalse);
    expect(stage.contains(door.topLeft) && stage.contains(door.bottomRight),
        isTrue);
    expect(tester.takeException(), isNull);
  });
}
