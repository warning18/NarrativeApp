// Signs (v1.192), the content: the shipped patrons.json and signs.json
// parse, every effect is one the fight knows and sits on a sign of the
// right slot, every line reads in both languages, and every patron can be
// met.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// The kinds a sign of [slot] may carry: its own slot's, and passives only
/// on passives.
const Map<SignSlot, Set<SignEffectKind>> _slotKinds = {
  SignSlot.strike: {
    SignEffectKind.strikeDamagePercent,
    SignEffectKind.strikeFlat,
    SignEffectKind.strikeElement,
    SignEffectKind.strikeStatus,
    SignEffectKind.strikeKeyword,
  },
  SignSlot.guard: {
    SignEffectKind.guardBlockPercent,
    SignEffectKind.guardFlat,
    SignEffectKind.guardHeal,
    SignEffectKind.guardRetaliate,
    SignEffectKind.guardStatus,
  },
  SignSlot.mend: {
    SignEffectKind.mendPercent,
    SignEffectKind.mendParty,
    SignEffectKind.mendShield,
    SignEffectKind.mendCleanse,
  },
  SignSlot.spell: {
    SignEffectKind.manaFlat,
    SignEffectKind.spellDamagePercent,
    SignEffectKind.spellCostLess,
    SignEffectKind.spellStatus,
  },
};

void main() {
  final patronsDb = _json('assets/gamedata/patrons.json');
  final signsDb = _json('assets/gamedata/signs.json');
  final patrons = parsePatrons(patronsDb);
  final signs = parseSigns(signsDb);
  final story = File('assets/Cleaned_Narrative_DAG.json').readAsStringSync();
  final nodes = (jsonDecode(story) as Map<String, dynamic>).keys.toSet();

  test('eleven patrons and 66 signs, nine of them duos', () {
    expect(patrons, hasLength(11));
    expect(signs, hasLength(66));
    expect(signs.values.where((s) => s.isDuo), hasLength(9));
    expect(
        patrons.values.where((p) => p.kind == PatronKind.clan), hasLength(5));
    expect(
        patrons.values.where((p) => p.kind == PatronKind.tribe), hasLength(4));
    expect(patrons[choirPatronId]!.minAlignment, 10);
    expect(patrons[pitPatronId]!.maxAlignment, -10);
    expect(patrons[choirPatronId]!.nameFor(AppLanguage.fr), 'Le Chœur');
    expect(patrons[pitPatronId]!.nameFor(AppLanguage.fr), 'La Fosse');
  });

  test('every patron can be met, reads in both languages, has an icon', () {
    for (final patron in patrons.values) {
      final id = patron.id;
      expect(patronsDb[id]['id'], id);
      expect(patron.nameFr, isNotEmpty, reason: id);
      expect(patron.intro, isNotEmpty, reason: id);
      expect(patron.introFr, isNotEmpty, reason: id);
      expect(patron.greetings.length, inInclusiveRange(3, 4), reason: id);
      expect(patron.greetingsFr, hasLength(patron.greetings.length),
          reason: id);
      expect(patronIconNames, contains(patron.icon), reason: id);
      expect(patron.color >> 24, 0xFF, reason: id);
      final flag = patron.unlockFlag;
      if (flag.isEmpty) continue;
      // A place found (found_<node>) or a flag the story sets.
      final place = flag.startsWith('found_') &&
          nodes.contains(flag.substring('found_'.length));
      expect(place || story.contains('"$flag"'), isTrue,
          reason: '$id waits for $flag, which nothing sets');
    }
    expect(
        patrons.values
            .where((p) => p.kind != PatronKind.tribe)
            .every((p) => p.unlockFlag.isEmpty),
        isTrue);
  });

  test('every sign is whole: known effects on the right slot', () {
    for (final sign in signs.values) {
      final id = sign.id;
      expect(signsDb[id]['id'], id);
      expect(patrons, contains(sign.patronId), reason: id);
      expect(sign.nameFr, isNotEmpty, reason: id);
      expect(sign.flavour, isNotEmpty, reason: id);
      expect(sign.flavourFr, isNotEmpty, reason: id);
      expect(sign.unknownEffectKinds, isEmpty, reason: id);
      expect(sign.effects, isNotEmpty, reason: id);
      final raw = (signsDb[id]['effects'] as List).cast<Map>();
      expect(sign.effects, hasLength(raw.length), reason: id);
      for (final effect in sign.effects) {
        final own = _slotKinds[sign.slot];
        final slotKind =
            _slotKinds.values.any((kinds) => kinds.contains(effect.kind));
        if (own == null) {
          expect(slotKind, isFalse, reason: '$id: ${effect.kind} on a passive');
        } else {
          expect(own, contains(effect.kind), reason: '$id: ${effect.kind}');
        }
        switch (effect.kind) {
          case SignEffectKind.strikeKeyword:
            expect(signStrikeKeywords, contains(effect.keyword), reason: id);
          case SignEffectKind.strikeElement:
            expect([
              'Fire',
              'Wind',
              'Earth',
              'Water',
              'Electricity',
              'Void',
              'Ice',
              'Light'
            ], contains(effect.element), reason: id);
            expect(effect.value, greaterThan(0), reason: id);
          case SignEffectKind.strikeStatus:
          case SignEffectKind.guardStatus:
          case SignEffectKind.spellStatus:
            expect(effect.status, isNotNull, reason: id);
            expect(effect.chance, inInclusiveRange(1, signChanceCap),
                reason: id);
          case SignEffectKind.stat:
            expect(signStatNames, contains(effect.stat), reason: id);
            expect(effect.value, greaterThan(0), reason: id);
          case SignEffectKind.secondWind:
            break;
          default:
            expect(effect.value, greaterThan(0), reason: id);
        }
      }
      if (sign.isDuo) {
        expect(sign.requiresPatrons, hasLength(2), reason: id);
        expect(sign.requiresPatrons, contains(sign.patronId), reason: id);
        expect(patrons.keys, containsAll(sign.requiresPatrons), reason: id);
      }
      // Pacts are the Pit's, and every Pit sign has one.
      expect(sign.pact != null, sign.patronId == pitPatronId, reason: id);
    }
  });

  test('every patron has three signs of their own to offer', () {
    for (final patron in patrons.values) {
      final own = offerableSigns(patron.id, signs: signs, held: const []);
      expect(own.regular.length, greaterThanOrEqualTo(signOfferSize),
          reason: patron.id);
    }
  });

  test('every line reads, numbers in, in both languages', () {
    final nbsp = RegExp('[^ ][:;!?%»]');
    for (final sign in signs.values) {
      for (final rarity in SignRarity.values) {
        for (final lang in AppLanguage.values) {
          final lines = [
            ...signEffectLines(sign, rarity, maxSignLevel, lang),
            if (sign.pact != null) pactCurseText(sign.pact!, lang),
          ];
          for (final line in lines) {
            expect(line, isNot(contains('{')), reason: '${sign.id}: $line');
            expect(line, isNot(contains('sign_')), reason: '${sign.id}: $line');
            expect(line, isNot(contains('_label')),
                reason: '${sign.id}: $line');
            expect(line, isNot(contains('keyword_')),
                reason: '${sign.id}: $line');
            if (lang == AppLanguage.fr) {
              // A non-breaking space before : ; ! ? % and », as in the
              // content itself.
              expect(nbsp.hasMatch(line), isFalse,
                  reason: '${sign.id}: "$line"');
            }
          }
        }
      }
    }
    for (final rarity in SignRarity.values) {
      expect(trFor(AppLanguage.fr, signRarityKey(rarity)),
          isNot(signRarityKey(rarity)));
    }
    for (final slot in SignSlot.values) {
      expect(
          trFor(AppLanguage.fr, signSlotKey(slot)), isNot(signSlotKey(slot)));
    }
  });
}
