// What a foe is (enemies.json's `kind`, Narrative's docs/proposals/
// foe-kinds.md), and the fight-length menu's rules by foe (docs/proposals/
// profession-clan-mechanics.md "Fight length: a menu tied to the world"):
//
// - Beasts tire: from [foeRuleStartRound], a beast strikes
//   [beastTireStep] softer a round, down to [beastTireFloor] of its blow.
// - The dead crumble: from [foeRuleStartRound], an undead foe loses
//   [undeadCrumbleShare] of its max health each round (never finishing it:
//   the execute does).
// Neither touches a boss, as the execute and morale don't: its fight is
// its own (the Bone Warden and the White Admiral crumbling won them 74%
// and 70% against their 55% and 45%).
// - Morale (fight_length.dart) moves only people and beasts: the dead, the
//   void, constructs, demons, angels and giants hold.
// - An Evil foe ([isEvilFoe]: the Lantern Vanguard's heal) is the void,
//   the dead or a demon -- not merely one weak to Light: the Turned, the
//   cultists and the zealots are living people.
//
// Pure rules; the fight screen and the playthrough simulator play them.
import 'dart:math';

/// What a foe is.
enum FoeKind { person, beast, undead, construct, voidborn, demon, angel, giant }

/// The kind of [enemy] (an enemies.json record): its `kind` ('void' is
/// [FoeKind.voidborn]), a person when unwritten.
FoeKind foeKindOf(Map<String, dynamic>? enemy) =>
    switch (enemy?['kind']?.toString()) {
      'beast' => FoeKind.beast,
      'undead' => FoeKind.undead,
      'construct' => FoeKind.construct,
      'void' => FoeKind.voidborn,
      'demon' => FoeKind.demon,
      'angel' => FoeKind.angel,
      'giant' => FoeKind.giant,
      _ => FoeKind.person,
    };

/// Whether [enemy] is an Evil foe: the void, the dead or a demon.
bool isEvilFoe(Map<String, dynamic>? enemy) => switch (foeKindOf(enemy)) {
      FoeKind.voidborn || FoeKind.undead || FoeKind.demon => true,
      _ => false,
    };

/// Whether morale can make [enemy] flee: a person or a beast.
bool canWaver(Map<String, dynamic>? enemy) => switch (foeKindOf(enemy)) {
      FoeKind.person || FoeKind.beast => true,
      _ => false,
    };

/// The round the foe rules start in.
const int foeRuleStartRound = 6;

const double beastTireStep = 0.05;
const double beastTireFloor = 0.5;
const double undeadCrumbleShare = 0.03;

/// The factor on a beast's blow in [round].
double beastTireFactor(int round) => round < foeRuleStartRound
    ? 1.0
    : max(beastTireFloor, 1 - beastTireStep * (round - foeRuleStartRound + 1));

/// [damage] struck by [enemy] in [round]: softer for a tiring beast.
int foeBlow(int damage, Map<String, dynamic>? enemy, int round,
        {bool boss = false}) =>
    damage <= 0 || boss || foeKindOf(enemy) != FoeKind.beast
        ? damage
        : (damage * beastTireFactor(round)).round();

/// What [enemy] of [maxHealth] crumbles away in [round] (the dead only).
int crumble(Map<String, dynamic>? enemy, int maxHealth, int round,
        {bool boss = false}) =>
    boss || foeKindOf(enemy) != FoeKind.undead || round < foeRuleStartRound
        ? 0
        : max(1, (maxHealth * undeadCrumbleShare).round());
