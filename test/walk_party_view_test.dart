import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/providers/walking_party_provider.dart';
import 'package:narrative_data_app/widgets/side_view/desert_kit.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';

void main() {
  test('the hero stands at the head, companions behind it', () {
    expect(walkingPartyXs(1), [walkHeroX]);
    final three = walkingPartyXs(3);
    expect(three.first, walkHeroX);
    expect(three[1], lessThan(three[0]));
    expect(three[2], lessThan(three[1]));
  });

  test('only the hero has walking frames for now', () {
    expect(hasWalkSprite('hero'), isTrue);
    expect(hasWalkSprite('companion_mira'), isFalse);
  });

  test('a companion keeps its cloak colour', () {
    expect(walkPlaceholderColour('mira'), walkPlaceholderColour('mira'));
  });

  testWidgets('the party draws alone, with companions, moving or waiting',
      (tester) async {
    const alone = [WalkingPartyMember(id: heroWalkerId, spriteKey: 'hero')];
    const three = [
      WalkingPartyMember(id: heroWalkerId, spriteKey: 'hero'),
      WalkingPartyMember(id: 'mira', spriteKey: 'companion_mira'),
      WalkingPartyMember(id: 'oren', spriteKey: 'companion_oren'),
    ];
    for (final party in [alone, three]) {
      for (final moving in [true, false]) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SideViewScene(
              layers: desertLayers(progress: 0.3),
              actors: desertActors(party: party, moving: moving),
              moving: moving,
            ),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
    }
  });
}
