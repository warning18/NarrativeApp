import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _tremblePrefsKey = 'combat_tremble_enabled';

class TrembleNotifier extends StateNotifier<bool> {
  TrembleNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_tremblePrefsKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tremblePrefsKey, enabled);
  }
}

/// Whether the screen should briefly shake when the player takes damage
/// in combat. Defaults to on; persisted via [SharedPreferences].
final trembleEnabledProvider =
    StateNotifierProvider<TrembleNotifier, bool>((ref) => TrembleNotifier());

const String _chestAutoOpenPrefsKey = 'combat_chest_auto_open';

class ChestAutoOpenNotifier extends StateNotifier<bool> {
  ChestAutoOpenNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_chestAutoOpenPrefsKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chestAutoOpenPrefsKey, enabled);
  }
}

/// Whether the post-fight spoils chest opens itself with every slot
/// already revealed, instead of waiting for the player's tap. Defaults to
/// off (the tap is the point); persisted via [SharedPreferences].
final chestAutoOpenProvider =
    StateNotifierProvider<ChestAutoOpenNotifier, bool>(
        (ref) => ChestAutoOpenNotifier());

const String _alignmentHuntersPrefsKey = 'alignment_hunters_enabled';

class AlignmentHuntersNotifier extends StateNotifier<bool> {
  AlignmentHuntersNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_alignmentHuntersPrefsKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alignmentHuntersPrefsKey, enabled);
  }
}

/// Whether alignment has consequences on the road: angels hunting an
/// Evil character, demons hunting a Good one, and temptations courting a
/// Neutral one (see alignment_events.dart). Defaults to on; persisted via
/// [SharedPreferences].
final alignmentHuntersEnabledProvider =
    StateNotifierProvider<AlignmentHuntersNotifier, bool>(
        (ref) => AlignmentHuntersNotifier());

const String _companionAutoTargetPrefsKey = 'combat_companion_auto_target';

class CompanionAutoTargetNotifier extends StateNotifier<bool> {
  CompanionAutoTargetNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_companionAutoTargetPrefsKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_companionAutoTargetPrefsKey, enabled);
  }
}

/// Whether companions aim their own strikes in a pack fight (focus fire on
/// the player's target, else the weakest enemy) or the player picks every
/// party member's target by hand. Defaults to on; persisted via
/// [SharedPreferences].
final companionAutoTargetProvider =
    StateNotifierProvider<CompanionAutoTargetNotifier, bool>(
        (ref) => CompanionAutoTargetNotifier());

const String _combatEffectsPrefsKey = 'combat_effects_enabled';

class CombatEffectsNotifier extends StateNotifier<bool> {
  CombatEffectsNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_combatEffectsPrefsKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_combatEffectsPrefsKey, enabled);
  }
}

/// Whether fights draw their effects on screen: each skill's and spell's
/// own effect, shields, heals, statuses, and the floating numbers.
/// Defaults to on; persisted via [SharedPreferences].
final combatEffectsEnabledProvider =
    StateNotifierProvider<CombatEffectsNotifier, bool>(
        (ref) => CombatEffectsNotifier());

const String _shipTurnTimerPrefsKey = 'ship_turn_timer_enabled';

class ShipTurnTimerNotifier extends StateNotifier<bool> {
  ShipTurnTimerNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_shipTurnTimerPrefsKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shipTurnTimerPrefsKey, enabled);
  }
}

/// Whether a ship battle's turns are timed (see shipTurnSeconds): on by
/// default; off, a turn waits for End turn. Persisted via
/// [SharedPreferences].
final shipTurnTimerProvider =
    StateNotifierProvider<ShipTurnTimerNotifier, bool>(
        (ref) => ShipTurnTimerNotifier());
