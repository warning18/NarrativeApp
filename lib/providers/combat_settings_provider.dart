import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An on/off setting saved in [SharedPreferences] under [prefsKey]. It
/// starts at [defaultValue] and takes the saved value a moment later;
/// anything that reads it once, at the start of something long (a ship
/// battle's clock), awaits [loaded] first so a player's choice is never
/// missed after a restart.
class PersistedFlagNotifier extends StateNotifier<bool> {
  PersistedFlagNotifier(this.prefsKey, {required bool defaultValue})
      : _defaultValue = defaultValue,
        super(defaultValue) {
    loaded = _load();
  }

  final String prefsKey;
  final bool _defaultValue;

  /// Completes once the saved value (if any) is in [state].
  late final Future<void> loaded;

  /// Set when the player changes it before the saved value arrives: the
  /// choice just made wins over the stale saved one.
  bool _changed = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (_changed || !mounted) return;
    state = prefs.getBool(prefsKey) ?? _defaultValue;
  }

  Future<void> setEnabled(bool enabled) async {
    _changed = true;
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, enabled);
  }
}

StateNotifierProvider<PersistedFlagNotifier, bool> _flag(
        String prefsKey, bool defaultValue) =>
    StateNotifierProvider<PersistedFlagNotifier, bool>(
        (ref) => PersistedFlagNotifier(prefsKey, defaultValue: defaultValue));

/// Whether the screen should briefly shake when the player takes damage
/// in combat, or a mighty blow lands. Defaults to on.
final trembleEnabledProvider = _flag('combat_tremble_enabled', true);

/// Whether the post-fight spoils chest opens itself with every slot
/// already revealed, instead of waiting for the player's tap. Defaults to
/// off (the tap is the point).
final chestAutoOpenProvider = _flag('combat_chest_auto_open', false);

/// Whether alignment has consequences on the road: angels hunting an
/// Evil character, demons hunting a Good one, and temptations courting a
/// Neutral one (see alignment_events.dart). Defaults to on.
final alignmentHuntersEnabledProvider =
    _flag('alignment_hunters_enabled', true);

/// Whether companions aim their own strikes in a pack fight (focus fire on
/// the player's target, else the weakest enemy) or the player picks every
/// party member's target by hand. Defaults to on.
final companionAutoTargetProvider = _flag('combat_companion_auto_target', true);

/// Whether fights draw their effects on screen: each skill's and spell's
/// own effect, shields, heals, statuses, and the floating numbers.
/// Defaults to on.
final combatEffectsEnabledProvider = _flag('combat_effects_enabled', true);

/// Whether a ship battle's turns are timed (see shipTurnSeconds): on by
/// default; off, a turn waits for End turn. A battle reads it once, after
/// [PersistedFlagNotifier.loaded].
final shipTurnTimerProvider = _flag('ship_turn_timer_enabled', true);

/// How a ship battle's aimed shot plays (a long press on an enemy room):
/// the marker at its usual speed, slower, or no aimed shots at all (a
/// long press then does nothing, and every shot is a plain one).
enum AimedShots { normal, slow, off }

/// One sweep of the aim bar's marker, for [AimedShots.normal] or slow.
Duration aimSweepFor(AimedShots setting) => setting == AimedShots.slow
    ? const Duration(milliseconds: 1600)
    : const Duration(milliseconds: 900);

class AimedShotsNotifier extends StateNotifier<AimedShots> {
  AimedShotsNotifier() : super(AimedShots.normal) {
    _load();
  }

  static const String prefsKey = 'ship_aimed_shots';
  bool _changed = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (_changed || !mounted) return;
    final saved = prefs.getString(prefsKey);
    state = AimedShots.values
        .firstWhere((v) => v.name == saved, orElse: () => AimedShots.normal);
  }

  Future<void> set(AimedShots value) async {
    _changed = true;
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, value.name);
  }
}

/// How aimed shots play in ship battles (see [AimedShots]).
final aimedShotsProvider =
    StateNotifierProvider<AimedShotsNotifier, AimedShots>(
        (ref) => AimedShotsNotifier());
