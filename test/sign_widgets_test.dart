// Signs (v1.192) on a 360-px phone, in French: the Character tab's signs
// with Titan's Blood spent, and the Clans codex (the Patrons' until
// v1.193: the patrons are the factions). Signs come in the clans' offers
// since v1.194 (see offer_dialog_test.dart).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/clan_widgets.dart';
import 'package:narrative_data_app/widgets/sign_widgets.dart';

import 'player_session_provider_test.dart' show baseSession;

/// The shipped factions: the names and words the dialog shows.
final Map<String, Faction> _factions = parseFactions(
    jsonDecode(File('assets/gamedata/factions.json').readAsStringSync())
        as Map<String, dynamic>);

void main() {
  testWidgets('the Character tab\'s signs and the codex, in French',
      (tester) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'app_language': 'fr'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    container.read(appLanguageProvider);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.runAsync(() async {
      await container
          .read(gameDbProvider(factionsSchema).notifier)
          .whenLoaded();
      await container.read(gameDbProvider(signsSchema).notifier).whenLoaded();
    });
    await tester.runAsync(() => notifier.loadSession(baseSession().copyWith(
          alignmentScore: -12,
          heldSigns: const [
            HeldSign(signId: 'inked_strike_ember', rarity: SignRarity.rare),
            HeldSign(signId: 'choir_passive_last_light'),
            HeldSign(signId: 'pit_passive_red_thirst', pactFightsLeft: 2),
          ],
          titanBlood: 1,
          patronFavour: const {'crows': 4, choirPatronId: 1},
          patronsMet: const ['crows', choirPatronId],
          signPatronsThisLife: const ['crows', pitPatronId],
        )));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [SignsSection(), ClansCodex()]),
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Sang de Titan\u00a0: 1'), findsOneWidget);
    expect(find.text('Poings de braise'), findsOneWidget);
    // Rare: Fire 1 x 1.5 = 2 (rounded).
    expect(
        find.text('Les faces Attaque prennent l’élément Feu, +2\u00a0dégâts.'),
        findsOneWidget);
    // The vow is silent at -12; the pact counts its fights down.
    expect(find.text('Silencieux\u00a0: votre alignement est sous 0.'),
        findsOneWidget);
    expect(find.textContaining('les 2\u00a0prochains combats'), findsOneWidget);
    // The codex: the factions met, their favour, and the Choir closed off.
    expect(
        find.text(_factions['crows']!.nameFor(AppLanguage.fr)), findsOneWidget);
    expect(find.text('Clan · Faveur 4 · niveau 1'), findsOneWidget);
    expect(find.text('Fermé pour vous dans cette vie'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    // A tap on a sign, confirmed, spends the blood on it.
    await tester.tap(find.byKey(const Key('sign_held_inked_strike_ember')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('titan_blood_raise')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    final session = container.read(playerSessionProvider);
    expect(session.titanBlood, 0);
    expect(session.heldSigns.first.level, 2);
    expect(find.text('Rare · Niv.\u00a02'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
