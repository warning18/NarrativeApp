// An expedition's written steps (Wave 7, docs/proposals/detours-expeditions.md):
// expedition_steps.json, Narrative's, gives a zone its own road, step by
// step, in the land_events.json shape. A zone with steps walks them in
// order, and its length is theirs (the boss comes after, as before); a zone
// without keeps today's drawn events and its zones.json `expeditionCount`.
//
// Narrative writes the words (texts, place names, notes) and which ability
// a check asks and who a fight is against; the numbers are Core's: a
// check's DC comes from the zone's chapter (harder by [writtenHardDc] for a
// `hard` choice), a rest heals as a detour's does, a discovery turns up one
// of the zone's reward materials, and gold, days, load and hurt come from
// the `gold`, `days`, `cargo` and `healthPct` a choice's notes may carry.
import 'dart:math';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import 'expedition_kinds.dart';
import 'sub_node_engine.dart';

/// The kinds of step.
const List<String> writtenStepTypes = [
  'event',
  'check',
  'fight',
  'discovery',
  'rest',
];

/// What a `hard` choice adds to the chapter's DC.
const int writtenHardDc = 2;

/// A note of a choice's outcome, with the numbers Core gives it.
class WrittenNote {
  const WrittenNote({
    this.en = '',
    this.fr = '',
    this.gold = 0,
    this.days = 0,
    this.cargo = 0,
    this.healthPct = 0,
  });

  static WrittenNote? tryParse(Object? raw) {
    if (raw is! Map) return null;
    int number(String key) => (raw[key] as num?)?.toInt() ?? 0;
    return WrittenNote(
      en: raw['note']?.toString() ?? '',
      fr: raw['note_fr']?.toString() ?? '',
      gold: number('gold'),
      days: number('days'),
      cargo: number('cargo'),
      healthPct: number('healthPct'),
    );
  }

  final String en;
  final String fr;
  final int gold;
  final int days;
  final int cargo;
  final int healthPct;

  String textFor(bool french) => french && fr.isNotEmpty ? fr : en;
}

/// One way through a step.
class WrittenChoice {
  const WrittenChoice({
    required this.id,
    required this.text,
    this.textFr = '',
    this.check,
    this.hard = false,
    this.fight = const [],
    this.success,
    this.fail,
    this.outcome,
  });

  factory WrittenChoice.fromJson(Map raw) {
    final fight = raw['fight'];
    final check = raw['check']?.toString() ?? '';
    return WrittenChoice(
      id: raw['id']?.toString() ?? '',
      text: raw['text']?.toString() ?? '',
      textFr: raw['text_fr']?.toString() ?? '',
      check: check.isEmpty ? null : check,
      hard: raw['hard'] == true,
      fight: fight is List
          ? [for (final id in fight) id.toString()]
          : fight == null || fight.toString().isEmpty
              ? const []
              : [fight.toString()],
      success: WrittenNote.tryParse(raw['success']),
      fail: WrittenNote.tryParse(raw['fail']),
      outcome: WrittenNote.tryParse(raw['outcome']),
    );
  }

  final String id;
  final String text;
  final String textFr;

  /// The ability a roll asks (strength … charisma, perception, luck).
  final String? check;
  final bool hard;

  /// The foes it fights: with a check, the ones the roll gets past.
  final List<String> fight;
  final WrittenNote? success;
  final WrittenNote? fail;
  final WrittenNote? outcome;
}

/// One step of a zone's road.
class WrittenStep {
  const WrittenStep({
    required this.id,
    this.type = 'event',
    this.text = '',
    this.textFr = '',
    this.place = '',
    this.placeFr = '',
    this.material = '',
    this.choices = const [],
  });

  factory WrittenStep.fromJson(Map raw) => WrittenStep(
        id: raw['id']?.toString() ?? '',
        type: writtenStepTypes.contains(raw['type']?.toString())
            ? raw['type'].toString()
            : 'event',
        text: raw['text']?.toString() ?? '',
        textFr: raw['text_fr']?.toString() ?? '',
        place: raw['place']?.toString() ?? '',
        placeFr: raw['place_fr']?.toString() ?? '',
        material: raw['material']?.toString() ?? '',
        choices: [
          for (final c in (raw['choices'] as List? ?? const []))
            if (c is Map) WrittenChoice.fromJson(c),
        ],
      );

  final String id;
  final String type;
  final String text;
  final String textFr;

  /// A discovery's place on the road (its name), and the material it
  /// hints at (kept when it is one of the zone's).
  final String place;
  final String placeFr;
  final String material;
  final List<WrittenChoice> choices;
}

/// expedition_steps.json's steps by zone id: the file is
/// `{"version": 1, "zones": {<zone id>: {"steps": [...]}}}` (or the zones
/// map itself), a zone's record `{"steps": [...]}` or the list itself.
/// Zones without steps are left out.
Map<String, List<WrittenStep>> writtenStepsFrom(Map<String, dynamic> raw) {
  final zones = raw['zones'] is Map ? raw['zones'] as Map : raw;
  final out = <String, List<WrittenStep>>{};
  for (final MapEntry(:key, :value) in zones.entries) {
    final list = value is Map ? value['steps'] : value;
    if (list is! List) continue;
    final steps = [
      for (final s in list)
        if (s is Map) WrittenStep.fromJson(s),
    ];
    if (steps.isNotEmpty) out[key.toString()] = steps;
  }
  return out;
}

/// How many events [zone] holds before its boss: its written [steps], else
/// its `expeditionCount` (3 by default).
int expeditionCountOf(Map<String, dynamic> zone,
        [List<WrittenStep> steps = const []]) =>
    steps.isNotEmpty
        ? steps.length
        : (zone['expeditionCount'] as num?)?.toInt() ?? 3;

/// [zones] with each written zone's `expeditionCount` set to its steps'
/// (for the code that only reads zones.json: the simulator).
Map<String, dynamic> zonesWithWrittenCounts(
  Map<String, dynamic> zones,
  Map<String, List<WrittenStep>> steps,
) =>
    {
      for (final MapEntry(:key, :value) in zones.entries)
        key: steps[key] != null && value is Map<String, dynamic>
            ? {...value, 'expeditionCount': steps[key]!.length}
            : value,
    };

/// The material a discovery turns up: the step's hint when it is one of
/// [rewardMaterials] (the zone's), else one of those at random; null for a
/// zone that names none.
String? discoveryMaterialFor(
  WrittenStep step,
  Map<String, int> rewardMaterials,
  Random random,
) {
  if (rewardMaterials.isEmpty) return null;
  if (rewardMaterials.containsKey(step.material)) return step.material;
  final ids = rewardMaterials.keys.toList()..sort();
  return ids[random.nextInt(ids.length)];
}

/// The foes a written fight of [ids] meets, by the rule a drawn pack
/// follows (SubNodeEngine.filterPackPool, maxPackSizeFor): two or more only
/// from the pack tier (`packEligible`), at most the chapter's pack size; a
/// heavy fights alone. Foes [enemies] doesn't know are dropped.
List<String> writtenFoes(
  List<String> ids, {
  required Map<String, dynamic> enemies,
  required int chapter,
}) {
  final known = [
    for (final id in ids)
      if (enemies.isEmpty || enemies.containsKey(id)) id,
  ];
  if (known.length < 2 || enemies.isEmpty) return known;
  bool pack(String id) =>
      (enemies[id] as Map?)?['packEligible'] as bool? ?? false;
  if (!known.every(pack)) return [known.firstWhere((id) => !pack(id))];
  return known.take(SubNodeEngine.maxPackSizeFor(chapter)).toList();
}

/// [step] as the expedition plays it: a node with its choices, and what
/// each choice costs the road (its notes, and for an escort or a delivery
/// its load and days). Foes [enemies] doesn't know are dropped. A
/// discovery's first way also finds [discoveryGold] (a detour's cache, see
/// detour_scenes.dart).
ExpeditionStep buildWrittenStep(
  WrittenStep step, {
  required String zoneId,
  required int chapter,
  required Random random,
  Map<String, dynamic> enemies = const {},
  Map<String, int> rewardMaterials = const {},
  int discoveryGold = 0,
}) {
  final dc = SubNodeEngine.detourCheckDc(chapter);
  final heal = SubNodeEngine.restHealFor(chapter);
  final found = step.type == 'discovery'
      ? discoveryMaterialFor(step, rewardMaterials, random)
      : null;
  final choices = step.choices.isEmpty
      ? [
          WrittenChoice(
            id: 'on',
            text: trFor(AppLanguage.en, 'expedition_press_on'),
            textFr: trFor(AppLanguage.fr, 'expedition_press_on'),
          ),
        ]
      : step.choices;
  final nodes = <StoryChoice>[];
  final outcomes = <StepOutcome>[];
  for (final (i, choice) in choices.indexed) {
    final foes = writtenFoes(choice.fight, enemies: enemies, chapter: chapter);
    final first = i == 0;
    final gold = (choice.outcome?.gold ?? 0) +
        (choice.success?.gold ?? 0) +
        (step.type == 'discovery' && first ? discoveryGold : 0);
    nodes.add(StoryChoice(
      text: choice.text,
      textFr: choice.textFr.isEmpty ? null : choice.textFr,
      nextId: '',
      checkAbility: choice.check,
      checkDC:
          choice.check == null ? null : dc + (choice.hard ? writtenHardDc : 0),
      triggerEnemyIds: foes,
      avoidFightOnSuccess: choice.check != null && foes.isNotEmpty,
      goldMod: gold,
      // A rest's first way heals as a detour's rest does; a discovery's
      // first turns up one of the zone's materials.
      healAmount: step.type == 'rest' && first ? heal : 0,
      grantMaterials: found != null && first ? {found: 1} : const {},
    ));
    outcomes.add(StepOutcome(
      cargo: choice.outcome?.cargo ?? 0,
      failCargo: choice.fail?.cargo ?? 0,
      days: (choice.outcome?.days ?? 0) + (choice.success?.days ?? 0),
      failDays: choice.fail?.days ?? 0,
      hurtOnFail: min(100, max(0, -(choice.fail?.healthPct ?? 0))),
      note: choice.outcome?.en ?? '',
      noteFr: choice.outcome?.fr ?? '',
      successNote: choice.success?.en ?? '',
      successNoteFr: choice.success?.fr ?? '',
      failNote: choice.fail?.en ?? '',
      failNoteFr: choice.fail?.fr ?? '',
    ));
  }
  final placeLine = step.place.isEmpty ? '' : '${step.place}. ';
  final placeLineFr = step.placeFr.isEmpty ? placeLine : '${step.placeFr}. ';
  return ExpeditionStep(
    key: 'written_${step.id}',
    node: StoryNode(
      id: 'zone_step_${zoneId}_${step.id}',
      description: '$placeLine${step.text}',
      descriptionFr: step.textFr.isEmpty ? null : '$placeLineFr${step.textFr}',
      choices: nodes,
    ),
    outcomes: outcomes,
  );
}
