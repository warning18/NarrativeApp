// The stat pick's layout (docs/proposals/stat-picks.md): three offers in a
// row like a clan's gift choice, all in the pick's rarity (a frame in the
// signs' colour, a chip on the rarer ones), what each gain does for the hero
// under it, the picked one's detail under them, at 320 px and in French.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/signs.dart' show SignRarity;
import 'package:narrative_data_app/data/training.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/training_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/sign_widgets.dart'
    show signRarityColor;
import 'package:narrative_data_app/widgets/stat_pick_picker.dart';

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

void main() {
  final paths = trainingPathsFrom(
      jsonDecode(File('assets/gamedata/training_paths.json').readAsStringSync())
          as Map<String, dynamic>);

  /// The pick on the table: a calling, a habit and a turn, all of [tier]
  /// (which makes each gain [points] points).
  PlayerSession session(SignRarity tier, int points) => PlayerSession.fromJson({
        'statPoints': 3,
        'professionId': 'ranger',
        'strength': 8,
        'dexterity': 12,
        'perception': 11,
        'statPickOffer': [
          {
            'path': 'duelist',
            'gains': {'dexterity': points},
            if (tier != SignRarity.common) 'tier': tier.name,
          },
          {
            'path': 'bruiser',
            'gains': {'constitution': points},
            if (tier != SignRarity.common) 'tier': tier.name,
          },
          {
            'path': 'hunter',
            'gains': {'perception': points},
            if (tier != SignRarity.common) 'tier': tier.name,
          },
        ],
      });

  for (final (name, width, french, tier) in [
    ('common, english 360', 360.0, false, SignRarity.common),
    ('rare, english 360', 360.0, false, SignRarity.rare),
    ('epic, english 360', 360.0, false, SignRarity.epic),
    ('heroic, english 360', 360.0, false, SignRarity.heroic),
    ('heroic, french 320', 320.0, true, SignRarity.heroic),
  ]) {
    testWidgets(
        'three offers in the pick\'s rarity, what each does, the'
        ' detail of the picked one ($name)', (tester) async {
      final points = statPickPointsOf(tier);
      SharedPreferences.setMockInitialValues({});
      if (Platform.environment['UX_SHOTS'] != null) await _loadFonts();
      tester.view.physicalSize = Size(width, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [trainingPathsProvider.overrideWith((ref) async => paths)],
        child: MaterialApp(
          theme: buildAppTheme(ColorScheme.fromSeed(seedColor: Colors.brown)),
          home: Scaffold(
            body: RepaintBoundary(
              key: const Key('shot'),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: const SingleChildScrollView(child: StatPickPicker()),
              ),
            ),
          ),
        ),
      ));
      final container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      container.read(playerSessionProvider);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.runAsync(() => container
          .read(appLanguageProvider.notifier)
          .setLanguage(french ? AppLanguage.fr : AppLanguage.en));
      await tester.runAsync(() => container
          .read(playerSessionProvider.notifier)
          .loadSession(session(tier, points)));
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 20));
      }

      for (var i = 0; i < 3; i++) {
        expect(find.byKey(Key('stat_pick_offer_$i')), findsOneWidget);
        // The frame is the rarity's colour (Common stays the quiet seam).
        final material = tester.widget<Material>(find
            .descendant(
                of: find.byKey(Key('stat_pick_offer_$i')),
                matching: find.byType(Material))
            .first);
        final side = (material.shape! as RoundedRectangleBorder).side;
        if (tier == SignRarity.common) {
          expect(side.color, isNot(signRarityColor(SignRarity.rare)));
        } else {
          expect(side.color, signRarityColor(tier));
        }
      }
      // The three share the rarity: a chip on each, but not on Common.
      expect(find.byKey(const Key('stat_pick_tier')),
          tier == SignRarity.common ? findsNothing : findsNWidgets(3));
      // What a gain does for a ranger: Dex is a dodge and (the damage
      // stat) a damage.
      final damage = find.byKey(const Key('stat_pick_effect_dexterity_0'));
      final dodge = find.byKey(const Key('stat_pick_effect_dexterity_1'));
      expect(damage, findsOneWidget);
      expect(dodge, findsOneWidget);
      if (!french) {
        expect(tester.widget<Text>(damage).data, contains('damage'));
        expect(tester.widget<Text>(dodge).data, contains('dodge'));
      }
      await _save(
          tester, 'stat-pick-${tier.name}-${french ? 'fr' : 'en'}-none');

      // The third offer picked: its detail, with the full line.
      await tester.tap(find.byKey(const Key('stat_pick_offer_2')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('stat_pick_detail_hunter')), findsOneWidget);
      expect(
          find.byKey(const Key('stat_pick_gain_perception')), findsOneWidget);
      expect(
          find.byKey(const Key('stat_pick_line_perception')), findsOneWidget);
      expect(
          tester
              .widget<Text>(find.byKey(const Key('stat_pick_line_perception')))
              .data,
          startsWith('+$points'));
      expect(find.byKey(const Key('stat_pick_worth')),
          tier == SignRarity.common ? findsNothing : findsOneWidget);
      expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('stat_pick_take')))
              .onPressed,
          isNotNull);
      await _save(
          tester, 'stat-pick-${tier.name}-${french ? 'fr' : 'en'}-picked');

      // Taking it spends one pick, adds the gain and counts the path.
      await tester.tap(find.byKey(const Key('stat_pick_take')));
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 20));
      }
      final after = container.read(playerSessionProvider);
      expect(after.statPoints, 2);
      expect(after.perception, 11 + points);
      expect(after.trainingTaken, {'hunter': 1});
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _save(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  await tester.runAsync(() async {
    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('shot')));
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}
