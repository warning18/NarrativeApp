// "1 charge", not "1 charges" (#650): the cost of a road ward and of a banish
// reads in its number, in English and in French, and no string puts a count
// straight before "charges" again.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/road_wards.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';

void main() {
  test('a count of charges takes its number', () {
    expect(chargesText(AppLanguage.en, 1), '1 charge');
    expect(chargesText(AppLanguage.en, 0), '0 charges');
    expect(chargesText(AppLanguage.en, 3), '3 charges');
    // French takes the singular for 0 and 1.
    expect(chargesText(AppLanguage.fr, 1), '1 charge');
    expect(chargesText(AppLanguage.fr, 0), '0 charge');
    expect(chargesText(AppLanguage.fr, 2), '2 charges');
  });

  test('the ward sheet prices each length in its number', () {
    for (final (roads, en, fr) in const [
      (3, '3 roads · 1 charge', '3 routes · 1 charge'),
      (6, '6 roads · 2 charges', '6 routes · 2 charges'),
      (9, '9 roads · 3 charges', '9 routes · 3 charges'),
    ]) {
      final cost = wardCostOf(roads);
      expect(wardLine('ward_length', AppLanguage.en, roads: roads, cost: cost),
          en);
      expect(wardLine('ward_length', AppLanguage.fr, roads: roads, cost: cost),
          fr);
    }
  });

  test('no string puts a count placeholder straight before "charges"', () {
    // A "{cost} charges" takes one form for every count; the line says
    // {charges} and the code fills it with chargesText.
    final source = File('lib/l10n/app_strings.dart').readAsStringSync();
    final bad = RegExp(r'\{\w+\}\s+charges')
        .allMatches(source)
        .map((m) => source.substring(m.start, m.end + 1));
    // The plural pair is the one place the count and the noun meet.
    expect(bad.where((b) => !b.startsWith('{n} charges')), isEmpty);
  });
}
