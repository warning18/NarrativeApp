// The pixel banners (v1.229): twenty 64x128 sprites drawn by
// tool/gen_banners.py, the six pieces shown on the Character tab (found in
// colour, the rest as silhouettes) and the title's standard on the menu.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/character_screen.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every banner is a 64x128 sprite in hard-edged flat colours', () async {
    for (final id in [
      ...shroudPieceIds,
      titleBannerId,
      for (final f in clanBannerFactionIds) clanBannerId(f)!,
    ]) {
      final file = File('assets/visuals/banners/$id.png');
      expect(file.existsSync(), isTrue, reason: id);
      final codec = await ui.instantiateImageCodec(file.readAsBytesSync());
      final image = (await codec.getNextFrame()).image;
      expect(image.width, pixelBannerSize.width.toInt(), reason: id);
      expect(image.height, pixelBannerSize.height.toInt(), reason: id);
      final data = (await image.toByteData())!;
      final colours = <int>{};
      for (var i = 0; i < data.lengthInBytes; i += 4) {
        if (data.getUint8(i + 3) == 0) continue;
        // hard edges: no half-transparent pixel anywhere
        expect(data.getUint8(i + 3), 255, reason: id);
        colours.add(data.getUint32(i));
      }
      expect(colours.length, lessThan(200), reason: '$id is a limited palette');
    }
  });

  test('every clan in factions.json has its main banner', () {
    final factions =
        json.decode(File('assets/gamedata/factions.json').readAsStringSync())
            as Map;
    final ids = [
      for (final e in factions.entries)
        if (e.value is Map && (e.value as Map).containsKey('color'))
          e.key as String,
    ];
    expect(ids.length, 13);
    for (final id in ids) {
      expect(clanBannerId(id), isNotNull, reason: id);
    }
  });

  test(
      'the six pieces are the ids the story grants, each named in both '
      'languages', () {
    for (final id in shroudPieceIds) {
      for (final lang in AppLanguage.values) {
        final key = 'banner_piece_$id';
        expect(trFor(lang, key), isNot(key), reason: '$id in $lang');
      }
    }
    expect(trFor(AppLanguage.fr, 'banner_piece_unfound'), 'Pas encore trouvé');
  });

  testWidgets('the Character tab lays the Shroud out, found pieces named',
      (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: Scaffold(body: CharacterScreen(embedded: true))),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(CharacterScreen)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'bannerPiecesCollected': ['heirloom_shroud', 'warden_standard'],
        })));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    // The Shroud is on the Pages tab (v1.267).
    await tester.tap(find.byKey(const Key('character_tab_pages')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('2 / 6', skipOffstage: false), findsOneWidget);
    expect(find.byType(PixelBanner, skipOffstage: false), findsNWidgets(6));
    expect(
        find.text('The heirloom piece', skipOffstage: false), findsOneWidget);
    expect(find.text('Not yet found', skipOffstage: false), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}
