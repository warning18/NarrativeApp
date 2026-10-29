// A clan's power on its card (Wave 12): the tier and value with a bar, the
// places it holds (count and names), the nemesis ribbon, in English and in
// French; and the colour a held place is washed with on the map.
// UX_SHOTS (a folder) saves a picture.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/data/factions.dart' show PoliticsState;
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/geography_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/clan_peek.dart';
import 'package:narrative_data_app/widgets/clan_power_block.dart';

import 'player_session_provider_test.dart' show baseSession;

final _shotKey = GlobalKey();

Future<void> _loadFonts() async {
  for (final (family, files) in [
    (
      InkFonts.system,
      ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']
    ),
    (
      InkFonts.prose,
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    (InkFonts.display, ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(
          ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync())));
    }
    await loader.load();
  }
  final icons = File('/tmp/flutter/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (Platform.environment['UX_SHOTS'] != null) await _loadFonts();
  });

  Future<ProviderContainer> open(WidgetTester tester,
      {required String factionId,
      PoliticsState politics = const PoliticsState(),
      String language = 'en'}) async {
    SharedPreferences.setMockInitialValues(
        {'app_language': language, 'tutorial_enabled': false});
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(appLanguageProvider);
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.runAsync(() async {
      for (final schema in [
        factionsSchema,
        subclansSchema,
        relationsSchema,
        titlesSchema,
        intriguesSchema,
        geographySchema,
        biomesSchema,
      ]) {
        await container.read(gameDbProvider(schema).notifier).whenLoaded();
      }
    });
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          ...baseSession().toJson(),
          'raceId': 'human',
          'professionId': 'warrior',
        }).copyWith(politics: politics)));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(const ColorScheme.dark()),
        builder: (context, child) =>
            RepaintBoundary(key: _shotKey, child: child),
        home: Scaffold(
          body: Center(child: ClanDetailsCard(factionId: factionId)),
        ),
      ),
    ));
    await tester.pump();
    return container;
  }

  testWidgets('the card names the tier, the value and the places held',
      (tester) async {
    final container = await open(tester,
        factionId: 'crows',
        politics: const PoliticsState(power: {'crows': 62}));
    final geography = container.read(geographyProvider);
    final politics = container.read(playerSessionProvider).politics;
    final held = placesOf('crows', geography, politics);
    expect(held, isNotEmpty);

    expect(find.byKey(const Key('clan_power_crows')), findsOneWidget);
    // The ranking: every clan's bar, this one framed, the plate and the legend.
    expect(find.byKey(const Key('ranked_bars')), findsOneWidget);
    expect(find.byKey(const Key('ranked_row_crows')), findsOneWidget);
    expect(find.byKey(const Key('rank_plate_crows')), findsWidgets);
    expect(find.byKey(const Key('rank_legend')), findsOneWidget);
    expect(
        tester
            .widget<Text>(find.byKey(const Key('clan_power_tier_crows')))
            .data,
        trFor(AppLanguage.en, 'power_tier_dominant'));
    expect(
        tester
            .widget<Text>(find.byKey(const Key('clan_power_value_crows')))
            .data,
        '62');
    final count = tester
        .widget<Text>(find.byKey(const Key('clan_holds_count_crows')))
        .data!;
    expect(count, contains('${held.length}'));
    expect(find.byKey(const Key('clan_holds_list_crows')), findsOneWidget);
    expect(find.byKey(const Key('clan_nemesis_crows')), findsNothing);
    await _shot(tester, 'clan-power-card');
  });

  testWidgets('the nemesis wears a red ribbon, in French too', (tester) async {
    await open(tester,
        factionId: 'dominion',
        politics:
            const PoliticsState(nemesis: 'dominion', power: {'dominion': 80}),
        language: 'fr');
    expect(find.byKey(const Key('clan_nemesis_dominion')), findsOneWidget);
    expect(
        find.text(trFor(AppLanguage.fr, 'clan_nemesis_tag')), findsOneWidget);
    expect(
        tester
            .widget<Text>(find.byKey(const Key('clan_power_tier_dominion')))
            .data,
        trFor(AppLanguage.fr, 'power_tier_ascendant'));
    await _shot(tester, 'clan-power-nemesis-fr');
  });

  testWidgets('a long list of places is cut with a "+N more"', (tester) async {
    final container = await open(tester, factionId: 'dominion');
    final geography = container.read(geographyProvider);
    final politics = container.read(playerSessionProvider).politics;
    final held = placesOf('dominion', geography, politics);
    final chips = find.descendant(
        of: find.byKey(const Key('clan_holds_list_dominion')),
        matching: find.byType(Container));
    if (held.length > powerBlockMaxPlaces) {
      expect(chips, findsNWidgets(powerBlockMaxPlaces));
      expect(
          find.text(trFor(AppLanguage.en, 'holds_more')
              .replaceAll('{n}', '${held.length - powerBlockMaxPlaces}')),
          findsOneWidget);
    } else {
      expect(chips, findsNWidgets(held.length));
    }
  });

  testWidgets('a held place is washed in its clan colour, red for the nemesis',
      (tester) async {
    final container = await open(tester, factionId: 'crows');
    final factions = container.read(factionsProvider);
    expect(holderTint('', factions, null), isNull);
    expect(holderTint('nobody', factions, null), isNull);
    expect(holderTint('crows', factions, 'crows'), nemesisRed);
    expect(holderTint('crows', factions, 'dominion'),
        Color(factions['crows']!.color | 0xFF000000));
  });
}
