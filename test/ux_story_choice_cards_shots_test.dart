// The choice card at Core's three weights on real choices (UX_SHOTS=<folder>):
// the real ChoiceCard, the real StoryChoice records of the story, the weight and
// the clan Core's choiceWeightOf and choiceClanOf give them, the deep frames,
// dark and light at 360 wide. Drawn only with UX_SHOTS.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/story_plates.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/choice_card.dart';
import 'package:narrative_data_app/widgets/clan_offer_gifts.dart' show CardTier;
import 'package:narrative_data_app/widgets/story_panel.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('the weights on real choices', skip: shots == null,
      (tester) async {
    await tester.runAsync(loadAppFonts);
    await tester.runAsync(StoryFrames.instance.preload);
    final dag =
        jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
            as Map<String, dynamic>;
    final factions =
        jsonDecode(File('assets/gamedata/factions.json').readAsStringSync())
            as Map<String, dynamic>;
    final subclans =
        jsonDecode(File('assets/gamedata/subclans.json').readAsStringSync())
            as Map<String, dynamic>;
    final subclanClans = {
      for (final e in subclans.entries)
        e.key: (e.value as Map)['clan']?.toString() ?? '',
    };

    StoryChoice find(String node, String startsWith) {
      final raw = ((dag[node] as Map)['choices'] as List).firstWhere(
          (c) => (c as Map)['text'].toString().startsWith(startsWith));
      return StoryChoice.fromJson(Map<String, dynamic>.from(raw as Map));
    }

    // A plain one: the first choice whose effects are only the story's flags.
    final plain = [
      for (final node in dag.values)
        for (final raw in (node as Map)['choices'] as List? ?? const [])
          StoryChoice.fromJson(Map<String, dynamic>.from(raw as Map)),
    ].firstWhere((c) =>
        choiceWeightOf(c) == ChoiceWeight.plain &&
        c.text.length > 24 &&
        c.text.length < 48);
    final choices = [
      plain,
      find('2010', 'Walk the stalls'),
      find('6010_clan_dominion_2', 'Tell the truth'),
      find('6010_clan_dominion_2', 'Swear that he let'),
      find('7100_clan_dominion_3', 'Open the lamp'),
      find('7003', 'Cut the taken'),
    ];
    Directory(shots!).createSync(recursive: true);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 760);
    final key = GlobalKey();
    for (final dark in [true, false]) {
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(AppPalette.stitchedInk
              .schemeFor(dark ? Brightness.dark : Brightness.light)),
          home: Builder(builder: (c) {
            final ink = InkColors.of(c);
            return Scaffold(
              appBar: AppBar(title: const Text('Choices')),
              body: ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(14),
                children: [
                  for (final choice in choices) ...[
                    Builder(builder: (_) {
                      final clan = choiceClanOf(choice,
                          subclanClans: subclanClans,
                          clans: factions.keys.toSet());
                      final weight = choiceWeightOf(choice);
                      final color = clan.isEmpty
                          ? null
                          : Color(int.parse(
                                  (factions[clan]['color'] as String)
                                      .substring(1),
                                  radix: 16) |
                              0xFF000000);
                      final tag = choice.alignmentMod != 0
                          ? ChoiceTag(
                              'Alignment ${choice.alignmentMod > 0 ? '+' : '−'}${choice.alignmentMod.abs()}',
                              ink.voidColor)
                          : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${weight.name}${clan.isEmpty ? '' : ' · $clan'}',
                                  style: TextStyle(
                                      fontFamily: InkFonts.system,
                                      fontSize: 9,
                                      color: ink.ash)),
                              const SizedBox(height: 3),
                              ChoiceCard(
                                icon: Icons.chat_bubble_outline,
                                color: ink.tide,
                                text: choice.text,
                                goLabel: 'Go',
                                tag: tag,
                                weight: weight,
                                clanColor: color,
                                richTier: (choice.grantsBannerPieceId ?? '')
                                        .isNotEmpty
                                    ? CardTier.legendary
                                    : CardTier.epic,
                              ),
                            ]),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            );
          }),
        ),
      ));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      late List<int> bytes;
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 2);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
      });
      File('$shots/choice-cards-${dark ? 'dark' : 'light'}.png')
          .writeAsBytesSync(bytes);
    }
  });
}
