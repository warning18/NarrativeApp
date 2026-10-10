/// Enemies that answer what the party does (v1.215). An enemy with a
/// `reaction` in enemies.json watches the party's round and bends its next
/// blow to it:
///
/// - [EnemyResponse.counter]: a heavy blow, [counterHealthShare] of its
///   health or more in one round, provokes it: its next blow lands
///   [counterDamageMultiplier] as hard, aimed at whoever hit it hardest.
/// - [EnemyResponse.press]: when everyone able to act plays a Defend face,
///   it presses the advantage: its next blow lands
///   [pressDamageMultiplier] as hard. Turtling has a price.
/// - [EnemyResponse.huntHealer]: when someone heals, its next blow turns on
///   the member who healed most.
///
/// Everything here is pure, like enemy_affix.dart.
enum EnemyResponse { none, counter, press, huntHealer }

/// The share of its maximum health one round of blows must take off a
/// counter-enemy to provoke it.
const double counterHealthShare = 0.2;

const double counterDamageMultiplier = 1.5;
const double pressDamageMultiplier = 1.3;

/// The response named [name] in enemies.json ('counter', 'press',
/// 'hunt_healer'), or [EnemyResponse.none].
EnemyResponse enemyResponseFromName(String? name) => switch (name) {
      'counter' => EnemyResponse.counter,
      'press' => EnemyResponse.press,
      'hunt_healer' => EnemyResponse.huntHealer,
      _ => EnemyResponse.none,
    };

/// True when [damageThisRound] provokes a counter-enemy of [maxHealth].
bool provokesCounter(int damageThisRound, int maxHealth) =>
    maxHealth > 0 && damageThisRound >= maxHealth * counterHealthShare;

/// True when a round in which [defenders] of the [acting] members played a
/// Defend face makes a press-enemy press: everyone defended, and somebody
/// acted.
bool provokesPress({required int defenders, required int acting}) =>
    acting > 0 && defenders >= acting;

/// The damage multiplier an enemy's next blow carries while [provoked] by a
/// counter or [pressing] a press; they do not stack.
double responseDamageMultiplier(
        {required bool provoked, required bool pressing}) =>
    provoked
        ? counterDamageMultiplier
        : pressing
            ? pressDamageMultiplier
            : 1.0;

/// l10n key of the response's chip.
String enemyResponseLabelKey(EnemyResponse response) =>
    'response_${response.name}';
