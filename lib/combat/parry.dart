import 'dart:math';

/// Targeted defence (v1.214): a Defend face need not only guard its roller.
/// The player may set it on one enemy's telegraphed blow instead: a parry.
///
/// - The face's block counts [parryMultiplier] times, but only against that
///   enemy's blow, and whoever the blow was aimed at.
/// - A blow the parry stops outright is turned aside and answered: the
///   enemy takes [parryCounterShare] of the parry back.
/// - A parry set on an enemy that does not attack that turn is wasted; the
///   roller's own guard is not raised either.
///
/// Everything here is pure, like enemy_affix.dart.
const double parryMultiplier = 1.5;

/// The share of a parry that an outright stop answers with.
const double parryCounterShare = 0.5;

/// The strength of a parry made from a Defend face worth [block].
int parryAmount(int block) =>
    block <= 0 ? 0 : (block * parryMultiplier).round();

/// True when a parry of [parry] stops a blow of [blow] outright.
bool parryStopsBlow(int blow, int parry) => blow > 0 && parry >= blow;

/// What an outright stop answers with, at least 1.
int parryCounter(int parry) => max(1, (parry * parryCounterShare).round());

/// The damage of a blow of [blow] once a parry of [parry], the target's own
/// [block] and the target's [mitigation] (armour and resist) have taken
/// their share, in that order. Never below zero.
int damageAfterParry({
  required int blow,
  required int parry,
  required int block,
  required int mitigation,
}) =>
    max(0, blow - parry - block - mitigation);
