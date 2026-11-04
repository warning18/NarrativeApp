// The data files leave a field out where its reader's default holds
// (v1.776, N7 of docs/proposals/core-improvements-2.md): skills.json no
// longer writes healthMod 0 and isActiveSkill true, nor zones.json an empty
// rewardDiceId and rewardAllyId, nor dice.json a face's element "None" and
// empty linkedSkillID. The record editor must not write them back on save,
// and must keep the keys its form doesn't show.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/screens/game_db_record_editor_screen.dart';

Map<String, dynamic> _asset(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('the default-valued fields stay out of the data files', () {
    for (final skill in _asset('skills').values.cast<Map>()) {
      expect(skill.containsKey('healthMod'), isFalse);
      expect(skill.containsKey('isActiveSkill'), isFalse);
    }
    for (final zone in _asset('zones').values.cast<Map>()) {
      expect(zone['rewardDiceId'] ?? 'none', isNot(''));
      expect(zone['rewardAllyId'] ?? 'none', isNot(''));
    }
    for (final die in _asset('dice').values.cast<Map>()) {
      for (final face in (die['faces'] as List).cast<Map>()) {
        expect(face['element'] ?? 'Fire', isNot('None'));
        expect(face['linkedSkillID'] ?? 'x', isNot(''));
      }
    }
  });

  testWidgets(
      'a save writes back neither the defaults a record left out nor drops '
      'the keys the form does not show', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(navigatorKey: navigator, home: const Scaffold()),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(Scaffold)));
    final table = await tester.runAsync(() =>
        container.read(gameDbProvider(skillsSchema).notifier).whenLoaded());
    final record = {
      ...(table!['fireball'] as Map<String, dynamic>),
      'notInTheForm': 7,
    };
    expect(record.containsKey('healthMod'), isFalse,
        reason: 'the case this is about');

    Future<Map<String, dynamic>> saveFrom(Map<String, dynamic> from,
        {String? damageMod, String? healthMod}) async {
      navigator.currentState!.push(MaterialPageRoute(
        builder: (_) => GameDbRecordEditorScreen(
          schema: skillsSchema,
          recordKey: 'fireball',
          initialRecord: from,
        ),
      ));
      await tester.pumpAndSettle();
      Finder field(String label) => find.byWidgetPredicate(
          (w) => w is TextField && (w.decoration?.labelText ?? '') == label);
      if (damageMod != null) {
        await tester.scrollUntilVisible(field('Damage Mod'), 200,
            scrollable: find.byType(Scrollable).first);
        await tester.enterText(field('Damage Mod'), damageMod);
      }
      if (healthMod != null) {
        await tester.scrollUntilVisible(field('Health Mod'), 200,
            scrollable: find.byType(Scrollable).first);
        await tester.enterText(field('Health Mod'), healthMod);
      }
      await tester.tap(find.byTooltip('Save'));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      return container.read(gameDbProvider(skillsSchema)).value!['fireball']
          as Map<String, dynamic>;
    }

    // Saved untouched: the record comes back as it was.
    final saved = await saveFrom(record);
    expect(saved.containsKey('healthMod'), isFalse);
    expect(saved.containsKey('isActiveSkill'), isFalse);
    expect(saved['notInTheForm'], 7);
    expect(saved['damageMod'], record['damageMod']);
    expect(saved['element'], record['element']);

    // A field the record had is written, edited or not; an absent one
    // only once it is changed.
    final edited = await saveFrom(saved, damageMod: '4', healthMod: '3');
    expect(edited['damageMod'], 4);
    expect(edited['healthMod'], 3);
    expect(edited.containsKey('isActiveSkill'), isFalse);
  });
}
