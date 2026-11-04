// The ground as a third party in a fight (v1.241): the stage a place gives a
// fight, the anomalies each stage can meet, and what an anomaly does round by
// round -- element factors, the Perception it takes, the ticks that wound
// and never finish.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/field_anomaly.dart';
import 'package:narrative_data_app/data/climate.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _asset(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

FieldAnomaly _anomaly(String id) => fieldAnomalyById(id)!;

void main() {
  group('the stage', () {
    test('every biome pattern has its stage, and a hall wins over all', () {
      for (final pattern in BiomePattern.values) {
        expect(fightStageOf(pattern).name, pattern.name);
        expect(fightStageOf(pattern, indoors: true), FightStage.hall);
      }
      expect(fightStageOf(null), FightStage.fields);
    });

    test('a stage is named by its enum name', () {
      for (final stage in FightStage.values) {
        expect(fightStageFromName(stage.name), stage);
      }
      expect(fightStageFromName('nowhere'), isNull);
      expect(fightStageFromName(''), isNull);
    });

    test('the world gives its places a stage: halls inside, land outside', () {
      final world = Geography.parse(
          geography: _asset('geography.json'), biomes: _asset('biomes.json'));
      // The prison, the sewers and the cathedral are halls...
      for (final id in [
        'alster_black_hold',
        'alster_undercroft',
        'spire_of_judgment',
        'drowned_cloister',
        'hollow_court',
        'candlehold_lantern_hall',
      ]) {
        expect(world.stageNameOf(id), 'hall', reason: id);
      }
      // ...the rest take the pattern of their land, every one a stage.
      for (final place in world.places.values) {
        if (!place.isSpot) continue;
        final name = world.stageNameOf(place.id);
        expect(name.isEmpty || fightStageFromName(name) != null, isTrue,
            reason: '${place.id}: $name');
      }
      expect(world.stageNameOf('white_wells'), 'dunes');
      expect(world.stageNameOf('akagiri'), 'terraces');
      // A place nobody knows is open country.
      expect(world.stageNameOf('nowhere'), '');
    });
  });

  group('the anomalies', () {
    test('ids are unique, named in both languages, and fit somewhere', () {
      final seen = <String>{};
      for (final anomaly in fieldAnomalies) {
        expect(seen.add(anomaly.id), isTrue, reason: anomaly.id);
        expect(anomaly.stages, isNotEmpty, reason: anomaly.id);
        for (final lang in AppLanguage.values) {
          final name = trFor(lang, 'anomaly_${anomaly.id}');
          expect(name, isNot('anomaly_${anomaly.id}'),
              reason: '${anomaly.id} in ${lang.name}');
        }
      }
      expect(fieldAnomalyById('sandstorm'), isNotNull);
      expect(fieldAnomalyById('nope'), isNull);
    });

    test('every stage can meet an anomaly, under any sky', () {
      for (final stage in FightStage.values) {
        for (final sky in [null, ...WeatherKind.values]) {
          final total = fieldAnomalies
              .map((a) => a.weightUnder(stage, sky))
              .fold<double>(0, (a, b) => a + b);
          expect(total, greaterThan(0), reason: '${stage.name} under $sky');
        }
        expect(trFor(AppLanguage.en, 'stage_${stage.name}'),
            isNot('stage_${stage.name}'));
        expect(trFor(AppLanguage.fr, 'stage_${stage.name}'),
            isNot('stage_${stage.name}'));
      }
    });

    test('the sky decides: a thunderstorm needs rain, a sandstorm likes dust',
        () {
      final thunder = _anomaly('thunderstorm');
      expect(thunder.weightUnder(FightStage.fields, WeatherKind.rain),
          greaterThan(0));
      expect(thunder.weightUnder(FightStage.fields, WeatherKind.clear), 0);
      expect(thunder.weightUnder(FightStage.fields, null), 0);
      // Not on a stage it does not belong to, whatever the sky.
      expect(thunder.weightUnder(FightStage.dunes, WeatherKind.rain), 0);

      final sand = _anomaly('sandstorm');
      expect(sand.weightUnder(FightStage.dunes, WeatherKind.dust),
          greaterThan(sand.weightUnder(FightStage.dunes, null)));
      expect(sand.weightUnder(FightStage.dunes, null), greaterThan(0));
    });

    test('nothing under a roof comes of the sky', () {
      for (final anomaly in fieldAnomalies) {
        if (!anomaly.stages.contains(FightStage.hall)) continue;
        expect(anomaly.skyRule, SkyRule.any, reason: anomaly.id);
      }
      final hall = fieldAnomalies
          .where((a) => a.weightUnder(FightStage.hall, WeatherKind.rain) > 0)
          .map((a) => a.id)
          .toSet();
      expect(hall, {'earth_break', 'collapse', 'blaze'});
    });

    test('no effect is wild: a tick is at most 12 %, a factor 0.6 to 1.4', () {
      for (final anomaly in fieldAnomalies) {
        final tick = anomaly.tick;
        if (tick != null) {
          expect(tick.percent, inInclusiveRange(1, 12), reason: anomaly.id);
        }
        for (final factor in [
          ...anomaly.elements.values,
          ...anomaly.sideElements.values,
          anomaly.sideDamage,
        ]) {
          expect(factor, inInclusiveRange(0.6, 1.4), reason: anomaly.id);
        }
        expect(anomaly.perception, inInclusiveRange(0, 5), reason: anomaly.id);
        // Something has to happen.
        expect(
            tick != null ||
                anomaly.elements.isNotEmpty ||
                anomaly.sideElements.isNotEmpty ||
                anomaly.sideDamage != 1 ||
                anomaly.perception > 0,
            isTrue,
            reason: anomaly.id);
      }
    });

    test('an anomaly that picks a side does something to that side', () {
      for (final anomaly in fieldAnomalies) {
        if (anomaly.shared) continue;
        expect(
            anomaly.tick != null ||
                anomaly.sideElements.isNotEmpty ||
                anomaly.sideDamage != 1,
            isTrue,
            reason: '${anomaly.id} picks a side but nothing falls on it');
      }
    });
  });

  group('a plan', () {
    FieldAnomalyPlan plan(String id, AnomalySide side,
            {int onset = 3, int rounds = 2}) =>
        FieldAnomalyPlan(
            anomaly: _anomaly(id), side: side, onset: onset, rounds: rounds);

    test('is announced a round ahead, lasts its rounds, then is over', () {
      final p = plan('sandstorm', AnomalySide.both);
      expect(p.last, 4);
      expect(p.phaseAt(1), AnomalyPhase.quiet);
      expect(p.phaseAt(2), AnomalyPhase.omen);
      expect(p.phaseAt(3), AnomalyPhase.active);
      expect(p.phaseAt(4), AnomalyPhase.active);
      expect(p.phaseAt(5), AnomalyPhase.over);
      expect(p.isActive(2), isFalse);
      expect(p.isActive(3), isTrue);
    });

    test('changes nothing before it breaks or after it ends', () {
      final p = plan('sandstorm', AnomalySide.both);
      expect(p.damage(10, 'Wind', byParty: true, round: 2), 10);
      expect(p.damage(10, 'Wind', byParty: true, round: 5), 10);
      expect(p.perceptionPenalty(2), 0);
      expect(p.perceptionPenalty(3), 4);
      expect(p.perceptionPenalty(5), 0);
      expect(p.ticksAt(2), isEmpty);
      expect(p.ticksAt(5), isEmpty);
    });

    test('a shared anomaly feeds an element for both sides alike', () {
      final p = plan('sandstorm', AnomalySide.both);
      expect(p.damage(20, 'Wind', byParty: true, round: 3), 25);
      expect(p.damage(20, 'Wind', byParty: false, round: 3), 25);
      expect(p.damage(20, 'Water', byParty: true, round: 3), 17);
      // An element it does not name is left as it is.
      expect(p.damage(20, 'None', byParty: true, round: 3), 20);
      expect(p.damage(0, 'Wind', byParty: true, round: 3), 0);
      expect(p.helpsParty, isNull);
    });

    test('a hurtful anomaly slows the side it falls on, and only that side',
        () {
      final onEnemies = plan('flash_flood', AnomalySide.enemies);
      // Water 1.3 for everyone; the enemies deal 0.85 of it besides.
      expect(onEnemies.damage(20, 'Water', byParty: true, round: 3), 26);
      expect(onEnemies.damage(20, 'Water', byParty: false, round: 3), 22);
      expect(onEnemies.helpsParty, isTrue);
      final onParty = plan('flash_flood', AnomalySide.party);
      expect(onParty.damage(20, 'Water', byParty: true, round: 3), 22);
      expect(onParty.damage(20, 'Water', byParty: false, round: 3), 26);
      expect(onParty.helpsParty, isFalse);
    });

    test('a boon spurs the side it falls on, and only that side', () {
      final wind = plan('tailwind', AnomalySide.party);
      // Wind 1.4 and 1.1 all told for the party; the enemy is spared.
      expect(wind.damage(10, 'Wind', byParty: true, round: 3), 15);
      expect(wind.damage(10, 'Wind', byParty: false, round: 3), 10);
      expect(wind.damage(10, 'Fire', byParty: true, round: 3), 11);
      expect(wind.helpsParty, isTrue);
      expect(plan('tailwind', AnomalySide.enemies).helpsParty, isFalse);
    });

    test('a hit still lands for at least 1', () {
      final p = plan('downpour', AnomalySide.both);
      expect(p.damage(1, 'Fire', byParty: true, round: 3), 1);
    });

    test('a tick falls on the side it is set for', () {
      final rock = plan('rockslide', AnomalySide.enemies);
      final hits = rock.ticksAt(3);
      expect(hits, hasLength(1));
      expect(hits.single.onParty, isFalse);
      expect(hits.single.one, isTrue);
      expect(hits.single.mend, isFalse);
      expect(hits.single.amountFor(200), 24);
      expect(hits.single.amountFor(3), 1);

      final dust = plan('sandstorm', AnomalySide.both);
      expect(dust.ticksAt(3).map((h) => h.onParty).toSet(), {true, false});

      final spring = plan('wellspring', AnomalySide.party);
      expect(spring.ticksAt(3).single.mend, isTrue);
      expect(spring.ticksAt(3).single.onParty, isTrue);
    });

    test('a wound never finishes anyone', () {
      expect(healthAfterHurt(50, 10), 40);
      expect(healthAfterHurt(5, 10), 1);
      expect(healthAfterHurt(1, 10), 1);
      // Someone already down stays down.
      expect(healthAfterHurt(0, 10), 0);
    });
  });

  group('rolling', () {
    test('a fight meets an anomaly about three times in ten', () {
      final random = Random(42);
      var met = 0;
      for (var i = 0; i < 2000; i++) {
        if (rollFieldAnomaly(
                stage: FightStage.dunes,
                sky: WeatherKind.dust,
                random: random) !=
            null) {
          met++;
        }
      }
      expect(met / 2000, closeTo(fieldAnomalyChance, 0.04));
    });

    test('chance 0 never rolls one, chance 1 always does', () {
      final random = Random(1);
      for (var i = 0; i < 100; i++) {
        expect(
            rollFieldAnomaly(
                stage: FightStage.fields, sky: null, random: random, chance: 0),
            isNull);
        expect(
            rollFieldAnomaly(
                stage: FightStage.fields, sky: null, random: random, chance: 1),
            isNotNull);
      }
    });

    test('a rolled anomaly fits its stage and breaks after the first round',
        () {
      final random = Random(7);
      for (final stage in FightStage.values) {
        for (var i = 0; i < 200; i++) {
          final p = pickFieldAnomaly(
              stage: stage,
              sky: WeatherKind.values[i % WeatherKind.values.length],
              random: random)!;
          // Its own, or the older stage's it is kin to (v1.688).
          expect(
              p.anomaly.stages.contains(stage) ||
                  p.anomaly.stages.contains(stage.kin),
              isTrue,
              reason: '${stage.name}: ${p.anomaly.id}');
          expect(p.onset, inInclusiveRange(2, 4));
          expect(p.rounds, inInclusiveRange(2, 3));
          expect(p.side == AnomalySide.both, p.anomaly.shared);
        }
      }
    });

    test('a side-picking anomaly falls on either side across fights', () {
      final random = Random(3);
      final sides = <AnomalySide>{
        for (var i = 0; i < 60; i++)
          planFor(_anomaly('rockslide'), random: random).side,
      };
      expect(sides, {AnomalySide.party, AnomalySide.enemies});
    });

    test('a story\'s own ground is set from the round after the first', () {
      final p = forcedFieldAnomaly('earth_break', side: AnomalySide.enemies)!;
      expect(p.onset, 2);
      expect(p.rounds, 3);
      expect(p.side, AnomalySide.enemies);
      expect(forcedFieldAnomaly('nope'), isNull);
      expect(forcedFieldAnomaly(null), isNull);
    });
  });

  group('in the story\'s choices', () {
    test('a choice names its fight\'s ground, and the modifiers carry it', () {
      final choice = StoryChoice.fromJson({
        'text': 'Fight on',
        'next_id': '100',
        'triggerEnemyId': 'slum_thug',
        'forcedAnomaly': 'sandstorm',
        'forcedStage': 'dunes',
      });
      final modifiers = EncounterModifiers.fromChoice(choice);
      expect(modifiers.forcedAnomaly?.anomaly.id, 'sandstorm');
      expect(modifiers.forcedStage, FightStage.dunes);
      expect(modifiers.isDefault, isFalse);
      // They survive being written out and read back.
      final again = StoryChoice.fromJson(choice.toJson());
      expect(again.forcedAnomaly, 'sandstorm');
      expect(again.forcedStage, 'dunes');
    });

    test('a choice that names nothing leaves the ground to the place', () {
      final choice = StoryChoice.fromJson(
          {'text': 'Fight on', 'next_id': '100', 'triggerEnemyId': 'x'});
      final modifiers = EncounterModifiers.fromChoice(choice);
      expect(modifiers.forcedAnomaly, isNull);
      expect(modifiers.forcedStage, isNull);
      expect(modifiers.isDefault, isTrue);
    });

    test('an expedition stamps its zone\'s stage on the modifiers it has', () {
      const base = EncounterModifiers(isTest: true);
      final stamped = base.copyWith(forcedStage: FightStage.cliffs);
      expect(stamped.forcedStage, FightStage.cliffs);
      expect(stamped.isTest, isTrue);
      // Left alone when nothing is stamped.
      expect(stamped.copyWith(chapter: 3).forcedStage, FightStage.cliffs);
    });

    test('every story choice that names a ground names a real one', () {
      final story = jsonDecode(
              File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
      for (final raw in story.values) {
        final choices = ((raw as Map<String, dynamic>)['choices'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            const [];
        for (final choice in choices) {
          final anomaly = choice['forcedAnomaly']?.toString();
          if (anomaly != null && anomaly.isNotEmpty) {
            expect(fieldAnomalyById(anomaly), isNotNull, reason: anomaly);
          }
          final stage = choice['forcedStage']?.toString();
          if (stage != null && stage.isNotEmpty) {
            expect(fightStageFromName(stage), isNotNull, reason: stage);
          }
        }
      }
    });
  });

  // The city road and the ship deck (v1.660).
  test("a ship's deck and a town's streets are stages of their own", () {
    expect(fightStageOf(BiomePattern.waves, ship: true), FightStage.shipDeck);
    expect(fightStageOf(null, ship: true, indoors: true), FightStage.shipDeck);
    expect(fightStageOf(BiomePattern.dunes, town: true), FightStage.cityRoad);
    // Indoors in a town is a hall.
    expect(fightStageOf(BiomePattern.dunes, town: true, indoors: true),
        FightStage.hall);
    expect(fightStageOf(BiomePattern.dunes), FightStage.dunes);
    expect(fightStageFromName('cityRoad'), FightStage.cityRoad);
    expect(fightStageFromName('shipDeck'), FightStage.shipDeck);
  });

  group('the newer stages (v1.688)', () {
    const newer = {
      FightStage.ruins: 'crumbling_walls',
      FightStage.woods: 'deep_canopy',
      FightStage.ford: 'rising_ford',
      FightStage.burntFields: 'smouldering_stubble',
      FightStage.oasis: 'cool_spring',
      FightStage.caravanRoad: 'dust_devils',
      FightStage.quay: 'slick_stones',
      FightStage.pass: 'thin_air',
    };

    test('each meets an anomaly of its own, and still its kin\'s', () {
      for (final MapEntry(key: stage, value: id) in newer.entries) {
        final own = _anomaly(id);
        expect(own.stages, {stage}, reason: id);
        expect(own.weightUnder(stage, null), greaterThan(0), reason: id);
        // Only there: not on the older stage it is kin to.
        expect(own.weightUnder(stage.kin, null), 0, reason: id);
        // The kin's anomalies come too.
        final kinOnes = fieldAnomalies.where((a) =>
            a.stages.contains(stage.kin) && a.weightUnder(stage, null) > 0);
        expect(kinOnes, isNotEmpty, reason: stage.name);
      }
    });

    test("a land crossing's fight: its road's terrain, else its biome", () {
      expect(landRouteStage(terrain: 'desert', biome: 'desert'),
          FightStage.caravanRoad);
      expect(landRouteStage(terrain: 'mountain'), FightStage.pass);
      expect(landRouteStage(terrain: 'forest'), FightStage.woods);
      expect(landRouteStage(terrain: 'fen'), FightStage.reeds);
      expect(landRouteStage(terrain: 'ruins', biome: 'ashlands'),
          FightStage.ruins);
      expect(landRouteStage(biome: 'tear'), FightStage.glass);
      expect(landRouteStage(), isNull);
      // Every route on file has its stage.
      final routes = jsonDecode(
              File('assets/gamedata/land_routes.json').readAsStringSync())
          as Map<String, dynamic>;
      for (final MapEntry(:key, :value) in routes.entries) {
        final r = value as Map<String, dynamic>;
        expect(
            landRouteStage(
                terrain: r['terrain']?.toString() ?? '',
                biome: r['biome']?.toString() ?? ''),
            isNotNull,
            reason: key);
      }
    });
  });
}
