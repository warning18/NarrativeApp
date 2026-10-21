// QA: the temple's sheet (v1.490: Mending and Blessing, priced by the ruling
// clan's standing, refused when Hunted) on a phone, with the app's own fonts:
// a neutral temple, a Hostile price, a Sworn price, the Hunted refusal, and
// the blocked rows (too poor, mended today). 360 x 740 and 320 x 568, English
// and French, no overflow (qa_smoke_harness.dart; SMOKE_SHOTS=<folder> for
// the pictures).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/town_services.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/temple_provider.dart';
import 'package:narrative_data_app/providers/town_rulers_provider.dart';
import 'package:narrative_data_app/widgets/town_service_sheet.dart';

import 'qa_smoke_harness.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

Future<void> _loadTables(ProviderContainer container) async {
  for (final schema in [
    factionsSchema,
    subclansSchema,
    relationsSchema,
    titlesSchema,
    geographySchema,
    biomesSchema,
    shopsSchema,
    portsSchema,
  ]) {
    await container.read(gameDbProvider(schema).notifier).whenLoaded();
  }
}

/// The clans no town was found for: a case that would show the wrong temple.
final _noTemple = <String>[];

/// Opens the sheet of the first temple that [clan] keeps ('' for one nobody
/// rules) as soon as it is built.
class _Temple extends ConsumerStatefulWidget {
  const _Temple(this.clan);
  final String clan;

  @override
  ConsumerState<_Temple> createState() => _TempleState();
}

class _TempleState extends ConsumerState<_Temple> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rulers = ref.read(townRulersProvider).keys;
      final place = widget.clan.isEmpty
          ? 'nowhere_in_particular'
          : rulers.firstWhere(
              (id) => ref.read(templeClanProvider(id)) == widget.clan,
              orElse: () {
              _noTemple.add(widget.clan);
              return 'missing_${widget.clan}';
            });
      showTownServiceSheet(
          context,
          TownService(CityServicePin('t_temple', 'temple', Offset.zero, ''), [
            (action: TownServiceAction.temple, id: place, unlocked: true),
          ]));
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );

  /// The save with [clan] at [standing] and the rest as given.
  PlayerSession at(String clan, num standing,
          {int gold = 600, Map<String, dynamic> more = const {}}) =>
      PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'ownedDiceIds': ['starter_die'],
        'equippedDiceId': 'starter_die',
        'gold': gold,
        'day': 5,
        ...more,
      }).copyWith(
        politics: clan.isEmpty
            ? PoliticsState.storyStart
            : setStandingValue(PoliticsState.storyStart, clan, standing, 'qa',
                    data: data)
                .state,
      );

  testWidgets('the temple sheet reads on a phone, EN and FR', (tester) async {
    await runSmoke(
      tester,
      [
        SmokeCase('temple_neutral', const _Temple(''),
            session: at('', 0), prepare: _loadTables),
        SmokeCase('temple_hostile_dominion', const _Temple('dominion'),
            session: at('dominion', -40), prepare: _loadTables),
        SmokeCase('temple_sworn_crows', const _Temple('crows'),
            session: at('crows', 100), prepare: _loadTables),
        SmokeCase('temple_sworn_dominion', const _Temple('dominion'),
            session: at('dominion', 100), prepare: _loadTables),
        SmokeCase('temple_hunted_crows', const _Temple('crows'),
            session: at('crows', -80), prepare: _loadTables),
        SmokeCase('temple_too_poor', const _Temple('compact'),
            session: at('compact', 0, gold: 20), prepare: _loadTables),
        SmokeCase('temple_mended_today', const _Temple('compact'),
            session: at('compact', 40, more: {'templeMendDay': 5}),
            prepare: _loadTables),
      ],
      overrides: [reachedChapterProvider.overrideWithValue(5)],
    );
    expect(_noTemple, isEmpty, reason: 'no town kept by these clans');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
