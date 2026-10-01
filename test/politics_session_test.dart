// The clan story layer (v1.195) in the session: a story choice's politics
// through the notifier (the offer it asks, the titles it gives, the
// companion an outcome takes or sours, once however often), the coast's
// events and their news (read at the camp), the Open Hand's stage and
// banner from Edit Mode with the titles they earn, "Your own hand" taken
// from an offer, and all of it through the save file.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/approval.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/politics_events.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/models/story_politics.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

import 'player_session_provider_test.dart' show baseSession;

final ClanData _data = ClanData.fromTables(
  factions: {
    'dominion': {'kind': 'clan', 'name': 'Dominion', 'startStanding': -10},
    'vigil': {'kind': 'clan', 'name': 'Vigil'},
    'mire': {'kind': 'clan', 'name': 'Mire'},
    'open_hand': {'kind': 'lost', 'name': 'The Open Hand'},
  },
  subclans: {
    'inquisition': {'clan': 'dominion', 'name': 'Inquisition'},
  },
  relations: {
    'pairs': [
      {'a': 'dominion', 'b': 'vigil', 'step': 2},
    ],
  },
  titles: {
    'drawer': {'name': 'Drawer', 'source': 'remembrance:3'},
    'last_of_the_open_hand': {'name': 'Last of the Open Hand'},
    'kingmaker': {'name': 'Kingmaker', 'source': 'intrigue'},
  },
  intrigues: {
    'dying_lantern_bearer': {
      'name': 'The Dying Lantern-Bearer',
      'outcomes': [
        {
          'name': 'Vane',
          'effects': [
            {'subclan': 'inquisition', 'mark': 'friend'},
            {'title': 'kingmaker'},
            {'companion': 'vess', 'change': 'leaves'},
            {'companion': 'kelda', 'change': 'disapproves'},
          ],
        },
      ],
    },
  },
);

final Map<String, PoliticsEvent> _events = parsePoliticsEvents(const {
  'bells': {
    'trigger': {'chapter': 4},
    'variants': [
      {
        'effects': {
          'flags': ['throne_vacant'],
          'offerFrom': 'vigil',
        },
        'news': 'The bells rang all night.',
        'news_fr': 'Les cloches sonnèrent toute la nuit.',
      },
    ],
  },
  'quarrel': {
    'trigger': {'flag': 'throne_vacant'},
    'variants': [
      {
        'effects': {
          'standing': {'vigil': 4},
        },
        'news': 'The Order and the Inquisition quarrel.',
      },
    ],
  },
});

Future<PlayerSessionNotifier> _notifierWith(PlayerSession session) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(session);
  return notifier;
}

StoryPolitics _politics(Map<String, dynamic> json) =>
    StoryPolitics.tryParse(json)!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a choice\'s politics through the notifier, once', () async {
    final notifier = await _notifierWith(baseSession(
      recruitedAllies: const [
        AllyState(companionId: 'vess', currentHealth: 50),
        AllyState(companionId: 'kelda', currentHealth: 50),
      ],
      activeAllyIds: const ['vess', 'kelda'],
    ).copyWith(day: 12, clockChapter: 4));
    expect(notifier.isLoaded, isTrue);
    final politics = _politics(const {
      'standing': {'vigil': 6},
      'offerFrom': 'mire',
      'remembrance': 3,
      'intrigue': {'id': 'dying_lantern_bearer', 'outcome': 0},
    });
    final change = await notifier.applyStoryPolitics(politics,
        nodeId: 'n7', key: choicePoliticsKey('n7', 1), data: _data, chapter: 4);
    expect(change.applied, isTrue);
    var s = notifier.state;
    // Standing, logged under the scene, on the chapter and the day.
    final entry = s.politics.standingLog.first;
    expect([entry.cause, entry.chapter, entry.day], ['story:n7', 4, 12]);
    expect(s.politics.standingOf('vigil', _data), 6);
    // The offer it asks: the Mire's place guaranteed, its cause the scene.
    expect(
        s.pendingOffers.single,
        const OfferTicket(
            source: OfferSource.story, detail: 'story:n7', factionId: 'mire'));
    // The outcome: a mark, a title (worn, none was), a companion gone and
    // one who thinks less of the character.
    expect(s.politics.markOf('inquisition'), SubclanMark.friend);
    expect(s.heldTitleIds, containsAll(['kingmaker', 'drawer']));
    expect(s.activeTitleId, isNotEmpty);
    expect(s.recruitedAllies.map((a) => a.companionId), ['kelda']);
    expect(s.departedAllyIds, ['vess']);
    expect(s.recruitedAllies.single.approval,
        startingApproval - PlayerSessionNotifier.intrigueApprovalShift);
    expect(
        s.flags,
        containsAll(
            ['open_hand_3', 'intrigue_dying_lantern_bearer_outcome_0']));

    // Taken again (going back, a hub's loop): nothing moves.
    final again = await notifier.applyStoryPolitics(politics,
        nodeId: 'n7', key: choicePoliticsKey('n7', 1), data: _data, chapter: 4);
    expect(again.applied, isFalse);
    s = notifier.state;
    expect(s.politics.standingOf('vigil', _data), 6);
    expect(s.pendingOffers, hasLength(1));
  });

  test('the coast moves on a chapter, its news read at the camp', () async {
    final notifier = await _notifierWith(baseSession().copyWith(day: 30));
    final none = await notifier.runPoliticsEvents(
        data: _data, events: _events, chapter: 3);
    expect(none.applied, isFalse);
    final change = await notifier.runPoliticsEvents(
        data: _data, events: _events, chapter: 4);
    // The bells set the flag the quarrel waits for.
    expect(change.fired, ['bells', 'quarrel']);
    expect(change.news.map((n) => n.text), [
      'The bells rang all night.',
      'The Order and the Inquisition quarrel.',
    ]);
    final s = notifier.state;
    expect(s.flags, contains('throne_vacant'));
    expect(s.pendingOffers.single.factionId, 'vigil');
    expect(s.pendingOffers.single.detail, 'event:bells');
    expect(s.politics.unreadNews, hasLength(2));
    expect(s.politics.standingLog.map((e) => e.cause),
        containsAll(['event:bells', 'event:quarrel']));
    // Nothing fires twice.
    expect(
        (await notifier.runPoliticsEvents(
                data: _data, events: _events, chapter: 5))
            .applied,
        isFalse);
    await notifier.markCoastNewsRead();
    expect(notifier.state.politics.unreadNews, isEmpty);
    expect(notifier.state.politics.news, hasLength(2));
    // Edit Mode's Fire now fires one again.
    await notifier.firePoliticsEvent('quarrel',
        data: _data, events: _events, chapter: 5);
    expect(notifier.state.politics.firedEvents['quarrel']!.count, 2);
    expect(notifier.state.politics.unreadNews, hasLength(1));
  });

  test('Edit Mode sets the remembrance and the banner; titles follow',
      () async {
    final notifier = await _notifierWith(
        baseSession().copyWith(flags: const ['open_hand_5', 'other']));
    await notifier.setOpenHandStage(3, data: _data);
    expect(notifier.state.flags,
        ['other', 'open_hand_1', 'open_hand_2', 'open_hand_3']);
    expect(notifier.state.heldTitleIds, ['drawer']);
    await notifier.setOpenHandStage(6, data: _data);
    expect(openHandStageFrom(notifier.state.flags), 6);
    expect(notifier.state.heldTitleIds, ['drawer'],
        reason: 'the last title wants the banner raised');
    await notifier.setStoryFlag(bannerRaisedFlag, true, data: _data);
    expect(notifier.state.heldTitleIds, ['drawer', 'last_of_the_open_hand']);
    await notifier.setOpenHandStage(0, data: _data);
    expect(notifier.state.flags, ['other', bannerRaisedFlag]);
    expect(notifier.state.heldTitleIds, hasLength(2), reason: 'kept');
    await notifier.setStoryFlag(bannerRaisedFlag, false, data: _data);
    expect(notifier.state.flags, ['other']);
  });

  test(
      '"Your own hand" taken: a sign, and the Dominion -2 once the banner '
      'is raised', () async {
    final signs = parseSigns(const {
      'hand_mend': {
        'patron': 'open_hand',
        'slot': 'mend',
        'name': 'The Open Palm',
        'effects': [
          {'kind': 'mendPercent', 'value': 10},
        ],
      },
    });
    const ticket = OfferTicket(source: OfferSource.level);
    const offer = ClanOffer(ticket: ticket, suitors: [
      Suitor(
          factionId: 'open_hand',
          gift: OfferGift(kind: GiftKind.sign, id: 'hand_mend')),
    ]);
    final notifier = await _notifierWith(
        baseSession(pendingOffers: const [ticket]).copyWith(
            clanOffer: offer,
            flags: [...openHandFlagsUpTo(6), bannerRaisedFlag]));
    final taken = await notifier.acceptSuitor('open_hand',
        tables: OfferTables(data: _data, signs: signs));
    expect(taken, isTrue);
    final s = notifier.state;
    expect(s.heldSigns.single.signId, 'hand_mend');
    expect(s.politics.standingOf('dominion', _data), -12);
    expect(s.politics.standings.containsKey('open_hand'), isFalse);
    expect(s.alignmentScore, 0);
    expect(s.pendingOffers, isEmpty);
  });

  test('the save keeps what was applied, fired and told', () async {
    final notifier = await _notifierWith(baseSession());
    await notifier.applyStoryPolitics(_politics(const {'remembrance': 2}),
        nodeId: 'n1', key: enterPoliticsKey('n1'), data: _data);
    await notifier.runPoliticsEvents(data: _data, events: _events, chapter: 4);
    final saved = PlayerSession.fromJson(
        jsonDecode(jsonEncode(notifier.state.toJson()))
            as Map<String, dynamic>);
    expect(saved.politics.appliedKeys, ['story:n1:enter']);
    expect(saved.politics.firedEvents.keys, ['bells', 'quarrel']);
    expect(saved.politics.news.first.textFr,
        'Les cloches sonnèrent toute la nuit.');
    expect(saved.politics.standingLog.map((e) => e.note),
        contains('The bells rang all night.'));
    expect(saved.flags, containsAll(['open_hand_1', 'open_hand_2']));
    expect(saved.politics.toJson(), notifier.state.politics.toJson());
  });
}
