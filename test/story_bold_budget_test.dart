import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// One bold passage per scene, the sharpest. The scenes below are the openings,
/// reveals, endings and ledgers, which keep more than one. English and French
/// carry the same number of bold passages in every scene.
const _keepsMoreThanOne = <String>{
  '0',
  '2015_house_salt_ledger',
  '5004',
  '5004b',
  '6002',
  '6004',
  '6010_confession',
  '6010_lysa_ledger',
  '6010_record',
  '7001',
  '7002',
  '7002_banner',
  '7003',
  '7004',
  '7005',
  '7005_crown',
  '7005_dawn',
  '7005_seeker',
  '7590_compact',
  '7590_crows',
  '7590_mire',
  '7590_open_hand',
  '7590_penitents',
  '7590_vigil',
  'names_choice',
  'names_clerk',
  'names_kin',
  'names_throne',
};

final _bold = RegExp(r'\*\*(.+?)\*\*', dotAll: true);

void main() {
  final dag =
      jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;

  test('English and French have the same number of bold passages', () {
    final off = <String>[];
    for (final e in dag.entries) {
      final n = e.value as Map<String, dynamic>;
      final en = _bold.allMatches((n['description'] ?? '') as String).length;
      final fr = _bold.allMatches((n['description_fr'] ?? '') as String).length;
      if (en != fr) off.add('${e.key}: EN $en, FR $fr');
    }
    expect(off, isEmpty);
  });

  test('a scene has one bold passage unless it is on the keep list', () {
    final extra = <String>[];
    for (final e in dag.entries) {
      final n = e.value as Map<String, dynamic>;
      final en = _bold.allMatches((n['description'] ?? '') as String).length;
      if (en > 1 && !_keepsMoreThanOne.contains(e.key)) extra.add(e.key);
    }
    expect(extra, isEmpty,
        reason: 'trim to the sharpest fact, or add the scene to the list');
  });

  test('every scene on the keep list still has more than one', () {
    final stale = <String>[];
    for (final id in _keepsMoreThanOne) {
      final n = dag[id] as Map<String, dynamic>?;
      final en = _bold.allMatches((n?['description'] ?? '') as String).length;
      if (en < 2) stale.add(id);
    }
    expect(stale, isEmpty);
  });
}
