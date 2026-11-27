// The Tower's counted lines read "1 potion, 2 antidotes", never "(s)".
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/screens/tower/tower_offer_view.dart';

void main() {
  String line(AppLanguage lang, int potions, int antidotes) =>
      towerBundleLine((key) => trFor(lang, key), potions, antidotes);

  test('the flasks card counts each part in its own number', () {
    expect(line(AppLanguage.en, 2, 1), '2 potions, 1 antidote');
    expect(line(AppLanguage.en, 1, 2), '1 potion, 2 antidotes');
    expect(line(AppLanguage.en, 1, 0), '1 potion');
    expect(line(AppLanguage.en, 0, 3), '3 antidotes');
    expect(line(AppLanguage.fr, 2, 1), '2 potions, 1 antidote');
    expect(line(AppLanguage.fr, 1, 0), '1 potion');
  });

  test('no Tower string keeps a (s) in either language', () {
    for (final key in const [
      'tower_bundle_text',
      'tower_bundle_potions',
      'tower_bundle_potions_one',
      'tower_bundle_antidotes',
      'tower_bundle_antidotes_one',
      'tower_event_picks_note',
      'tower_event_picks_note_one',
    ]) {
      for (final lang in AppLanguage.values) {
        expect(trFor(lang, key), isNot(contains('(s)')), reason: '$key $lang');
      }
    }
  });
}
