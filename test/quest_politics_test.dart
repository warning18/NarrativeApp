// Quests feed politics (v1.204): a turn-in choice may move the clans
// (read as a story choice's politics), applied once under its own key and
// logged under the quest; the turn-in dialog says what each choice moves;
// a quest with a giver of its own (`detourEligible` false) stays out of
// the random detours.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/politics_events.dart';
import 'package:narrative_data_app/data/sub_node_engine.dart';
import 'package:narrative_data_app/data/turn_in_choices.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/widgets/turn_in_choice_dialog.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

final ClanData _data = ClanData.fromTables(
  factions: _json('factions'),
  subclans: _json('subclans'),
  relations: _json('relations'),
  titles: _json('titles'),
  intrigues: _json('intrigues'),
);

const Map<String, dynamic> _quest = {
  'questName': 'The Unpaid Scaffold',
  'rewardGold': 40,
  'alignmentChange': 0,
  'turnInChoices': [
    {
      'choiceText': 'Hand the wages to the crew',
      'rewardGold': 15,
      'flag': 'scaffold_paid',
      'politics': {
        'standing': {'compact': 10, 'dominion': -5},
        'marks': {'scaffolders': 'friend'},
      },
    },
    {
      'choiceText': 'Take the Ledger’s cut yourself',
      'rewardGold': 70,
      'alignmentChange': -5,
      'flag': 'scaffold_skimmed',
      'politics': {
        'standing': {'dominion': 5, 'compact': -10},
      },
    },
    {
      'choiceText': 'Walk away',
      'flag': 'scaffold_left',
    },
  ],
};

void main() {
  group('turn-in politics', () {
    test('a choice reads its politics as a story choice does', () {
      final choices = turnInChoicesOf(_quest);
      expect(choices, hasLength(3));
      expect(choices[0].hasPolitics, isTrue);
      expect(choices[0].politics!.standing, {'compact': 10, 'dominion': -5});
      expect(choices[0].politics!.marks, {'scaffolders': 'friend'});
      expect(choices[1].politics!.standing, {'dominion': 5, 'compact': -10});
      expect(choices[2].politics, isNull);
      expect(choices[2].hasPolitics, isFalse);
      expect(
          TurnInChoice.fromJson(const {'choiceText': 'x', 'politics': {}})
              .hasPolitics,
          isFalse);
    });

    test('the key names the quest and the choice', () {
      expect(questTurnInPoliticsKey('q_ch2_unpaid_scaffold', 0),
          'quest:q_ch2_unpaid_scaffold:turnin0');
      expect(questTurnInPoliticsKey('q', 2), 'quest:q:turnin2');
      expect(questTurnInPoliticsKey('q', 0), isNot(choicePoliticsKey('q', 0)));
    });

    test('applied once under its key, logged under the quest', () {
      final choice = turnInChoicesOf(_quest)[0];
      final world = CoastWorld(data: _data, chapter: 2);
      final key = questTurnInPoliticsKey('q_ch2_unpaid_scaffold', 0);
      final before = PoliticsState.empty.standingOf('compact', _data);
      final first = applyStoryPolitics(choice.politics!,
          cause: 'quest:q_ch2_unpaid_scaffold',
          key: key,
          politics: PoliticsState.empty,
          flags: const [],
          world: world);
      expect(first.applied, isTrue);
      expect(first.politics.standingOf('compact', _data), before + 10);
      expect(first.politics.applied(key), isTrue);
      expect(first.politics.markOf('scaffolders'), SubclanMark.friend);
      expect(
          first.politics.standingLog
              .any((e) => e.cause == 'quest:q_ch2_unpaid_scaffold'),
          isTrue);
      expect(standingCauseLabel('quest:q_ch2_unpaid_scaffold', AppLanguage.en),
          'Quest · q_ch2_unpaid_scaffold');
      // Turned in again (a replay of the dialog): nothing moves.
      final again = applyStoryPolitics(choice.politics!,
          cause: 'quest:q_ch2_unpaid_scaffold',
          key: key,
          politics: first.politics,
          flags: const [],
          world: world);
      expect(again.applied, isFalse);
      expect(again.politics.standingOf('compact', _data), before + 10);
    });

    testWidgets('the dialog says what each choice moves', (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appLanguageProvider);
      await tester.runAsync(() async {
        for (final schema in [
          factionsSchema,
          subclansSchema,
          relationsSchema,
          titlesSchema,
          intriguesSchema,
        ]) {
          await container.read(gameDbProvider(schema).notifier).whenLoaded();
        }
      });
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showTurnInChoiceDialog(context, ref,
                    quest: _quest, choices: turnInChoicesOf(_quest)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('turn_in_choice_0')), findsOneWidget);
      final hint =
          tester.widget<Text>(find.byKey(const Key('turn_in_politics_hint_0')));
      expect(hint.data, contains('+10'));
      expect(hint.data, contains('−5'));
      expect(find.byKey(const Key('turn_in_politics_hint_1')), findsOneWidget);
      expect(find.byKey(const Key('turn_in_politics_hint_2')), findsNothing,
          reason: 'a choice that moves nothing says nothing');
      expect(tester.takeException(), isNull);
    });
  });

  group('detours', () {
    test('a quest with its own giver stays out of the random pool', () {
      final quests = {
        'q_open': {'chapter': 2},
        'q_given': {'chapter': 2, 'detourEligible': false},
        'q_said_so': {'chapter': 2, 'detourEligible': true},
        'q_later': {'chapter': 3},
      };
      expect(
          SubNodeEngine.filterQuestPool(
              quests: quests,
              chapter: 2,
              unlockedQuestIds: const [],
              completedQuestIds: const []),
          ['q_open', 'q_said_so']);
    });

    test('every quest with a politics turn-in is written for its giver', () {
      // The side quests with a giver in a town (v1.204) carry politics on
      // their turn-in and are never offered by a detour.
      final quests = _json('quests');
      for (final entry in quests.entries) {
        final quest = entry.value as Map<String, dynamic>;
        final choices = turnInChoicesOf(quest);
        if (!choices.any((c) => c.hasPolitics)) continue;
        expect(quest['detourEligible'], isFalse, reason: entry.key);
        for (final choice in choices) {
          expect(choice.flag, isNotEmpty,
              reason: '${entry.key}: ${choice.text}');
        }
      }
    });
  });
}
