// A detour remembers the choice it interrupts on every one of its nodes,
// and forgets it once the story resumes.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/sub_node_engine.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the origin rides every detour node and clears on resume', () async {
    final notifier = StoryPlayNotifier('1');
    await Future<void>.delayed(Duration.zero);
    const a = StoryNode(id: 'gen_a', description: 'A', choices: []);
    const b = StoryNode(id: 'gen_b', description: 'B', choices: []);
    notifier.startExcursion([a, b], '2',
        origin: 'Take the Stone Bridge', originFr: 'Prendre le pont');
    expect(notifier.state.activeExcursionNode?.id, 'gen_a');
    expect(notifier.state.excursionOriginFor(false), 'Take the Stone Bridge');
    expect(notifier.state.excursionOriginFor(true), 'Prendre le pont');
    notifier.advanceExcursion();
    expect(notifier.state.activeExcursionNode?.id, 'gen_b');
    expect(notifier.state.excursionOriginFor(false), 'Take the Stone Bridge');
    notifier.advanceExcursion();
    expect(notifier.state.isInExcursion, isFalse);
    expect(notifier.state.currentNodeId, '2');
    expect(notifier.state.excursionOriginFor(false), isNull);
  });

  test('a pack slipped past leaves no trail to follow', () async {
    const pack = StoryNode(id: 'gen_1', description: 'Rats', choices: []);
    const trail = StoryNode(
        id: 'gen_2${SubNodeEngine.huntTrailSuffix}',
        description: 'One of them got away.',
        choices: []);
    const quarry = StoryNode(id: 'gen_3', description: 'The lair', choices: []);
    const cache = StoryNode(id: 'gen_4', description: 'A cache', choices: []);
    expect(SubNodeEngine.isHuntTrail(trail), isTrue);
    expect(SubNodeEngine.isHuntTrail(quarry), isFalse);

    final sneaky = StoryPlayNotifier('1');
    await Future<void>.delayed(Duration.zero);
    sneaky.startExcursion([pack, trail, quarry, cache], '2');
    sneaky.advanceExcursion(slippedPast: true);
    expect(sneaky.state.activeExcursionNode?.id, 'gen_4');

    // A pack fought: the survivor's trail is there to follow.
    final fought = StoryPlayNotifier('1');
    await Future<void>.delayed(Duration.zero);
    fought.startExcursion([pack, trail, quarry, cache], '2');
    fought.advanceExcursion();
    expect(fought.state.activeExcursionNode?.id, trail.id);
  });

  test('a detour put off by a crisis is owed once, then taken', () async {
    final notifier = StoryPlayNotifier('1');
    await Future<void>.delayed(Duration.zero);
    expect(notifier.takeOwedDetour(), isFalse);
    notifier.oweDetour();
    notifier.oweDetour();
    expect(notifier.detourOwed, isTrue);
    expect(notifier.takeOwedDetour(), isTrue);
    expect(notifier.takeOwedDetour(), isFalse);
  });
}
