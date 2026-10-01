import 'dart:math';

import '../combat/dice_faces.dart' show isAssignableFace;
import '../combat/spells.dart';
import 'factions.dart';
import 'offers.dart';
import 'perks.dart';
import 'signs.dart';
import 'sim_combat.dart';
import 'skill_tree.dart';

/// How the simulated character grows (see the playthrough simulator):
/// - [legacy]: the rules before v1.194 -- a skill point a level (and the
///   profession's starting ones) spent on the tree, a perk every even
///   level, a sign every odd level and every boss;
/// - [offers]: v1.194 -- an offer from the clans for each level, each
///   boss and each chapter reached (and the profession's starting points),
///   taken by [preferredSuitor]'s policy.
/// Both share the fight model and how a learned skill finds a face on the
/// die ([SimGrowth.assignSkills]), so their win rates compare.
enum SimProgression { legacy, offers }

/// The gamedata the growth reads.
class SimGrowthTables {
  const SimGrowthTables({
    this.skills = const {},
    this.skillTrees = const {},
    this.items = const {},
    this.spells = const {},
    this.patrons = const {},
    this.signs = const {},
    this.clans = ClanData.empty,
  });

  final Map<String, dynamic> skills;
  final Map<String, dynamic> skillTrees;
  final Map<String, dynamic> items;
  final Map<String, SpellSpec> spells;
  final Map<String, Patron> patrons;
  final Map<String, SignDef> signs;
  final ClanData clans;

  OfferTables get offerTables => OfferTables(
        data: clans,
        signs: signs,
        skills: skills,
        skillTrees: skillTrees,
        items: items,
        spells: spells,
      );
}

/// The perks the simulator takes, best first: what a fight model without a
/// party, rerolls or momentum feels most.
const List<Perk> simPerkPreference = [
  Perk.heavyHand,
  Perk.ironHide,
  Perk.vigor,
  Perk.keenEye,
  Perk.lastStand,
  Perk.lightFeet,
  Perk.apothecary,
  Perk.deepWell,
  Perk.plunderer,
  Perk.quickStudy,
  Perk.steadyHands,
  Perk.battleRhythm,
  Perk.leader,
];

/// The odds the offers' policy takes the suitor of the faction the
/// character stands best with, rather than the best gift.
const double simFavourBestChance = 0.25;

/// A skill's worth on a die face, for the simulator's assignment: what it
/// hits for over a plain blow, what it heals, a status it carries.
double simSkillScore(Map<String, dynamic>? skill) {
  if (skill == null) return 0;
  final mod = (skill['damageMod'] as num?)?.toDouble() ?? 0;
  final mult = (skill['damageMultiplier'] as num?)?.toDouble() ?? 1;
  final heal = (skill['healAmount'] as num?)?.toDouble() ?? 0;
  final status = (skill['inflictsStatus']?.toString() ?? 'None') != 'None';
  const base = 15.0;
  final damage = mult <= 0 ? 0.0 : (base + mod) * max(1.0, mult) - base;
  return damage + heal * 0.7 + (status ? 4 : 0);
}

/// The growth of one simulated character, in either [mode]: what waits
/// (skill points, perk and sign picks; offers), what was taken, and the
/// politics the offers move. The walk calls [levelsReached],
/// [bossBeaten] and [chapterReached], then [settle] to spend what waits.
class SimGrowth {
  SimGrowth({
    required this.mode,
    required this.tables,
    required this.character,
    int startingSkillPoints = 0,
  }) {
    if (mode == SimProgression.legacy) {
      skillPoints = startingSkillPoints;
    } else {
      for (var i = 0; i < startingSkillPoints; i++) {
        pending.add(const OfferTicket(source: OfferSource.start));
      }
    }
  }

  final SimProgression mode;
  final SimGrowthTables tables;
  final SimCharacter character;

  // The old rules.
  int skillPoints = 0;
  int perkPicks = 0;
  int signPicks = 0;

  // The offers.
  final List<OfferTicket> pending = [];
  PoliticsState politics = PoliticsState.empty;
  List<String> titles = const [];
  String activeTitle = '';
  final List<String> boons = [];
  int chapterOffersThrough = 0;

  // Both.
  final Map<String, int> perkRanks = {};
  final List<String> patronsThisLife = [];
  final List<String> patronsMet = [];
  final Map<String, int> favour = {};
  final List<String> signsTaken = [];

  /// Gifts taken, by kind (offers), for the telemetry.
  final Map<GiftKind, int> giftsTaken = {};
  int skillsLearned = 0;

  PerkEffects get perks => perkEffectsFor(perkRanks);

  /// The title worn, the bad ones, the boon while sworn.
  List<SignEffect> get clanEffects => clanEffectsFor(
        activeTitleId: activeTitle,
        heldTitleIds: titles,
        swornBoonIds: boons,
        swornFactionId: politics.swornFactionId,
        data: tables.clans,
      );

  /// What the signs, the title and the boon add up to at [alignment].
  SignEffects effects(int alignment) =>
      tables.signs.isEmpty && clanEffects.isEmpty
          ? SignEffects.none
          : signEffectsFor(character.heldSigns, tables.signs,
              alignment: alignment, extra: clanEffects);

  /// Levels from [before] to [after] reached.
  void levelsReached(int before, int after) {
    if (after <= before) return;
    if (mode == SimProgression.legacy) {
      skillPoints += after - before;
      perkPicks += perkPicksFor(before, after);
      signPicks += signPicksFor(before, after);
    } else {
      for (var i = before; i < after; i++) {
        pending.add(const OfferTicket(source: OfferSource.level));
      }
    }
  }

  /// A boss beaten: a sign (legacy), an offer (offers).
  void bossBeaten() {
    if (mode == SimProgression.legacy) {
      signPicks++;
    } else {
      pending.add(const OfferTicket(source: OfferSource.boss));
    }
  }

  /// A new chapter reached: an offer from chapter 2 on, once (offers).
  void chapterReached(int chapter) {
    if (mode != SimProgression.offers ||
        chapter < 2 ||
        chapter <= chapterOffersThrough) {
      return;
    }
    chapterOffersThrough = chapter;
    pending.add(OfferTicket(source: OfferSource.chapter, detail: '$chapter'));
  }

  /// Spends whatever waits, the simulator's way; returns the alignment
  /// after (vows, pacts and the clans' leans move it).
  int settle({
    required int alignment,
    required Iterable<String> flags,
    required Random random,
  }) {
    var next = alignment;
    if (mode == SimProgression.legacy) {
      _spendSkillPoints(next);
      while (perkPicks > 0) {
        perkPicks--;
        final offer = rollPerkOffer(perkRanks, random);
        if (offer.isEmpty) break;
        final perk = simPerkPreference.firstWhere(offer.contains);
        _takePerk(perk);
      }
      next = _takeSigns(next, flags, random);
    } else {
      next = _takeOffers(next, flags, random);
    }
    return next;
  }

  // --- Skills and the die ---------------------------------------------------

  /// The die's open Skill faces: a Skill face with no skill of its own (or
  /// the basic strike), where a learned skill can go.
  List<int> get _openSkillFaces => [
        for (var i = 0; i < character.diceFaces.length; i++)
          if (character.diceFaces[i]['type'] == 'Skill' &&
              isAssignableFace(character.diceFaces[i]))
            i,
      ];

  /// The mana skill's face, kept as it is (a caster's pool lives on it).
  bool _isManaSkill(String skillId) {
    final skill = tables.skills[skillId] as Map<String, dynamic>?;
    return ((skill?['damageMultiplier'] as num?)?.toDouble() ?? 1) <= 0;
  }

  /// Whether [skillId], learned now, would go on an empty face of the die.
  bool fillsEmptyFace(String skillId) {
    if (character.unlockedSkillIds.contains(skillId)) return false;
    final open = _openSkillFaces;
    final used = open
        .where((i) => character.diceSkillAssignments.containsKey('$i'))
        .length;
    return used < open.length;
  }

  /// Every learned skill to the die's open Skill faces, the best on them:
  /// the mana skill keeps its face, the rest go by [simSkillScore].
  void assignSkills() {
    final open = _openSkillFaces;
    final assignments = <String, String>{};
    final placed = <String>{};
    for (final i in open) {
      final current = character.diceSkillAssignments['$i'];
      if (current != null && _isManaSkill(current)) {
        assignments['$i'] = current;
        placed.add(current);
      }
    }
    final ranked = [
      for (final id in character.unlockedSkillIds)
        if (!placed.contains(id) &&
            !_isManaSkill(id) &&
            tables.skills[id] is Map<String, dynamic>)
          id,
    ]..sort((a, b) {
        final byScore = simSkillScore(tables.skills[b] as Map<String, dynamic>)
            .compareTo(simSkillScore(tables.skills[a] as Map<String, dynamic>));
        return byScore != 0 ? byScore : a.compareTo(b);
      });
    var next = 0;
    for (final i in open) {
      if (assignments.containsKey('$i')) continue;
      if (next >= ranked.length) break;
      assignments['$i'] = ranked[next++];
    }
    character.diceSkillAssignments = assignments;
  }

  void _learn(String skillId) {
    if (character.unlockedSkillIds.add(skillId)) skillsLearned++;
    assignSkills();
  }

  /// The old rules: each point spent on the best next skill the points
  /// cover, one that fills an empty face first.
  void _spendSkillPoints(int alignment) {
    final branches = skillBranchesFor(tables.skillTrees,
        raceId: character.raceId, professionId: character.professionId);
    while (skillPoints > 0) {
      final known = {
        ...character.unlockedSkillIds,
        for (final e in tables.skills.entries)
          if (e.value is Map && (e.value as Map)['isUnlocked'] == true) e.key,
      };
      String? best;
      var bestScore = double.negativeInfinity;
      for (final branch in branches) {
        for (var i = 0; i < branch.skillIds.length; i++) {
          final id = branch.skillIds[i];
          if (!canLearnWithPoints(id,
              branches: branches,
              known: known,
              skills: tables.skills,
              alignmentScore: alignment)) {
            continue;
          }
          final cost = skillPointCostOf(id, branches);
          if (cost > skillPoints) continue;
          final score = (fillsEmptyFace(id) ? 1000 : 0) +
              simSkillScore(tables.skills[id] as Map<String, dynamic>?) / cost;
          if (score > bestScore) {
            best = id;
            bestScore = score;
          }
        }
      }
      if (best == null) return;
      skillPoints -= skillPointCostOf(best, branches);
      _learn(best);
    }
  }

  void _takePerk(Perk perk) {
    final rank = perkRanks[perk.name] ?? 0;
    if (rank >= perkInfo[perk]!.maxRank) return;
    perkRanks[perk.name] = rank + 1;
    if (perk == Perk.vigor) {
      character.maxHealth += vigorHealthPerRank;
      character.currentHealth += vigorHealthPerRank;
    }
  }

  // --- Signs (the old rules) ------------------------------------------------

  int _takeSigns(int alignment, Iterable<String> flags, Random random) {
    var next = alignment;
    if (tables.signs.isEmpty) {
      signPicks = 0;
      return next;
    }
    while (signPicks > 0) {
      final offer = rollSignOffer(
        patrons: tables.patrons,
        signs: tables.signs,
        held: character.heldSigns,
        flags: flags,
        alignment: next,
        random: random,
        patronsThisLife: patronsThisLife,
        patronsMet: patronsMet,
        luck: character.luck + effects(next).stat('luck'),
      );
      final card = offer == null
          ? null
          : preferredSignCard(offer, character.heldSigns, tables.signs);
      final sign = card == null ? null : tables.signs[card.signId];
      if (offer == null || card == null || sign == null) return next;
      character.heldSigns =
          takeSign(character.heldSigns, sign, card.rarity, tables.signs).held;
      next += alignmentShiftFor(sign);
      for (final id in {offer.patronId, sign.patronId}) {
        if (!patronsThisLife.contains(id)) patronsThisLife.add(id);
      }
      if (!patronsMet.contains(offer.patronId)) patronsMet.add(offer.patronId);
      signsTaken.add(sign.id);
      signPicks--;
    }
    return next;
  }

  // --- Offers ---------------------------------------------------------------

  OfferContext _context(int alignment, Iterable<String> flags) => OfferContext(
        data: tables.clans,
        politics: politics,
        signs: tables.signs,
        heldSigns: character.heldSigns,
        skills: tables.skills,
        skillTrees: tables.skillTrees,
        items: tables.items,
        spells: tables.spells,
        raceId: character.raceId,
        professionId: character.professionId,
        knownSkillIds: {
          ...character.unlockedSkillIds,
          for (final e in tables.skills.entries)
            if (e.value is Map && (e.value as Map)['isUnlocked'] == true) e.key,
        },
        ownedItemIds: character.equippedItemIds,
        knownSpellIds: [for (final s in character.knownSpells) s.id],
        flags: flags,
        alignment: alignment,
        patronsThisLife: patronsThisLife,
        favour: favour,
        patronsMet: patronsMet,
        heldTitleIds: titles,
        swornBoonIds: boons,
        perkRanks: perkRanks,
        luck: character.luck + effects(alignment).stat('luck'),
      );

  int _takeOffers(int alignment, Iterable<String> flags, Random random) {
    var next = alignment;
    while (pending.isNotEmpty) {
      final ticket = pending.first;
      final offer = drawOffer(ticket, _context(next, flags), random);
      if (offer == null) return next;
      final suitor = preferredSuitor(
        offer,
        fillsEmptyFace: fillsEmptyFace,
        heldSigns: character.heldSigns,
        signs: tables.signs,
        favourBest: random.nextDouble() < simFavourBestChance,
        politics: politics,
        data: tables.clans,
      );
      if (suitor == null) return next;
      pending.removeAt(0);
      for (final s in offer.suitors) {
        if (!patronsMet.contains(s.factionId)) patronsMet.add(s.factionId);
      }
      next = _applyGift(suitor, next);
      final taken = acceptPolitics(suitor, ticket,
          politics: politics, data: tables.clans);
      politics = taken.politics;
      next += taken.alignment;
      final earned = titlesEarned(titles, politics, tables.clans);
      titles = earned.held;
      activeTitle =
          activeTitleAfter(activeTitle, titles, earned.gained, tables.clans);
      giftsTaken[suitor.gift.kind] = (giftsTaken[suitor.gift.kind] ?? 0) + 1;
    }
    return next;
  }

  int _applyGift(Suitor suitor, int alignment) {
    final gift = suitor.gift;
    switch (gift.kind) {
      case GiftKind.skill:
        _learn(gift.id);
      case GiftKind.sign:
        final sign = tables.signs[gift.id];
        if (sign == null) return alignment;
        character.heldSigns =
            takeSign(character.heldSigns, sign, gift.rarity, tables.signs).held;
        favour[suitor.factionId] = (favour[suitor.factionId] ?? 0) + 1;
        for (final id in {suitor.factionId, sign.patronId}) {
          if (!patronsThisLife.contains(id)) patronsThisLife.add(id);
        }
        signsTaken.add(sign.id);
        return alignment + alignmentShiftFor(sign);
      case GiftKind.object:
        _takeItem(gift.id);
      case GiftKind.title:
        if (!titles.contains(gift.id)) titles = [...titles, gift.id];
        if (activeTitle.isEmpty) activeTitle = gift.id;
      case GiftKind.sworn:
        if (!boons.contains(gift.id)) boons.add(gift.id);
      case GiftKind.perk:
        final perk = perkFromName(gift.id);
        if (perk != null) _takePerk(perk);
    }
    return alignment;
  }

  /// An object given: potions as charges, a spellbook read, gear worn when
  /// it beats what is in its slot.
  void _takeItem(String itemId) {
    final item = tables.items[itemId] as Map<String, dynamic>?;
    if (item == null) return;
    final c = character;
    switch (item['itemType']?.toString()) {
      case 'Potion':
        if (itemId != 'antidote') c.potions += itemId == 'potion_major' ? 2 : 1;
        return;
      case 'Scroll':
        return;
    }
    final spellId = spellbookSpellIdFor(item);
    if (spellId != null) {
      final spell = tables.spells[spellId];
      if (spell != null &&
          canLearnSpell(spell,
              professionId: c.professionId,
              knownSpellIds: [for (final s in c.knownSpells) s.id])) {
        c.knownSpells.add(spell);
      }
      return;
    }
    if (item['isEquippable'] != true) return;
    final slot = item['equipSlot']?.toString() ?? '';
    if (slot.isEmpty) return;
    int score(String? id) {
      final record = tables.items[id] as Map<String, dynamic>?;
      if (record == null) return -1;
      return ((record['attackDamage'] as num?)?.toInt() ?? 0) +
          ((record['armor'] as num?)?.toInt() ?? 0);
    }

    if (score(itemId) > score(c.equippedBySlot[slot])) {
      c.equippedBySlot[slot] = itemId;
    }
  }
}
