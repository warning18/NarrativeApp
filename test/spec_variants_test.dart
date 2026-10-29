// The sub-clans' variants and upgrades, and rank II (spec_variants.dart):
// spec_variants.json whole and in both languages, two of a sub-clan for
// each specialisation (its own clan's), offered from Trusted on a
// specialisation held and rank II from Sworn, and the numbers they set.
// VARIANTS_RUNS=60 prints each one against its specialisation alone in
// the simulator (docs/simulation/specialisations.md).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/spec_variants.dart';
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
  final variants = specVariantsFrom(_table('spec_variants'));
  final specs = specInfosFrom(_table('specialisations'));
  final factions = _table('factions');

  test('two sub-clan gifts and a rank II for each specialisation', () {
    for (final spec in Spec.values.where(isMainSpec)) {
      final mine = variants.values.where((v) => v.spec == spec).toList();
      final subclan = mine.where((v) => v.kind != SpecVariantKind.rank);
      expect(subclan, hasLength(2), reason: specId(spec));
      expect(mine.where((v) => v.kind == SpecVariantKind.rank), hasLength(1),
          reason: specId(spec));
      expect(variants[rankTwoId(spec)], isNotNull, reason: specId(spec));
      // A sub-clan of the specialisation's own clan.
      final clan = specs[specId(spec)]!.factionId;
      final own = (factions[clan] as Map)['subclans'] as List;
      for (final v in subclan) {
        expect(own, contains(v.subclanId), reason: v.id);
      }
    }
    for (final v in variants.values) {
      for (final text in [v.name, v.nameFr, v.text, v.textFr]) {
        expect(text, isNotEmpty, reason: v.id);
      }
    }
  });

  test('the numbers they set', () {
    final none = SpecMods(const []);
    expect(none.briarBack(40), 32);
    expect(SpecMods(['anvil_deaf_briar_guard']).briarBack(40), 40);
    expect(SpecMods(['briar_guard_ii']).briarBack(40), 48);
    expect(SpecMods(['order_lantern_vanguard']).vanguardEvilHeal, 0.30);
    expect(SpecMods(['candlebearers_long_vigil']).vigilMend(80, 100), 18);
    expect(SpecMods(['ember_sisters_ashen_hand']).ashenCleanse, 2);
    expect(SpecMods(['cantors_beacon']).beaconBurn, 1.875);
    expect(SpecMods(['scorched_choir_burden_bearer']).burdenMultiplier, 1.6);
    expect(SpecMods(['keyholders_tempest_toll']).spellDiscount, 1);
    expect(SpecMods(['reliquary_thieves_relicbreaker']).relicMana, 2);
    expect(SpecMods(['relicbreaker_ii']).relicThreshold, 2);
    expect(SpecMods(['scaffolders_trapwright']).stunTargets, 2);
    expect(SpecMods(['trapwright_ii']).stun.remainingTurns, 2);
    expect(SpecMods(['returned_fen_guide']).trailSight, 2);
    expect(specGunPercent(['brig_born_corsairs_eye']), broadsideGunPercent);
    expect(specGunPercent(const []), 0);
    // Rank II: half again.
    expect(SpecMods(['fever_blade_ii']).rot, closeTo(rotShare * 1.5, 1e-9));
    expect(
        poisonDamageFor(SpecMods(['fever_blade_ii']).withRotOf(const [], 100)),
        30);
  });

  test('a variant from Trusted on a specialisation held, rank II at Sworn', () {
    final data = ClanData.fromTables(
      factions: factions,
      subclans: _table('subclans'),
      relations: _table('relations'),
      titles: _table('titles'),
    );
    OfferContext ctx(num crows, List<String> held) => OfferContext(
          data: data,
          politics: setStandingValue(
                  PoliticsState.empty, 'crows', crows, 'edit',
                  data: data)
              .state,
          professionId: 'warrior',
          raceId: 'human',
          specs: specs,
          specVariants: variants,
          heldSpecIds: held,
        );
    // Friend: the specialisation only, never its variants.
    expect(offerableSpecsFor('crows', ctx(20, const [])), ['berserker']);
    expect(offerableSpecsFor('crows', ctx(20, ['berserker'])), isEmpty);
    // Trusted, held: its two sub-clans' gifts.
    expect(offerableSpecsFor('crows', ctx(30, ['berserker'])),
        ['brig_born_berserker', 'tar_hands_berserker']);
    // Not held: none of them.
    expect(offerableSpecsFor('crows', ctx(30, const [])), ['berserker']);
    // Sworn: rank II too.
    expect(offerableSpecsFor('crows', ctx(70, ['berserker'])),
        contains('berserker_ii'));
    // The sub-clan voices its own gift.
    final random = Random(4);
    for (var i = 0; i < 20; i++) {
      final suitor = drawSuitor('crows', ctx(30, ['berserker']), random);
      if (suitor?.gift.kind != GiftKind.spec) continue;
      expect(suitor!.subclanId, variants[suitor.gift.id]!.subclanId);
    }
  });

  test('in the simulator, each against its specialisation alone', () {
    final runs = int.tryParse(Platform.environment['VARIANTS_RUNS'] ?? '');
    if (runs == null) return;
    final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
    final story = StoryData({
      for (final e in raw.entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    });
    final tables = simTables();
    double win(String profession, List<String> held) {
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
          startSpecs: held);
      var won = 0, fights = 0;
      for (final r in summaries) {
        won += r.fightsWon;
        fights += r.fightsWon + r.fightsLost;
      }
      return 100 * won / fights;
    }

    final only = (Platform.environment['VARIANTS_ONLY'] ?? '')
        .split(',')
        .where((id) => id.isNotEmpty)
        .toSet();
    final lines = <String>[];
    for (final spec in Spec.values.where(isMainSpec)) {
      final info = specs[specId(spec)]!;
      final mine = variants.values.where((v) => v.spec == spec).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      if (only.isNotEmpty && !mine.any((v) => only.contains(v.id))) continue;
      final base = win(info.professionId, [info.id]);
      for (final v in mine) {
        if (only.isNotEmpty && !only.contains(v.id)) continue;
        final w = win(info.professionId, [info.id, v.id]);
        lines.add('| ${info.name} | ${v.name} (${v.kind.name}) | '
            '${base.toStringAsFixed(1)}% → ${w.toStringAsFixed(1)}% | '
            '${w - base >= 0 ? '+' : ''}${(w - base).toStringAsFixed(1)} |');
      }
    }
    // ignore: avoid_print
    print(lines.join('\n'));
  });
}
