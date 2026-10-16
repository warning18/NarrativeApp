// The Shroud's boon (Lysa's arc, v1.416): her blood on the piece wakes it.
// A story-only sign, given (never drawn) once `lysa_sacrificed` is set; the
// Void's hold on the character is its cost.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'player_session_provider_test.dart' show baseSession;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final signs = parseSigns(
      jsonDecode(File('assets/gamedata/signs.json').readAsStringSync())
          as Map<String, dynamic>);

  test('the Shroud\'s boon is the story\'s, never an offer\'s', () {
    final boon = signs[shroudBloodSignId]!;
    expect(boon.storyOnly, isTrue);
    expect(boon.patronId, 'open_hand');
    expect(boon.unknownEffectKinds, isEmpty);
    final offerable = offerableSigns('open_hand', signs: signs, held: const []);
    expect(offerable.regular.map((s) => s.id), isNot(contains(boon.id)));
    expect(offerable.regular, isNotEmpty);
  });

  test('its gift, and the Void\'s hold on you', () {
    final boon = signs[shroudBloodSignId]!;
    final scaled = [
      for (final e in boon.effects) e.scaled(shroudBloodRarity, 1),
    ];
    final health = scaled.singleWhere((e) => e.kind.name == 'maxHealth');
    expect(health.value, -12, reason: 'the cost is not scaled up');
    final fury =
        scaled.singleWhere((e) => e.kind.name == 'lowHealthDamagePercent');
    expect(fury.value, greaterThan(6));
    expect(signEffectText(health, AppLanguage.en), contains('-12'));
    expect(signEffectText(health, AppLanguage.en), isNot(contains('+-')));
  });

  test('given once, when her blood is on it', () {
    expect(withStoryBoons(const [], const ['lysa_mercy']), isEmpty);
    final once = withStoryBoons(const [], const ['lysa_sacrificed']);
    expect(once.single.signId, shroudBloodSignId);
    expect(once.single.rarity, shroudBloodRarity);
    expect(withStoryBoons(once, const ['lysa_sacrificed']), once);
  });

  test('the session gives it with the flag', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = PlayerSessionNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await notifier.loadSession(baseSession());
    await notifier.applyChoiceEffects(
        flagsToAdd: const ['lysa_sacrificed', 'void_marked']);
    expect(notifier.state.heldSigns.map((h) => h.signId),
        contains(shroudBloodSignId));
  });
}
