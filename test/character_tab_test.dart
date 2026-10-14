// The Character tab (v1.266): the skills beside the radar at the top, the
// titles as chips (a tap wears one, a hold reads it), perks and signs folded
// to a line each, the Mana card opening the skills on their Spells tab, and
// the race and profession recap as one row per choice. Measured at phone
// widths with the app's own fonts (Ahem is far too wide to say anything).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/character_screen.dart';
import 'package:narrative_data_app/screens/race_profession_screen.dart';
import 'package:narrative_data_app/screens/skills/spells_view.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/title_detail_view.dart';

import 'player_session_provider_test.dart' show baseSession;

Future<void> _loadFonts() async {
  const families = {
    'PixelifySans': [
      'assets/fonts/PixelifySans-Regular.ttf',
      'assets/fonts/PixelifySans-SemiBold.ttf',
    ],
    'Spectral': [
      'assets/fonts/Spectral-Regular.ttf',
      'assets/fonts/Spectral-Medium.ttf',
      'assets/fonts/Spectral-Italic.ttf',
    ],
    'IMFellEnglishSC': ['assets/fonts/IMFellEnglishSC-Regular.ttf'],
  };
  for (final family in families.entries) {
    final loader = FontLoader(family.key);
    for (final path in family.value) {
      loader.addFont(
          Future.value(ByteData.view(File(path).readAsBytesSync().buffer)));
    }
    await loader.load();
  }
}

/// Collects the overflow reports instead of failing on the first.
List<String> _collectOverflows() {
  final seen = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) {
      seen.add(details.exceptionAsString().split('\n').first);
    } else {
      previous?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = previous);
  return seen;
}

Future<ProviderContainer> _open(
  WidgetTester tester,
  Widget home, {
  required Size size,
  bool french = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({if (french) 'app_language': 'fr'});
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final notifier = container.read(playerSessionProvider.notifier);
  container.read(appLanguageProvider);
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.runAsync(() async {
    for (final schema in [
      racesSchema,
      professionsSchema,
      skillsSchema,
      skillTreesSchema,
      itemsSchema,
      spellsSchema,
      factionsSchema,
      subclansSchema,
      relationsSchema,
      titlesSchema,
      intriguesSchema,
      signsSchema,
    ]) {
      await container.read(gameDbProvider(schema).notifier).whenLoaded();
    }
  });
  await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
        ...baseSession().toJson(),
        'characterName': 'Ysolde',
        'raceId': 'human',
        'professionId': 'warrior',
        'statPoints': 2,
        'unlockedSkillIds': ['warrior_shield_bash', 'bulwark_stance'],
        'perkRanks': {'keenEye': 2, 'vigor': 3},
      }).copyWith(
        heldSigns: const [HeldSign(signId: 'inked_strike_ember')],
        heldTitleIds: const ['coal_guard', 'the_marked'],
        activeTitleId: 'coal_guard',
        pendingOffers: const [OfferTicket(source: OfferSource.level)],
      )));
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: buildAppTheme(ColorScheme.fromSeed(
          seedColor: Colors.amber, brightness: Brightness.dark)),
      home: home,
    ),
  ));
  for (var i = 0; i < 6; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  return container;
}

const _tab = Scaffold(body: CharacterScreen(embedded: true));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  Future<void> openTab(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key('character_tab_$key')));
    await tester.pump(const Duration(milliseconds: 250));
  }

  for (final size in const [Size(360, 740), Size(320, 640)]) {
    for (final french in [false, true]) {
      testWidgets(
          'the three tabs fit ${size.width.toInt()} px '
          '${french ? 'in French' : 'in English'}', (tester) async {
        final overflows = _collectOverflows();
        await _open(tester, _tab, size: size, french: french);

        // The header and the tabs: Overview is where it opens.
        for (final k in ['overview', 'gifts', 'pages']) {
          expect(find.byKey(Key('character_tab_$k')), findsOneWidget);
        }
        expect(find.byKey(const Key('character_level_up')), findsOneWidget);
        // Overview: the radar and the skills known, and the alignment.
        expect(find.byKey(const Key('character_radar')), findsOneWidget);
        expect(find.byKey(const Key('character_skill_warrior_shield_bash')),
            findsOneWidget);
        expect(find.byKey(const Key('character_titles')), findsNothing);
        // The Gifts tab says an offer waits.
        expect(find.byKey(const Key('character_gifts_dot')), findsOneWidget);
        expect(overflows, isEmpty, reason: overflows.toSet().join('\n'));

        // Gifts: the offer, the titles as chips, the perks and the signs.
        await openTab(tester, 'gifts');
        expect(find.byKey(const Key('offer_open')), findsOneWidget);
        expect(find.byKey(const Key('title_coal_guard')), findsOneWidget);
        expect(find.byKey(const Key('title_the_marked')), findsOneWidget);
        expect(find.byKey(const Key('perk_owned_keenEye')), findsOneWidget);
        expect(find.byKey(const Key('sign_held_inked_strike_ember')),
            findsOneWidget);
        expect(find.byKey(const Key('character_radar')), findsNothing);
        expect(overflows, isEmpty, reason: overflows.toSet().join('\n'));

        // Pages: mana, the links.
        await openTab(tester, 'pages');
        expect(find.byKey(const Key('character_mana')), findsOneWidget);
        expect(find.byKey(const Key('character_titles')), findsNothing);
        expect(overflows, isEmpty, reason: overflows.toSet().join('\n'));
      });
    }
  }

  testWidgets('a tap wears a title or takes it off; a hold reads it',
      (tester) async {
    final container = await _open(tester, _tab, size: const Size(360, 740));
    String worn() => container.read(playerSessionProvider).activeTitleId;
    expect(worn(), 'coal_guard');

    await openTab(tester, 'gifts');
    await tester.ensureVisible(find.byKey(const Key('title_coal_guard')));
    await tester.tap(find.byKey(const Key('title_coal_guard')));
    await tester.pump();
    expect(worn(), '', reason: 'a tap on the worn title takes it off');
    await tester.tap(find.byKey(const Key('title_coal_guard')));
    await tester.pump();
    expect(worn(), 'coal_guard');

    // A bad title counts while held: no tap, but it can be read.
    await tester.tap(find.byKey(const Key('title_the_marked')));
    await tester.pump();
    expect(worn(), 'coal_guard');
    expect(find.byType(TitleDetailView), findsNothing);
    await tester.longPress(find.byKey(const Key('title_the_marked')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TitleDetailView), findsOneWidget);
    expect(find.text('The Marked'), findsWidgets);
    expect(find.byKey(const Key('title_toggle')), findsNothing,
        reason: 'a brand cannot be worn or taken off');
    expect(worn(), 'coal_guard', reason: 'reading it wears nothing');
    await tester.tap(find.text('Close'));
    await tester.pump(const Duration(milliseconds: 300));

    // The worn one reads with "Take off", and the sheet's button does it.
    await tester.longPress(find.byKey(const Key('title_coal_guard')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TitleDetailView), findsOneWidget);
    expect(find.text('Take off'), findsOneWidget);
    expect(worn(), 'coal_guard');
    await tester.tap(find.byKey(const Key('title_toggle')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(worn(), '');
  });

  testWidgets('the Mana card opens the skills on their Spells tab',
      (tester) async {
    await _open(tester, _tab, size: const Size(360, 740));
    await openTab(tester, 'pages');
    final mana = find.byKey(const Key('character_mana'));
    await tester.ensureVisible(mana);
    await tester.tap(mana);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(SpellsView), findsOneWidget);
  });

  testWidgets('"All skills" opens the skills on the Tree', (tester) async {
    await _open(tester, _tab, size: const Size(360, 740));
    await tester.tap(find.byKey(const Key('character_skills_all')));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('skills_tab_tree')), findsOneWidget);
    expect(find.byType(SpellsView), findsNothing);
  });

  for (final size in const [Size(360, 740), Size(320, 640)]) {
    for (final french in [false, true]) {
      testWidgets(
          'the recap is one row per choice at ${size.width.toInt()} px '
          '${french ? 'in French' : 'in English'}; a tap reads the lore',
          (tester) async {
        final overflows = _collectOverflows();
        await _open(tester, const RaceProfessionScreen(),
            size: size, french: french);
        final race = find.byKey(const Key('sheet_race_card'));
        final profession = find.byKey(const Key('sheet_profession_card'));
        expect(race, findsOneWidget);
        expect(profession, findsOneWidget);
        // A row each, not half a screen.
        expect(tester.getSize(race).height, lessThan(150));
        expect(tester.getSize(profession).height, lessThan(150));
        // The dossier: elements, belongings and the Continue sit within a
        // screen and a bit, not three.
        expect(find.byKey(const Key('sheet_radar')), findsOneWidget);
        // (Just under the fold, so it is built but not on stage yet.)
        final belongings =
            find.byKey(const Key('sheet_belongings'), skipOffstage: false);
        expect(belongings, findsOneWidget);
        expect(tester.getBottomLeft(belongings).dy, lessThan(size.height * 1.4),
            reason: 'the whole dossier is a screen and a bit');
        // The lore is behind the tap.
        expect(find.byKey(const Key('sheet_race_card_lore')), findsNothing);
        await tester.tap(race);
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byKey(const Key('sheet_race_card_lore')), findsOneWidget);
        expect(overflows, isEmpty, reason: overflows.toSet().join('\n'));
      });
    }
  }
}
