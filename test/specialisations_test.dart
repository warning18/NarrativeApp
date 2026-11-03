// The main clans' specialisations (specialisations.dart): the rules on
// their own, specialisations.json, and in the simulator what each does to
// its profession's fights against the core alone (SPECS_RUNS=40 prints the
// table of docs/simulation/specialisations.md).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/profession_cores.dart';
import 'package:narrative_data_app/combat/spec_variants.dart' show SpecMods;
import 'package:narrative_data_app/combat/specialisations.dart';
import 'package:narrative_data_app/combat/status_effect.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';
import 'support/sim_world.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('every specialisation has an id, a core, and a home in the file', () {
    final infos = specInfosFrom(_table('specialisations'));
    final factions = _table('factions');
    final professions = _table('professions');
    expect(infos.keys.toSet(), {for (final s in Spec.values) specId(s)});
    for (final info in infos.values) {
      expect(specNamed(info.id), info.spec);
      expect(coreOfProfession(info.professionId), coreOfSpec(info.spec),
          reason: info.id);
      expect(professions.containsKey(info.professionId), isTrue);
      expect(factions.containsKey(info.factionId), isTrue);
      for (final text in [
        info.name,
        info.nameFr,
        info.gift,
        info.giftFr,
        info.voice,
        info.voiceFr,
      ]) {
        expect(text, isNotEmpty, reason: info.id);
      }
    }
    // Three main ones a profession, from three different clans.
    for (final p in professions.keys) {
      final mine = infos.values
          .where((i) => i.professionId == p && isMainSpec(i.spec))
          .toList();
      expect(mine, hasLength(3), reason: p);
      expect(mine.map((i) => i.factionId).toSet(), hasLength(3), reason: p);
    }
  });

  test('a specialisation plays only on its own core', () {
    expect(specsFor(['berserker', 'fever_blade', 'nope'], ProfessionCore.fury),
        {Spec.berserker});
    expect(specsFor(['berserker'], ProfessionCore.flurry), isEmpty);
  });

  test('the numbers', () {
    // The fight's own rules (spec_variants.dart), with no variant held.
    final mods = SpecMods.none;
    expect(mods.briarBack(40), 32);
    expect(mods.briarBack(0), 0);
    expect(mods.vigilMend(80, 100), 15);
    expect(mods.vigilMend(50, 100), 0);
    expect(mods.vigilMend(100, 100), 0);
    expect(
        fireAfterHeal(
            fire: 0,
            healing: 90,
            currentHealth: 100,
            maxHealth: 100,
            beacon: true),
        90);
    expect(
        fireAfterHeal(
            fire: 0,
            healing: 90,
            currentHealth: 100,
            maxHealth: 100,
            beacon: false),
        50);
    expect(mods.censerBurnFor(3, 20), 180);
    expect(ledgerCritical(30), 35);
    // An Evil foe is told by its kind (foe_kind.dart), not by Light.
    expect(isEvilFoe({'kind': 'undead'}), isTrue);
    expect(
        isEvilFoe({
          'kind': 'person',
          'weakTo': ['Light']
        }),
        isFalse);
  });

  test('the Rot stacks where poison refreshes, and lasts', () {
    var effects = withRot(const [], 100);
    expect(poisonDamageFor(effects), 20);
    effects = withRot(effects, 50);
    expect(poisonDamageFor(effects), 30);
    expect(effects.single.remainingTurns, rotTurns);
  });

  test('the Trail knows a run\'s first face and its Verdict', () {
    final deck = TrailDeck(6, Random(5));
    for (var run = 0; run < 5; run++) {
      for (var i = 0; i < trailDrawsPerRun; i++) {
        if (i == 1) deck.peek();
        deck.draw();
        expect(deck.drewFirst, i == 0, reason: 'run $run, draw $i');
        expect(deck.drewVerdict, i == trailDrawsPerRun - 1,
            reason: 'run $run, draw $i');
      }
    }
  });

  test('the main clan offers its specialisation from Friend, once', () {
    final data = ClanData.fromTables(
      factions: _table('factions'),
      subclans: _table('subclans'),
      relations: _table('relations'),
      titles: _table('titles'),
    );
    final specs = specInfosFrom(_table('specialisations'));
    OfferContext ctx(num crows,
            {String profession = 'warrior', List<String> held = const []}) =>
        OfferContext(
          data: data,
          politics: setStandingValue(
                  PoliticsState.empty, 'crows', crows, 'edit',
                  data: data)
              .state,
          professionId: profession,
          raceId: 'human',
          specs: specs,
          heldSpecIds: held,
        );
    expect(offerableSpecsFor('crows', ctx(20)), ['berserker']);
    expect(offerableSpecsFor('crows', ctx(10)), isEmpty);
    expect(offerableSpecsFor('crows', ctx(20, held: ['berserker'])), isEmpty);
    expect(offerableSpecsFor('crows', ctx(20, profession: 'mage')),
        ['tempest_toll']);
    expect(offerableSpecsFor('vigil', ctx(20)), isEmpty);
    expect(availableGiftKinds('crows', ctx(20)), contains(GiftKind.spec));
    // Weighted first, it comes most of the time.
    final random = Random(2);
    var came = 0;
    for (var i = 0; i < 100; i++) {
      if (drawGift('crows', ctx(20), random)?.kind == GiftKind.spec) came++;
    }
    expect(came, greaterThan(40));
  });

  test('in the simulator, each specialisation against its core alone', () {
    final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
    final story = StoryData({
      for (final e in raw.entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    });
    final tables = simTables();
    final runs = int.tryParse(Platform.environment['SPECS_RUNS'] ?? '') ?? 2;
    final infos = specInfosFrom(_table('specialisations'));
    ({double win, double rounds}) measure(String profession,
        [List<String> specs = const []]) {
      final summaries = simulatePlaythroughs(story,
          tables: tables,
          gameConfig: _table('game_config'),
          plan: [
            for (var i = 0; i < runs; i++)
              (
                strategy: SimStrategy.random,
                raceId: null,
                professionId: profession,
              ),
          ],
          seed: 11,
          startSpecs: specs);
      var won = 0, fights = 0, rounds = 0;
      for (final r in summaries) {
        won += r.fightsWon;
        fights += r.fightsWon + r.fightsLost;
        rounds += r.roundsFought;
      }
      return (win: 100 * won / fights, rounds: rounds / fights);
    }

    final professions = {
      for (final i in infos.values)
        if (Platform.environment['SPECS_ONLY'] == null ||
            Platform.environment['SPECS_ONLY']!.split(',').contains(i.id))
          i.professionId,
    };
    final core = {for (final p in professions) p: measure(p)};
    final lines = <String>[];
    final silent = <String>[];
    final only = (Platform.environment['SPECS_ONLY'] ?? '')
        .split(',')
        .where((id) => id.isNotEmpty)
        .toSet();
    for (final info in infos.values.toList()
      ..sort((a, b) => a.professionId.compareTo(b.professionId))) {
      if (only.isNotEmpty && !only.contains(info.id)) continue;
      final base = core[info.professionId]!;
      final spec = measure(info.professionId, [info.id]);
      lines.add('| ${info.professionId} | ${info.name} | '
          '${base.win.toStringAsFixed(1)}% → ${spec.win.toStringAsFixed(1)}% | '
          '${(spec.win - base.win) >= 0 ? '+' : ''}'
          '${(spec.win - base.win).toStringAsFixed(1)} | '
          '${spec.rounds.toStringAsFixed(1)} |');
      // Every specialisation plays: its profession's fights change.
      if (spec.win == base.win && spec.rounds == base.rounds) {
        silent.add(info.id);
      }
    }
    if (Platform.environment['SPECS_RUNS'] != null) {
      // ignore: avoid_print
      print(lines.join('\n'));
    }
    // The weak links the autoplay never reaches: a warrior's die has no
    // Mana face, a potion is drunk below 40%, a mage's spells seldom meet
    // another element or leave a status.
    expect(
        silent.toSet().difference({
          'burning_penance',
          'brimming_draught',
          'double_kindling',
          'lingering_hex',
        }),
        isEmpty);
  });
}
