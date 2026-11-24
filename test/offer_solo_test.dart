// A specialisation or a Sworn boon offered alone (Wave 1, the user's call:
// "replace", not "add"): a draw holding one deals that card alone; "Not now"
// deals the same offer again as the usual cards, without that gift, and
// moves nothing else; the gift may come again later. The save keeps the
// flag.
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

const _boon = Suitor(
    factionId: 'crows', gift: OfferGift(kind: GiftKind.sworn, id: 'crows'));

bool _isBoon(Suitor s) => s.gift.kind == GiftKind.sworn && s.gift.id == 'crows';

Future<PlayerSessionNotifier> _notifierWith(PlayerSession session) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(session);
  return notifier;
}

/// A human warrior Sworn to the Crows (their boon due), an offer waiting.
PlayerSession _swornToCrows() {
  final base = PlayerSession.fromJson({
    ...baseSession().toJson(),
    'raceId': 'human',
    'professionId': 'warrior',
    'unlockedSkillIds': ['warrior_shield_bash', 'human_resolve'],
  });
  final politics =
      setStandingValue(base.politics, 'crows', 70, 'edit', data: _tables.data)
          .state;
  return base.copyWith(politics: politics, pendingOffers: [_level]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a draw holding a Sworn boon or a specialisation deals it alone',
      () async {
    final notifier = await _notifierWith(_swornToCrows());
    final c = notifier.offerContextFor(_tables);
    var alone = 0;
    for (var seed = 1; seed <= 60; seed++) {
      final usual = drawOffer(_level, c, Random(seed), solo: false)!;
      final offer = drawOffer(_level, c, Random(seed))!;
      final expected = soloSuitorOf(usual.suitors);
      if (expected == null) {
        expect(offer.solo, isFalse, reason: 'seed $seed');
        expect(offer, usual, reason: 'seed $seed: nothing alone, no change');
        continue;
      }
      alone++;
      expect(offer.solo, isTrue, reason: 'seed $seed');
      expect(offer.suitors, [expected], reason: 'seed $seed');
      expect(offer.suitors.single.risky, isFalse);
      // The boon before a specialisation.
      if (usual.suitors.any((s) => s.gift.kind == GiftKind.sworn)) {
        expect(offer.suitors.single.gift.kind, GiftKind.sworn);
      }
    }
    expect(alone, greaterThan(0), reason: 'the Crows\' boon never came');
  });

  test('"Not now" deals the usual three cards, without that gift', () async {
    final notifier = await _notifierWith(_swornToCrows().copyWith(
        clanOffer:
            const ClanOffer(ticket: _level, suitors: [_boon], solo: true)));
    final before = notifier.state;
    final next = await notifier.declineSoloOffer(_tables, random: Random(3));
    final offer = notifier.state.clanOffer!;
    expect(next, offer);
    expect(offer.solo, isFalse);
    expect(offer.suitors, hasLength(3));
    expect(offer.suitors.where(_isBoon), isEmpty);
    expect({for (final s in offer.suitors) s.factionId}, hasLength(3));
    // Nothing else moves: the offer still waits, no boon, no standing.
    expect(notifier.state.pendingOffers, before.pendingOffers);
    expect(notifier.state.swornBoonIds, before.swornBoonIds);
    expect(notifier.state.politics.standingOf('crows', _tables.data),
        before.politics.standingOf('crows', _tables.data));
    expect(notifier.state.rollBans, before.rollBans);

    // Whatever the draw, the declined boon never comes back on that offer.
    final c = notifier.offerContextFor(_tables);
    const solo = ClanOffer(ticket: _level, suitors: [_boon], solo: true);
    for (var seed = 1; seed <= 40; seed++) {
      final usual = declinedOffer(solo, c, Random(seed))!;
      expect(usual.solo, isFalse, reason: 'seed $seed');
      expect(usual.suitors.where(_isBoon), isEmpty, reason: 'seed $seed');
    }

    // Taken from the usual cards, the offer is spent; the boon stays due.
    await notifier.acceptSuitor(offer.suitors.first.factionId, tables: _tables);
    expect(notifier.state.pendingOffers, isEmpty);
    expect(notifier.state.swornBoonIds, isNot(contains('crows')));
    expect(swornBoonDue('crows', notifier.offerContextFor(_tables)), isTrue);
  });

  test('"Not now" does nothing on an offer that is not alone', () async {
    const three = ClanOffer(ticket: _level, suitors: [_boon]);
    final notifier =
        await _notifierWith(_swornToCrows().copyWith(clanOffer: three));
    expect(await notifier.declineSoloOffer(_tables), three);
    expect(notifier.state.clanOffer, three);
  });

  test('the save keeps the flag; an old save reads it off', () {
    const solo = ClanOffer(ticket: _level, suitors: [_boon], solo: true);
    final json = jsonDecode(jsonEncode(solo.toJson()));
    expect(ClanOffer.tryParse(json), solo);
    expect((json as Map)['solo'], isTrue);
    final old = Map<String, dynamic>.from(json)..remove('solo');
    expect(ClanOffer.tryParse(old)!.solo, isFalse);
    expect(
        const ClanOffer(ticket: _level, suitors: [_boon])
            .toJson()
            .containsKey('solo'),
        isFalse);
  });
}
