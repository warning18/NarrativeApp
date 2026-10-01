// A price the story asks (a fee, a bribe, a buy-in) is never paid on
// credit (v1.187): either the next scene asks for the gold, or the
// choice is marked as a payment and stays shut until the purse holds it.
// Gold the story takes away as a loss (stores thrown overboard, the camp
// given up) is not a price and takes what there is.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/story_player_screen.dart';

/// Story choices whose gold is a loss, not a price.
const _losses = {
  // A chapter 1 fight lost in the casino gives back what it paid; a
  // failed way aboard the Lark takes the fine or the bribe out of what
  // there is.
  '115',
  '125',
  '896_failed',
  '897_failed',
  '2900_boat_fixed',
  '2999',
  '2015_cards_lost',
  '2015_sable_caught',
  '4999_standard',
  '7002_price',
};

void main() {
  final dag =
      jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
  final story = StoryData({
    for (final entry in dag.entries)
      entry.key:
          StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
  });

  PlayerSession purse(int gold) => PlayerSession.fromJson(
      {'raceId': 'human', 'professionId': 'warrior', 'gold': gold});

  test('every price the story asks is guarded', () {
    for (final node in story.nodes.values) {
      for (final choice in node.choices) {
        if (choice.pays) {
          expect(choice.goldMod, lessThan(0), reason: node.id);
        }
        if (choice.goldMod >= 0 || _losses.contains(node.id)) continue;
        final price = -choice.goldMod;
        final target = story.nodeFor(choice.nextId);
        final guarded = choice.pays ||
            (target?.reqGold ?? 0) >= price ||
            // The toll's scene is only reached with the toll in hand.
            node.reqGold >= price;
        expect(guarded, isTrue,
            reason: '${node.id}: "${choice.text}" costs $price');
      }
    }
  });

  test('a marked payment stays shut until the purse holds it', () {
    final lysa =
        story.nodeFor('3005_lysa')!.choices.firstWhere((c) => c.goldMod < 0);
    expect(lysa.pays, isTrue);
    expect(isStoryChoiceLocked(lysa, story, purse(29)), isTrue);
    expect(isStoryChoiceLocked(lysa, story, purse(30)), isFalse);
    // The other ways out of the scene stay open to a broke party.
    for (final other
        in story.nodeFor('3005_lysa')!.choices.where((c) => !c.pays)) {
      expect(isStoryChoiceLocked(other, story, purse(0)), isFalse,
          reason: other.text);
    }
  });

  test('a loss is not a payment: it takes what there is', () {
    final stores =
        story.nodeFor('2999')!.choices.firstWhere((c) => c.goldMod < 0);
    expect(stores.pays, isFalse);
    expect(isStoryChoiceLocked(stores, story, purse(0)), isFalse);
  });
}
