// UX: the widgets of the story stage, the fight's status tiles, the
// character's radar card and the settings page on a phone, with the app's own
// fonts: 360 x 740 and 320 x 568, English and French, no overflow
// (qa_smoke_harness.dart; SMOKE_SHOTS=<folder> for the pictures).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/screens/settings_screen.dart';
import 'package:narrative_data_app/widgets/fight_effect_icons.dart';
import 'package:narrative_data_app/widgets/scene_stage.dart';
import 'package:narrative_data_app/widgets/scene_vignette.dart';
import 'package:narrative_data_app/widgets/skills_radar_card.dart';

import 'qa_smoke_harness.dart';

const _long = 'The Inquisition High Warden of the Ashen Quarter';

void main() {
  setUpAll(loadSmokeFonts);

  testWidgets('stage, vignette, status tiles, radar card, settings on a phone',
      (tester) async {
    await runSmoke(tester, [
      const SmokeCase(
        'scene_stage_long',
        Padding(
          padding: EdgeInsets.all(12),
          child: SceneStage(
            foeId: 'slum_thug',
            foeName: _long,
            prompt: 'What do you say to the man who keeps the third piece?',
            balloon: 'I have come a long way, and I will not leave without it.',
            doorName: 'The Drowned Stair of the Ashen Quarter',
            doorLit: true,
          ),
        ),
      ),
      const SmokeCase(
        'scene_vignette_faced',
        Padding(
          padding: EdgeInsets.all(12),
          child: SceneVignette(
            heroName: 'Aurel Vane of the Crows',
            prompt: 'What do you say to the man who keeps the third piece?',
            faced:
                SceneFaced(id: 'slum_thug', name: _long, role: 'High Warden'),
          ),
        ),
      ),
      const SmokeCase(
        'scene_vignette_folded',
        Padding(
          padding: EdgeInsets.all(12),
          child: SceneVignette(
            heroName: 'Aurel Vane of the Crows',
            prompt: 'What do you say?',
            folded: true,
          ),
        ),
      ),
      SmokeCase(
        'fight_status_tiles',
        Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final badge in <String?>[null, '1/2', '12'])
                FightStatusTile(
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                  label: 'Momentum',
                  body: 'Fills as the party lands blows.',
                  closeHint: 'Tap to close',
                  badge: badge,
                ),
            ]),
          ),
        ),
      ),
      const SmokeCase('skills_radar_card', SkillsRadarCard()),
      for (final view in const ['skills', 'detail'])
        SmokeCase(
          'skills_radar_card_$view',
          const SkillsRadarCard(),
          act: (tester) async {
            await tester.tap(find.byKey(Key('character_view_$view')));
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
      const SmokeCase('settings', SettingsScreen(), bare: true),
    ]);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
