// QA: the story and journey widgets on a phone, with the app's own fonts: the
// choice cards, the arrival sheet, the way back, the mercy dialog, a locked
// feature and the map's banner pins. 360 x 740 and 320 x 568, English and
// French, no overflow (qa_smoke_harness.dart; SMOKE_SHOTS=<folder> for the
// pictures).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/widgets/arrival_sheet.dart';
import 'package:narrative_data_app/widgets/choice_card.dart';
import 'package:narrative_data_app/widgets/feature_unlock.dart';
import 'package:narrative_data_app/widgets/journey_banner_pin.dart';
import 'package:narrative_data_app/widgets/mercy_dialog.dart';
import 'package:narrative_data_app/widgets/return_notice.dart';

import 'qa_smoke_harness.dart';

const _long = 'Follow the smuggler through the flooded cellars beneath the '
    'Lantern Hall and trust that the tide keeps its word';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  Map<String, dynamic> table(String name) =>
      jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
          as Map<String, dynamic>;
  final clans = ClanData.fromTables(
    factions: table('factions'),
    subclans: table('subclans'),
    relations: table('relations'),
    titles: table('titles'),
  );

  testWidgets('the story widgets read on a phone, EN and FR', (tester) async {
    await runSmoke(tester, [
      SmokeCase(
        'choice_cards',
        Column(children: [
          ChoiceCard(
            icon: Icons.explore,
            color: Colors.amber,
            text: _long,
            goLabel: 'Go',
            notes: const ['Faces: Harbour Watch captain, two guards'],
            leadsTo: 'Leads to the Lantern Hall, chapter 3',
            tag: const ChoiceTag('Dexterity 14', Colors.teal),
            onTap: () {},
            onGo: () {},
          ),
          ChoiceCard(
            icon: Icons.lock,
            color: Colors.grey,
            text: 'The gate is shut until the bells ring twice.',
            goLabel: 'Go',
            locked: true,
            onTap: () {},
          ),
          ChoiceCard(
            icon: Icons.shield,
            color: Colors.red,
            text: 'Hold the line',
            goLabel: 'Go',
            selected: true,
            busy: true,
            tag: const ChoiceTag('Rare · Very long tag label', Colors.purple),
            onTap: () {},
            onGo: () {},
          ),
        ]),
      ),
      SmokeCase(
        'arrival_sheet',
        SizedBox(
          height: 560,
          child: ArrivalSheet(
            title: 'The Lantern Hall of the Dominion',
            continueLabel: 'Continue',
            closeTip: 'Close',
            onContinue: () {},
            child: Text(_long * 4),
          ),
        ),
        bare: true,
      ),
      SmokeCase(
        'return_notice',
        Align(
          alignment: Alignment.topCenter,
          child: ReturnNotice(
              place: 'The Lantern Hall of the Dominion', onTap: () {}),
        ),
        bare: true,
      ),
      SmokeCase(
        'mercy_dialog',
        Consumer(
          builder: (context, ref, _) => MercyDialog(
            enemyId: 'slum_thug',
            name: 'Harbour Watch captain',
            clan: clans.faction('dominion'),
            lang: ref.watch(appLanguageProvider),
            read: null,
            onChoose: (_) {},
          ),
        ),
      ),
      SmokeCase(
        'locked_features',
        Column(children: [
          for (final feature in GameFeature.values)
            FeatureLockedTile(feature: feature),
          const FeatureLockedTile(
              feature: GameFeature.levelUp,
              title: 'The long name of a shut part of the camp'),
        ]),
      ),
      SmokeCase(
        'banner_pins',
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final cat in JourneyPinCat.values)
            for (final lit in [false, true])
              BannerPin(
                  cat: cat,
                  color: Colors.deepOrange,
                  dark: true,
                  lit: lit,
                  scale: 1.5),
          const BannerPin(
              cat: JourneyPinCat.way,
              color: Colors.grey,
              dark: false,
              icon: Icons.lock,
              unknown: true),
        ]),
      ),
    ]);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
