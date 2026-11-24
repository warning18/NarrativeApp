// QA guard (the solo gift, v1.1007): a gift that comes alone (a Sworn boon,
// else a specialisation) over every clan, and through the saves a player's
// app really makes. Core's offer_solo_test checks the rule on the Crows; this
// goes over all the clans, and restarts the app's session store between the
// moves: the offer waits alone after a restart, "Not now" is kept across a
// restart, and a card taken afterwards leaves nothing waiting.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _data(String name) =>
    json.decode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

final OfferTables _tables = OfferTables(
  data: ClanData.fromTables(
    factions: _data('factions'),
    subclans: _data('subclans'),
    relations: _data('relations'),
    titles: _data('titles'),
    intrigues: _data('intrigues'),
  ),
  signs: parseSigns(_data('signs')),
  skills: _data('skills'),
  skillTrees: _data('skill_trees'),
  items: _data('items'),
  spells: parseSpells(_data('spells')),
);

const _level = OfferTicket(source: OfferSource.level);

PlayerSession _swornTo(String clan) {
  final base = PlayerSession.fromJson({
    ...baseSession().toJson(),
    'raceId': 'human',
    'professionId': 'warrior',
    'unlockedSkillIds': ['warrior_shield_bash', 'human_resolve'],
  });
  final politics =
      setStandingValue(base.politics, clan, 70, 'edit', data: _tables.data)
          .state;
  return base.copyWith(politics: politics, pendingOffers: [_level]);
}

Future<PlayerSessionNotifier> _open() async {
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('over every clan: alone, risk-free; Not now leaves three other cards',
      () async {
    final clans = [
      for (final k in _data('factions').keys)
        if (!k.startsWith('_')) k
    ];
    expect(clans.length, greaterThan(8));
    var alone = 0;
    for (final clan in clans) {
      SharedPreferences.setMockInitialValues({});
      final notifier = await _open();
      await notifier.loadSession(_swornTo(clan));
      final c = notifier.offerContextFor(_tables);
      for (var seed = 1; seed <= 12; seed++) {
        final offer = drawOffer(_level, c, Random(seed));
        if (offer == null || !offer.solo) continue;
        alone++;
        expect(offer.suitors, hasLength(1), reason: '$clan seed $seed');
        final gift = offer.suitors.single;
        expect(gift.risky, isFalse, reason: '$clan seed $seed');
        final after = declinedOffer(offer, c, Random(seed));
        expect(after, isNotNull, reason: '$clan seed $seed: nobody else comes');
        expect(after!.solo, isFalse, reason: '$clan seed $seed');
        expect(after.suitors, hasLength(3), reason: '$clan seed $seed');
        expect(
            after.suitors.where((s) =>
                s.factionId == gift.factionId &&
                s.gift.kind == gift.gift.kind &&
                s.gift.id == gift.gift.id),
            isEmpty,
            reason: '$clan seed $seed: the declined gift is dealt again');
        expect({for (final s in after.suitors) s.factionId}, hasLength(3),
            reason: '$clan seed $seed: a clan twice');
      }
    }
    expect(alone, greaterThan(clans.length),
        reason: 'the gift came alone for too few of the clans');
  });

  test('the solo offer, Not now and a taken card survive restarts', () async {
    SharedPreferences.setMockInitialValues({});
    var notifier = await _open();
    await notifier.loadSession(_swornTo('crows'));
    // A draw that holds the gift alone.
    ClanOffer? solo;
    for (var seed = 1; seed <= 60 && solo == null; seed++) {
      final o =
          drawOffer(_level, notifier.offerContextFor(_tables), Random(seed));
      if (o != null && o.solo) solo = o;
    }
    expect(solo, isNotNull);
    await notifier.loadSession(notifier.state.copyWith(clanOffer: solo));

    // Restart 1: the offer still waits, alone.
    notifier = await _open();
    expect(notifier.state.clanOffer, solo);
    expect(notifier.state.clanOffer!.solo, isTrue);

    // Not now, then restart 2: the three cards, the same ones.
    final three = await notifier.declineSoloOffer(_tables, random: Random(3));
    expect(three!.solo, isFalse);
    notifier = await _open();
    expect(notifier.state.clanOffer, three);
    expect(notifier.state.pendingOffers, [_level]);

    // A card taken, then restart 3: nothing waits, the boon is not given.
    await notifier.acceptSuitor(three.suitors.first.factionId, tables: _tables);
    notifier = await _open();
    expect(notifier.state.clanOffer, isNull);
    expect(notifier.state.pendingOffers, isEmpty);
    expect(notifier.state.swornBoonIds, isNot(contains('crows')));
  });
}
