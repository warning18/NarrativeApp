// The Data tab's downloads (see db_export.dart): a collection's records as
// JSON or a CSV table, the whole database, and every text with its French.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/gamedata/db_export.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/screens/game_data_home_screen.dart';

Map<String, dynamic> _data(String name) =>
    json.decode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// A small RFC 4180 reader, to read back what the exports write.
List<List<String>> _parseCsv(String text) {
  if (text.startsWith('﻿')) text = text.substring(1);
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      row.add(cell.toString());
      cell.clear();
    } else if (c == '\r') {
      continue;
    } else if (c == '\n') {
      row.add(cell.toString());
      cell.clear();
      rows.add(row);
      row = [];
    } else {
      cell.write(c);
    }
  }
  if (cell.isNotEmpty || row.isNotEmpty) {
    row.add(cell.toString());
    rows.add(row);
  }
  return rows;
}

void main() {
  group('one collection', () {
    final ships = _data('enemy_ships');

    test('JSON is every record as stored', () {
      expect(jsonDecode(recordsJson(ships)), ships);
    });

    test('CSV: one row per record, an id column, one column per field', () {
      final csv = recordsCsv(enemyShipsSchema, ships);
      expect(csv.startsWith('﻿'), isTrue, reason: 'accents in Excel');
      final rows = _parseCsv(csv);
      expect(rows.length, ships.length + 1);
      final header = rows.first;
      expect(header.first, 'id');
      // Schema order first.
      expect(header.indexOf('shipName'), lessThan(header.indexOf('maxHull')));
      for (final row in rows) {
        expect(row.length, header.length);
      }
      final skiff = rows.firstWhere((r) => r.first == 'raider_skiff');
      String cell(String column) => skiff[header.indexOf(column)];
      expect(cell('displayName_fr'), 'Esquif de pillards');
      expect(cell('maxHull'), '60');
      // A list is carried as JSON.
      final weapons = jsonDecode(cell('weapons')) as List;
      expect(weapons.first['weaponName'], 'Bow chaser');
    });

    test('quotes, commas and line breaks survive the CSV', () {
      final records = {
        'a': {
          'name': 'Say "hi", then go',
          'name_fr': 'Dites « salut »,\npuis partez',
        },
      };
      final rows = _parseCsv(recordsCsv(enemyShipsSchema, records));
      expect(
          rows[1], ['a', 'Say "hi", then go', 'Dites « salut »,\npuis partez']);
    });
  });

  group('texts', () {
    test('each text beside its French; ids, flags and numbers left out', () {
      final texts = recordTexts({
        'questID': 'q1',
        'questName': 'The Road',
        'questName_fr': 'La Route',
        'critLine': 'Got you!',
        'critLineFr': 'Je vous tiens !',
        'requiredFlags': 'flag_a',
        'goldReward': 30,
        'encounterText': ['One', 'Two'],
        'encounterText_fr': ['Un', 'Deux'],
        'weapons': [
          {'weaponName': 'Gun', 'weaponName_fr': 'Canon', 'damage': 8},
        ],
        'onlyFrench_fr': 'Seulement',
      });
      final byPath = {for (final t in texts) t.path: t};
      expect(byPath.keys, [
        'questName',
        'critLine',
        'encounterText[0]',
        'encounterText[1]',
        'weapons[0].weaponName',
        'onlyFrench',
      ]);
      expect(byPath['questName']!.french, 'La Route');
      expect(byPath['critLine']!.french, 'Je vous tiens !');
      expect(byPath['encounterText[1]']!.english, 'Two');
      expect(byPath['encounterText[1]']!.french, 'Deux');
      expect(byPath['weapons[0].weaponName']!.french, 'Canon');
      expect(byPath['onlyFrench']!.english, '');
    });

    test('a field named like a text shows even with no French twin', () {
      final texts = recordTexts({
        'diceName': 'iron_die',
        'diceName_fr': 'Dé de fer',
        'faces': [
          {'faceName': 'Shield Wall', 'type': 'Defend', 'linkedSkillID': ''},
        ],
        'lockedText': '',
      });
      expect(
          [for (final t in texts) t.path], ['diceName', 'faces[0].faceName']);
      expect(texts.last.english, 'Shield Wall');
      expect(texts.last.french, '');
    });

    test('a text whose French is not written yet still shows', () {
      final texts = recordTexts({'description': 'English only'},
          schemaKeys: {'description', 'description_fr'});
      expect(texts.single.english, 'English only');
      expect(texts.single.french, '');
    });

    test('every collection\'s texts, in English and French, in one CSV', () {
      final collections = [
        for (final schema in gameDbSchemas)
          (schema, _data(schema.assetPath.split('/').last.split('.').first)),
      ];
      final rows = _parseCsv(textsCsv(collections));
      expect(rows.first, ['collection', 'id', 'field', 'english', 'french']);
      final body = rows.skip(1).toList();
      for (final row in body) {
        expect(row.length, 5);
      }
      // A top-level text, a nested one, and a list line.
      expect(
          body.any((r) =>
              r[0] == 'enemy_ships' &&
              r[1] == 'raider_skiff' &&
              r[2] == 'displayName' &&
              r[3] == 'Raider Skiff' &&
              r[4] == 'Esquif de pillards'),
          isTrue);
      expect(
          body.any((r) =>
              r[0] == 'enemy_ships' &&
              r[2] == 'weapons[0].weaponName' &&
              r[4] == 'Canon de chasse'),
          isTrue);
      expect(body.any((r) => r[0] == 'enemies' && r[2] == 'encounterText[0]'),
          isTrue);
      // Every collection with texts shows up; ids and flags never do.
      final collectionsWithTexts = {for (final r in body) r[0]};
      expect(collectionsWithTexts, containsAll(['items', 'quests', 'npcs']));
      expect(body.any((r) => r[2] == 'requiredFlags'), isFalse);
      expect(body.any((r) => r[2] == 'questID'), isFalse);
      // Most texts are translated (dice face names are not, yet).
      final translated = body.where((r) => r[4].isNotEmpty).length;
      expect(translated / body.length, greaterThan(0.8));
    });

    test('the whole database as one long table', () {
      final all = {
        'enemy_ships': _data('enemy_ships'),
        'ships': _data('ships')
      };
      final rows = _parseCsv(allRecordsCsv(all));
      expect(rows.first, ['collection', 'id', 'field', 'value']);
      expect(
          rows.any((r) =>
              r[0] == 'ships' &&
              r[1] == 'rusty_eel' &&
              r[2] == 'baseMaxHull' &&
              r[3] == '100'),
          isTrue);
      expect(jsonDecode(allRecordsJson(all)), all);
    });
  });

  testWidgets('the Data tab downloads every collection and every text',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: Scaffold(body: GameDataHomeScreen())),
    ));
    await tester.tap(find.byKey(const Key('data_download_all')));
    await tester.pumpAndSettle();
    expect(find.text('All records (JSON)'), findsOneWidget);
    expect(find.text('All records (CSV)'), findsOneWidget);
    expect(find.text('All texts (CSV)'), findsOneWidget);

    // Copy the texts: every collection loads, then the CSV is built.
    final copyTexts = find.descendant(
        of: find.byKey(const Key('data_export_game_texts.csv')),
        matching: find.byIcon(Icons.copy_outlined));
    await tester.tap(copyTexts);
    for (var i = 0; i < 20 && copied == null; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    expect(copied, isNotNull);
    final rows = _parseCsv(copied!);
    expect(rows.first, ['collection', 'id', 'field', 'english', 'french']);
    expect(rows.length, greaterThan(500));
    await tester.pumpAndSettle();
    expect(find.textContaining('copied to the clipboard'), findsOneWidget);
  });
}
