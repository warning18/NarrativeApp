// The sub-clans' variants and upgrades, and rank II (v5.2 step 2b): a
// specialisation (specialisations.dart) held, its main clan's sub-clans
// bend it from Trusted (a variant changes how it works, an upgrade raises
// its number), and at Sworn the clan raises it to rank II (half again its
// number). spec_variants.json holds them: Narrative's words, the
// specialisation each bends and the sub-clan that offers it; the numbers
// are here, in [SpecMods], which reads what a character holds.
import 'dart:math';

import '../data/text_placeholders.dart';
import '../l10n/app_locale.dart';
import 'specialisations.dart';
import 'status_effect.dart';

/// What a gift of spec_variants.json is.
enum SpecVariantKind { variant, upgrade, rank }

/// One record of spec_variants.json.
class SpecVariantInfo {
  const SpecVariantInfo({
    required this.id,
    required this.spec,
    required this.kind,
    this.subclanId = '',
    this.name = '',
    this.nameFr = '',
    this.text = '',
    this.textFr = '',
    this.voice = '',
    this.voiceFr = '',
  });

  static SpecVariantInfo? tryParse(String id, Object? raw) {
    if (raw is! Map) return null;
    final spec = specNamed(raw['spec']?.toString());
    final kind = SpecVariantKind.values
        .where((k) => k.name == raw['kind']?.toString())
        .firstOrNull;
    if (spec == null || kind == null) return null;
    String text(String key) => raw[key]?.toString() ?? '';
    return SpecVariantInfo(
      id: id,
      spec: spec,
      kind: kind,
      subclanId: text('subclan'),
      name: text('name'),
      nameFr: text('name_fr'),
      text: text('text'),
      textFr: text('text_fr'),
      voice: text('voice'),
      voiceFr: text('voice_fr'),
    );
  }

  final String id;
  final Spec spec;
  final SpecVariantKind kind;

  /// The sub-clan that offers it ('' for a rank, the main clan's own).
  final String subclanId;
  final String name;
  final String nameFr;
  final String text;
  final String textFr;
  final String voice;
  final String voiceFr;

  String nameFor(bool french) => french && nameFr.isNotEmpty ? nameFr : name;

  /// The gift's line in French or English, its placeholders filled from
  /// the numbers in [SpecMods] (see [specVariantPlaceholders]).
  String textFor(bool french) =>
      _resolved(french && textFr.isNotEmpty ? textFr : text, french);
  String voiceFor(bool french) =>
      _resolved(french && voiceFr.isNotEmpty ? voiceFr : voice, french);

  String _resolved(String line, bool french) => resolvePlaceholders(line,
      specVariantPlaceholders(id), french ? AppLanguage.fr : AppLanguage.en);
}

/// The numbers a spec_variants.json line may name (text_placeholders.dart),
/// read from [SpecMods] with [id] held so they follow the rules: the
/// record's own numbers live in code, not in the file. Every line may name
/// `{rank}` (rank II's "half again", 50); the rest by gift (see
/// docs/proposals/text-placeholders.md).
Map<String, num> specVariantPlaceholders(String id) {
  final mods = SpecMods([id]);
  final base = SpecMods.none;
  num percent(double share) => percentOfShare(share);
  return {
    'rank': 50,
    ...switch (id) {
      'brig_born_berserker' => {'heal': percent(mods.killHealShare)},
      'anvil_deaf_briar_guard' => {'share': percent(mods.briarShare)},
      'order_lantern_vanguard' => {
          'heal': percent(mods.vanguardEvilHeal),
          'baseHeal': percent(base.vanguardEvilHeal),
        },
      'candlebearers_long_vigil' => {
          'heal': percent(mods.vigilShare),
          'baseHeal': percent(base.vigilShare),
        },
      'ember_sisters_ashen_hand' => {
          'cleanse': mods.ashenCleanse,
          'baseCleanse': base.ashenCleanse,
        },
      'cantors_beacon' => {
          'multiplier': mods.beaconBurn,
          'baseMultiplier': base.beaconBurn,
        },
      'tribunal_censer_mage' => {'round': tribunalFromRound},
      'scorched_choir_burden_bearer' => {
          'multiplier': mods.burdenMultiplier,
          'baseMultiplier': base.burdenMultiplier,
        },
      'spire_fallen_burden_bearer' => {'heal': percent(mods.burdenHealShare)},
      'keyholders_tempest_toll' => {'mana': mods.spellDiscount},
      'whisper_ledger_tempest_toll' || 'whisper_ledger_ledger_knife' => {
          'gold': ledgerStealGold
        },
      'moss_choir_fever_blade' => {'heal': percent(mods.rotHealShare)},
      'reliquary_thieves_relicbreaker' => {
          'mana': mods.relicMana,
          'baseMana': base.relicMana,
        },
      'ember_sisters_relicbreaker' => {'heal': percent(mods.relicHealShare)},
      'brig_born_corsairs_eye' => {'gun': mods.gunPercent},
      'scaffolders_trapwright' => {'targets': mods.stunTargets},
      'returned_fen_guide' => {'faces': mods.trailSight},
      _ => const <String, num>{},
    },
  };
}

/// spec_variants.json parsed, by id.
Map<String, SpecVariantInfo> specVariantsFrom(Map<String, dynamic> raw) => {
      for (final MapEntry(:key, :value) in raw.entries)
        if (SpecVariantInfo.tryParse(key, value) case final info?) key: info,
    };

/// The id of [spec]'s rank II.
String rankTwoId(Spec spec) => '${specId(spec)}_ii';

/// Gold a spell or a critical hit steals under the Whisper Ledger.
const int ledgerStealGold = 3;

/// The round from which the Tribunal may refill an empty Well.
const int tribunalFromRound = 4;

/// What the Brig-Born's Broadside adds to the ship's guns, in percent.
const int broadsideGunPercent = 15;

/// What the variants a character holds ([ids]) add to the ship's guns,
/// in percent (the Brig-Born's Broadside).
int specGunPercent(Iterable<String> ids) => SpecMods(ids).gunPercent;

/// The Inquisition's weakening (the Vanguard's heavy blow, the Censer's
/// burn) and the Heron's Wake's slowing: a Weaken of this many percent.
const StatusEffect specWeaken = StatusEffect(
    type: StatusEffectType.weaken, remainingTurns: 2, magnitude: 25);

/// The numbers of the specialisations, variants and ranks a character
/// holds ([held]: their ids, as PlayerSession.specIds keeps them).
class SpecMods {
  SpecMods(Iterable<String> held) : held = {...held};

  static final SpecMods none = SpecMods(const []);

  final Set<String> held;

  bool has(String id) => held.contains(id);
  bool _two(Spec spec) => held.contains(rankTwoId(spec));
  double _rank(Spec spec) => _two(spec) ? 1.5 : 1.0;

  // Berserker
  int get painFury => _two(Spec.berserker) ? 2 : 1;
  bool get painBleeds => has('tar_hands_berserker');
  double get killHealShare => has('brig_born_berserker') ? 0.10 : 0;

  // Briar Guard
  double get briarShare =>
      (has('anvil_deaf_briar_guard') ? 0.5 : briarReflectShare) *
      _rank(Spec.briarGuard);
  bool get briarBreaksGuard => has('quarrymen_briar_guard');
  bool get noHealFaces => has('anvil_deaf_briar_guard');
  int briarBack(int stopped) =>
      stopped <= 0 ? 0 : max(1, (stopped * briarShare).round());

  // Lantern Vanguard
  double get vanguardEvilHeal =>
      (has('order_lantern_vanguard') ? 0.30 : vanguardEvilHealShare) *
      _rank(Spec.lanternVanguard);
  bool get vanguardWeakens => has('inquisition_lantern_vanguard');

  // Long Vigil
  double get vigilShare =>
      (has('candlebearers_long_vigil') ? 0.07 : longVigilHealShare) *
      _rank(Spec.longVigil);
  int vigilMend(int health, int maxHealth) =>
      health * 2 > maxHealth && health < maxHealth
          ? max(1, (maxHealth * vigilShare).round())
          : 0;
  bool get defendFeedsFire => has('last_watch_long_vigil');

  // Ashen Hand
  int get ashenCleanse => has('ember_sisters_ashen_hand') ? 2 : 1;
  double get ashenMend => ashenMendShare * _rank(Spec.ashenHand);
  bool get ashenLight => has('road_exorcists_ashen_hand');

  // Beacon
  double get beaconBurn =>
      (has('cantors_beacon') ? 1.875 : beaconBurnMultiplier) +
      (_two(Spec.beacon) ? 0.25 : 0);
  bool get fireLingers => has('wickwardens_beacon');

  // Censer Mage
  int censerBurnFor(int overflow, int strike) => overflow <= 0
      ? 0
      : max(
          1,
          (overflow * strike * censerBurnPerMana * _rank(Spec.censerMage))
              .round());
  bool get censerWeakens => has('inquisition_censer_mage');
  bool get wellRefill => has('tribunal_censer_mage');

  /// The Tribunal's refill: a third of the Well, once a fight.
  int wellRefillOf(int maxMana) => (maxMana / 3).ceil();

  // Burden-Bearer
  double get burdenMultiplier =>
      (has('scorched_choir_burden_bearer') ? 2.5 : burdenFullWellMultiplier) +
      (_two(Spec.burdenBearer) ? 0.5 : 0);
  double get burdenHealShare => has('spire_fallen_burden_bearer') ? 0.25 : 0;

  // Tempest Toll
  double get tempestShare => tempestLifeShare * _rank(Spec.tempestToll);
  int get spellDiscount => has('keyholders_tempest_toll') ? 1 : 0;
  bool get spellsSteal => has('whisper_ledger_tempest_toll');

  // Fever Blade
  double get rot => rotShare * _rank(Spec.feverBlade);
  bool get rotPasses => has('barkbleeders_fever_blade');
  double get rotHealShare => has('moss_choir_fever_blade') ? 0.2 : 0;

  /// [effects] with the Rot of a critical hit of [hit] added.
  List<StatusEffect> withRotOf(List<StatusEffect> effects, int hit) =>
      withRot(effects, hit, share: rot);

  // Ledger Knife
  double get ledgerStep => ledgerChainStep * _rank(Spec.ledgerKnife);
  bool get critsSteal => has('whisper_ledger_ledger_knife');
  bool get chainKept => has('drowned_debt_ledger_knife');

  // Relicbreaker
  int get relicMana => has('reliquary_thieves_relicbreaker') ? 2 : 1;
  int get relicThreshold => _two(Spec.relicbreaker) ? 2 : relicSureCritMana;
  double get relicHealShare => has('ember_sisters_relicbreaker') ? 0.03 : 0;

  // Corsair's Eye
  int get gunPercent => has('brig_born_corsairs_eye') ? broadsideGunPercent : 0;
  bool get killReshuffles => has('drowned_debt_corsairs_eye');
  double get verdict => verdictMultiplier + (_two(Spec.corsairsEye) ? 0.3 : 0);

  // Trapwright
  int get stunTargets => has('scaffolders_trapwright') ? 2 : 1;
  StatusEffect get stun => StatusEffect(
      type: StatusEffectType.stun,
      remainingTurns: _two(Spec.trapwright) ? 2 : 1);
  bool get trapBreaksGuard => has('quarrymen_trapwright');

  // Fen Guide
  StatusEffect fenPoisonFor(int strike) =>
      fenPoison(strike, share: fenPoisonShare * _rank(Spec.fenGuide));
  bool get fenSlows => has('herons_wake_fen_guide');
  int get trailSight => has('returned_fen_guide') ? 2 : 1;
}
