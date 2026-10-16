// The six rival hunters (Narrative's rival-hunters.md) and the six nemesis
// champions (nemesis-quests.md) have icons of their own, drawn by
// tool/gen_hunter_icons.py: no more a borrowed picture, 128x128 like every
// enemy icon, and none the same as another.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/utils/pixel_icons/enemy_icons.dart';

const hunters = [
  'vigil_spearman_halvard',
  'vigil_candlebearer_ysel',
  'compact_quarryman_brodin',
  'compact_anvil_deaf_tove',
  'mire_returned_sedge',
  'mire_herons_wake_wen',
  'champion_dominion',
  'champion_crows',
  'champion_compact',
  'champion_vigil',
  'champion_penitents',
  'champion_mire',
  // The Regent of the Lantern (claimant_vane), drawn since v1.456.
  'claimant_vane',
];

void main() {
  test('each hunter and champion has an icon of its own, 128x128', () {
    for (final id in hunters) {
      expect(EnemyIcons.allIds, contains(id), reason: id);
      expect(EnemyIcons.pathFor(id), 'assets/icons/enemies/$id.png',
          reason: '$id is not borrowed');
      final bytes = File(EnemyIcons.pathFor(id)).readAsBytesSync();
      final header = ByteData.sublistView(Uint8List.fromList(bytes));
      expect(header.getUint32(16), 128, reason: '$id width');
      expect(header.getUint32(20), 128, reason: '$id height');
    }
  });

  test('no two of them, and none and another foe, share a picture', () {
    final seen = <String, String>{};
    for (final id in EnemyIcons.allIds) {
      final bytes = File('assets/icons/enemies/$id.png');
      if (!bytes.existsSync()) continue;
      final key = String.fromCharCodes(bytes.readAsBytesSync());
      final other = seen[key];
      if (other != null && (hunters.contains(id) || hunters.contains(other))) {
        fail('$id and $other have the same icon');
      }
      seen[key] = id;
    }
  });
}
