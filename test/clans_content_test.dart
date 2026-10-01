// Clans (v1.193), the content: the shipped factions, sub-clans,
// relations, titles and intrigues parse whole; every id they name is
// real (items, skill branches, sub-clans, titles, companions); the
// relations table covers every pair of clans once; and every French line
// keeps French typography and says « vous ».
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// Every string under a key ending in `_fr`, with where it is.
List<(String, String)> _frenchTexts(Object? value, String path,
    {bool french = false}) {
  if (value is String) return french ? [(path, value)] : const [];
  final out = <(String, String)>[];
  if (value is Map) {
    for (final e in value.entries) {
      final key = e.key.toString();
      out.addAll(_frenchTexts(e.value, '$path.$key',
          french: french || key.endsWith('_fr')));
    }
  } else if (value is List) {
    for (var i = 0; i < value.length; i++) {
      out.addAll(_frenchTexts(value[i], '$path[$i]', french: french));
    }
  }
  return out;
}

void main() {
  final factionsDb = _json('factions');
  final subclansDb = _json('subclans');
  final relationsDb = _json('relations');
  final titlesDb = _json('titles');
  final intriguesDb = _json('intrigues');
  final data = ClanData.fromTables(
    factions: factionsDb,
    subclans: subclansDb,
    relations: relationsDb,
    titles: titlesDb,
    intrigues: intriguesDb,
  );
  final items = _json('items');
  final branches = _json('skill_trees');
  final companions = _json('companions');
  const clanIds = [
    'dominion',
    'vigil',
    'compact',
    'mire',
    'crows',
    'penitents'
  ];

  test(
      'thirteen factions: six clans, the Choir and the Pit, four tribes '
      'and the Open Hand', () {
    // The Open Hand (v1.195) is the dead clan, of kind `lost`: no clan
    // among the six, whatever kind the parser reads it as.
    expect(factionsDb['open_hand']['kind'], 'lost');
    expect(
        data.clans.map((f) => f.id).where((id) => id != 'open_hand'), clanIds);
    expect(data.otherworld.map((f) => f.id), ['choir', 'pit']);
    expect(data.tribes.map((f) => f.id),
        unorderedEquals(['giants', 'oni', 'tidekin', 'kindly']));
    expect(data.factions, hasLength(13));
    // The note on the Sworn boons' new kinds is no faction.
    expect(factionsDb['_newKinds'], isA<List>());
    expect(data.factions.keys.where((id) => id.startsWith('_')), isEmpty);
    expect(data.faction('dominion')!.startStanding, -10);
    for (final f in data.factions.values) {
      if (f.id != 'dominion') expect(f.startStanding, 0, reason: f.id);
    }
    // Signs' rules come with them: the Choir and the Pit's alignment, the
    // tribes' flags.
    expect(data.faction('choir')!.patron.minAlignment, 10);
    expect(data.faction('pit')!.patron.maxAlignment, -10);
    for (final tribe in data.tribes) {
      expect(tribe.unlockFlag, isNotEmpty, reason: tribe.id);
    }
  });

  test('every faction reads in both languages and has an icon', () {
    for (final f in data.factions.values) {
      final raw = factionsDb[f.id] as Map<String, dynamic>;
      expect(raw['id'], f.id);
      expect(f.patron.nameFr, isNotEmpty, reason: f.id);
      expect(f.introFor(AppLanguage.fr), isNotEmpty, reason: f.id);
      expect(patronIconNames, contains(f.icon), reason: f.id);
      expect((raw['lean'] as num).abs(), lessThanOrEqualTo(1), reason: f.id);
    }
    for (final clan in data.clans) {
      expect(clan.motto, isNotEmpty, reason: clan.id);
      expect(clan.mottoFr, isNotEmpty, reason: clan.id);
      expect(clan.nameOf, isNotEmpty, reason: clan.id);
      expect(clan.nameOfFr, isNotEmpty, reason: clan.id);
    }
  });

  test('a clan\'s sub-clans, sponsors, objects and Sworn boon are real', () {
    final newKinds = {
      for (final k in factionsDb['_newKinds'] as List)
        (k as Map)['kind'].toString(),
    };
    // The Open Hand has none of these: it is remembered, not joined.
    final lost = data.faction('open_hand')!;
    expect([lost.subclans, lost.sponsors, lost.objects], everyElement(isEmpty));
    expect(lost.sworn, isNull);
    for (final clan in data.clans.where((c) => c.id != 'open_hand')) {
      final id = clan.id;
      expect(clan.subclans, isNotEmpty, reason: id);
      for (final s in clan.subclans) {
        expect(data.subclan(s)?.clanId, id, reason: '$id: $s');
      }
      expect(clan.sponsors, isNotEmpty, reason: id);
      for (final b in clan.sponsors) {
        expect(branches, contains(b), reason: '$id sponsors $b');
      }
      expect(clan.objects, isNotEmpty, reason: id);
      for (final o in clan.objects) {
        expect(items, contains(o.itemId), reason: '$id gives ${o.itemId}');
      }
      final boon = clan.sworn;
      expect(boon, isNotNull, reason: id);
      expect(boon!.nameFr, isNotEmpty, reason: id);
      expect(boon.line, isNotEmpty, reason: id);
      expect(boon.lineFr, isNotEmpty, reason: id);
      expect(boon.rawEffects, isNotEmpty, reason: id);
      // A kind Signs doesn't know yet is one of the new ones the note
      // describes (Part B wires them).
      for (final kind in boon.unknownEffectKinds) {
        expect(newKinds, contains(kind), reason: '$id: $kind');
      }
    }
    for (final other in [...data.tribes, ...data.otherworld]) {
      expect(other.subclans, isEmpty, reason: other.id);
      expect(other.sworn, isNull, reason: other.id);
    }
  });

  test('the 29 sub-clans', () {
    expect(data.subclans, hasLength(29));
    final counts = {
      for (final id in clanIds) id: data.subclansOf(id).length,
    };
    expect(counts, {
      'dominion': 8,
      'vigil': 3,
      'compact': 4,
      'mire': 4,
      'crows': 5,
      'penitents': 5,
    });
    for (final s in data.subclans.values) {
      final raw = subclansDb[s.id] as Map<String, dynamic>;
      expect(clanIds, contains(s.clanId), reason: s.id);
      for (final field in [
        'name_fr',
        'line',
        'line_fr',
        'favour',
        'favour_fr'
      ]) {
        expect(raw[field]?.toString() ?? '', isNotEmpty,
            reason: '${s.id}.$field');
      }
      expect(raw['color'].toString(), startsWith('#'), reason: s.id);
      expect((raw['lean'] as num).abs(), lessThanOrEqualTo(1), reason: s.id);
    }
    expect(data.subclan('inquisition')!.lean, -1);
    expect(data.subclan('wickwardens')!.lean, 1);
  });

  test('relations: seven steps, every pair of clans once, the history', () {
    final relations = data.relations;
    expect([for (final s in relations.steps) s.step], [1, 2, 3, 4, 5, 6, 7]);
    for (final s in relations.steps) {
      expect(s.nameFr, isNotEmpty);
    }
    expect(relations.pairs, hasLength(15));
    final keys = {for (final p in relations.pairs) p.key};
    expect(keys, hasLength(15));
    for (var i = 0; i < clanIds.length; i++) {
      for (var j = i + 1; j < clanIds.length; j++) {
        expect(keys, contains(relationKey(clanIds[i], clanIds[j])));
      }
    }
    for (final p in relations.pairs) {
      expect(p.reason, isNotEmpty, reason: p.key);
      expect(p.reasonFr, isNotEmpty, reason: p.key);
    }
    expect(relations.history, hasLength(12));
    for (final h in relations.history) {
      expect([h.yearFr, h.nameFr, h.textFr], everyElement(isNotEmpty));
    }
    // The design's table: the Vigil and the Penitents share the dead; the
    // Mire has not forgiven Reedholm.
    const opening = PoliticsState.empty;
    expect(alliesOf('penitents', opening, data), contains('vigil'));
    expect(rivalsOf('penitents', opening, data), contains('mire'));
    expect(rivalsOf('vigil', opening, data), contains('dominion'));
  });

  test('titles: real factions and sources, known effects', () {
    expect(data.titles.length, greaterThanOrEqualTo(30));
    final source = RegExp(
        r'^(offer|quest|intrigue|story|tier:(known|trusted|sworn)|mark:foe:[a-z_]+)$');
    for (final t in data.titles.values) {
      final id = t.id;
      expect(titlesDb[id]['id'], id);
      expect(data.factions, contains(t.factionId), reason: id);
      expect(source.hasMatch(t.source), isTrue, reason: '$id: ${t.source}');
      if (t.source.startsWith('mark:foe:')) {
        expect(data.subclans, contains(t.source.substring('mark:foe:'.length)),
            reason: id);
        expect(t.negative, isTrue, reason: id);
      }
      expect([t.nameFr, t.line, t.lineFr], everyElement(isNotEmpty),
          reason: id);
      // Titles act through Signs' effects: every kind one it knows.
      expect(t.unknownEffectKinds, isEmpty, reason: id);
    }
    expect(data.titlesFor(source: 'mark:foe:inquisition'), isNotEmpty);
    for (final clan in clanIds) {
      expect(data.titlesFor(factionId: clan, source: 'tier:sworn'), isNotEmpty,
          reason: clan);
    }
  });

  test('the eight intrigues: six stages each, outcomes that name real ids', () {
    expect(data.intrigues, hasLength(8));
    for (final intrigue in data.intrigues.values) {
      final id = intrigue.id;
      expect(intriguesDb[id]['id'], id);
      expect([
        intrigue.nameFr,
        intrigue.premise,
        intrigue.premiseFr
      ], everyElement(isNotEmpty), reason: id);
      expect([for (final s in intrigue.stages) s.stage], intrigueStageNames,
          reason: id);
      for (final s in intrigue.stages) {
        expect(s.chapter, isNotEmpty, reason: id);
        expect(s.textFr, isNotEmpty, reason: id);
        for (final lang in AppLanguage.values) {
          expect(trFor(lang, s.key), isNot(s.key), reason: s.key);
        }
      }
      expect(intrigue.factionIds, isNotEmpty, reason: id);
      for (final f in intrigue.factionIds) {
        expect(data.factions, contains(f), reason: '$id: $f');
      }
      for (final s in intrigue.subclanIds) {
        expect(data.subclans, contains(s), reason: '$id: $s');
      }
      expect(intrigue.outcomes.length, greaterThanOrEqualTo(2), reason: id);
      for (final outcome in intrigue.outcomes) {
        expect(outcome.nameFr, isNotEmpty, reason: id);
        for (final e in outcome.effects) {
          final what = '$id: ${e.raw}';
          if (e.factionId.isNotEmpty) {
            expect(data.factions, contains(e.factionId), reason: what);
            expect(e.delta, isNot(0), reason: what);
          } else if (e.subclanId.isNotEmpty) {
            expect(data.subclans, contains(e.subclanId), reason: what);
            expect(e.mark, isNotNull, reason: what);
          } else if (e.companionId.isNotEmpty) {
            expect(companions, contains(e.companionId), reason: what);
            expect(e.change, isNotEmpty, reason: what);
          } else if (e.titleId.isNotEmpty) {
            expect(data.titles, contains(e.titleId), reason: what);
          } else {
            expect(e.note, isNotEmpty, reason: what);
            expect(e.noteFr, isNotEmpty, reason: what);
          }
        }
      }
    }
  });

  test('every French line keeps French typography and says « vous »', () {
    final nbsp = RegExp('[^\u00a0][:;!?»]|«[^\u00a0]');
    final tu = RegExp(
        r"(?<!\p{L})(?:(?:tu|toi|ton|ta|tes|te)(?!\p{L})|t['’](?=\p{L}))",
        caseSensitive: false,
        unicode: true);
    var checked = 0;
    for (final name in [
      'factions',
      'subclans',
      'relations',
      'titles',
      'intrigues',
      'signs',
    ]) {
      for (final (path, text) in _frenchTexts(_json(name), name)) {
        checked++;
        expect(nbsp.hasMatch(text), isFalse, reason: '$path: "$text"');
        expect(tu.hasMatch(text), isFalse, reason: '$path: "$text"');
      }
    }
    expect(checked, greaterThan(500));
  });

  test('every tier, mark and cause has its words', () {
    final keys = [
      for (final tier in StandingTier.values) standingTierKey(tier),
      for (final mark in SubclanMark.values) subclanMarkKey(mark),
      for (final cause in [
        'offer',
        'quest',
        'chapter',
        'favour',
        'intrigue',
        'sea',
        'story',
        'edit',
        'sworn_cap',
        'event',
      ])
        'standing_cause_$cause',
    ];
    for (final key in keys) {
      for (final lang in AppLanguage.values) {
        expect(trFor(lang, key), isNot(key), reason: '$key ($lang)');
      }
    }
  });
}
