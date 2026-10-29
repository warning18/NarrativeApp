// A walk inside a town, told in words (v1.537): a name in the middle of a
// sentence, and the doorway veil between a room and the streets.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/town_walk.dart';

void main() {
  test('a name loses its leading article\'s capital in a sentence', () {
    expect(townNameInSentence('The Stone Bridge'), 'the Stone Bridge');
    expect(townNameInSentence('Le Pont de Pierre'), 'le Pont de Pierre');
    expect(townNameInSentence('La Geôle Noire'), 'la Geôle Noire');
    expect(townNameInSentence('Les Souterrains'), 'les Souterrains');
    expect(townNameInSentence('L’Escalier Noyé'), 'l’Escalier Noyé');
    // No article, or only a word that starts like one.
    expect(townNameInSentence('Tern Row'), 'Tern Row');
    expect(townNameInSentence('Lantern Hall'), 'Lantern Hall');
    expect(townNameInSentence('The'), 'The');
    expect(townNameInSentence(' The Pool '), 'the Pool');
  });

  test('the veil is thick at the door and gone when the map is clear', () {
    expect(TownDoorVeil.opacityAt(0), closeTo(0.85, 1e-9));
    expect(TownDoorVeil.opacityAt(1), 0);
    expect(TownDoorVeil.opacityAt(0.5), lessThan(TownDoorVeil.opacityAt(0.2)));
  });

  testWidgets(
      'the veil shows on the way through, then clears, and is still '
      'with reduced motion', (tester) async {
    final clock = AnimationController(
        vsync: const TestVSync(), duration: const Duration(milliseconds: 500));
    addTearDown(clock.dispose);
    Widget veil({bool still = false}) => MaterialApp(
          home: SizedBox(
            width: 200,
            height: 200,
            child: TownDoorVeil(
                clock: clock,
                colour: Colors.black,
                icon: Icons.login,
                still: still),
          ),
        );
    const veilKey = ValueKey('town_door_veil');
    await tester.pumpWidget(veil());
    expect(find.byKey(veilKey), findsOneWidget);
    clock.value = 1;
    await tester.pump();
    expect(find.byKey(veilKey), findsNothing);
    clock.value = 0.2;
    await tester.pumpWidget(veil(still: true));
    expect(find.byKey(veilKey), findsNothing);
  });
}
