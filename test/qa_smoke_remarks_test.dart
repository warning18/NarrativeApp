// QA: the companions' words at wave 15's moments (v1.493, v1.494) in their
// speech bubble, on a phone, with the app's own fonts: the longest lines of
// the 88 records, a two-line exchange, and the real moments with two
// companions in the party (a roll house built, a temple service bought).
// 360 x 740 and 320 x 568, English and French, no overflow (qa_smoke_harness
// .dart; SMOKE_SHOTS=<folder> for the pictures).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/data/companion_remarks.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/town_services.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/remark_provider.dart';
import 'package:narrative_data_app/providers/temple_provider.dart';
import 'package:narrative_data_app/providers/town_rulers_provider.dart';
import 'package:narrative_data_app/widgets/camp_town_section.dart';
import 'package:narrative_data_app/widgets/companion_remark_bubble.dart';
import 'package:narrative_data_app/widgets/town_service_sheet.dart';

import 'qa_smoke_harness.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// The wave 15 moments' kinds (core's RemarkKind names).
const _moments = {
  'builtParleyTent',
  'builtBoneCastersHut',
  'builtWardingCairn',
  'builtStarWell',
  'riskyTaken',
  'riskyWon',
  'riskyLostHealth',
  'riskyLostGold',
  'riskyLostCurse',
  'templeMended',
  'templeBlessed',
};

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
    housesSchema,
    zonesSchema,
    achievementsSchema,
    companionsSchema,
    companionRemarksSchema,
  ]) {
    await container.read(gameDbProvider(schema).notifier).whenLoaded();
  }
}

/// Shows the bubble over the screen as soon as it is built: the longest
/// wave 15 lines in the language now (`count` of them, one after another).
class _Bubble extends ConsumerStatefulWidget {
  const _Bubble(this.count);
  final int count;

  @override
  ConsumerState<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends ConsumerState<_Bubble> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final french = ref.read(appLanguageProvider) == AppLanguage.fr;
      final book = ref.read(remarkBookProvider);
      final companions =
          ref.read(localizedDbProvider(companionsSchema)).value ??
              const <String, dynamic>{};
      final all = <SpokenLine>[];
      for (final id in companions.keys) {
        for (final kind
            in RemarkKind.values.where((k) => _moments.contains(k.name))) {
          for (final line in book.linesFor(id, kind, french: french)) {
            all.add(SpokenLine(
              speaker:
                  (companions[id] as Map)['companionName']?.toString() ?? id,
              line: line,
              companionId: id,
            ));
          }
        }
      }
      all.sort((a, b) => b.line.length.compareTo(a.line.length));
      showSpokenLines(context, ref, all.take(widget.count).toList());
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// A town's temple, its sheet open (as in qa_smoke_temple_test.dart).
class _Temple extends ConsumerStatefulWidget {
  const _Temple();

  @override
  ConsumerState<_Temple> createState() => _TempleState();
}

class _TempleState extends ConsumerState<_Temple> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final place = ref
          .read(townRulersProvider)
          .keys
          .firstWhere((id) => ref.read(templeClanProvider(id)) == 'dominion');
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

class _Town extends ConsumerWidget {
  const _Town();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Map<String, dynamic> table(DbSchema schema) =>
        ref.watch(localizedDbProvider(schema)).value ??
        const <String, dynamic>{};
    return CampTownSection(
      houses: table(housesSchema),
      shops: table(shopsSchema),
      zones: table(zonesSchema),
      achievements: table(achievementsSchema),
    );
  }
}

/// The bubble's words, all typed out (they come a letter every 16 ms).
Future<void> _typed(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
}

/// The bubble tapped away the way a player does (the words, then the
/// bubble), and the screen let go.
Future<void> _dismissed(WidgetTester tester) async {
  for (var i = 0;
      i < 6 && find.byType(CompanionRemarkOverlay).evaluate().isNotEmpty;
      i++) {
    await tester.tap(find.byKey(const Key('remark_next')));
    await tester.pump(const Duration(milliseconds: 400));
  }
  await tester.pump(const Duration(seconds: 1));
}

/// Pumps until [finder] shows (at most about 8 s).
Future<bool> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 80 && finder.evaluate().isEmpty; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  return finder.evaluate().isNotEmpty;
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

  AllyState ally(String id) => AllyState(
      companionId: id,
      currentHealth: AllyState.fullHealthSentinel,
      approval: 10);

  PlayerSession party(Map<String, dynamic> more, {int gold = 900}) =>
      PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'ownedDiceIds': ['starter_die'],
        'equippedDiceId': 'starter_die',
        'gold': gold,
        'day': 5,
        'inventoryItemIds': [
          for (final m in const ['material_timber', 'material_cut_stone']) ...[
            m,
            m,
            m
          ],
        ],
        ...more,
      }).copyWith(
        recruitedAllies: [ally('maren'), ally('malrik')],
        activeAllyIds: const ['maren', 'malrik'],
        politics: setStandingValue(
                PoliticsState.storyStart, 'dominion', 40, 'qa',
                data: data)
            .state,
      );

  testWidgets('the companions\' wave 15 words read on a phone, EN and FR',
      (tester) async {
    await runSmoke(
      tester,
      [
        SmokeCase('remark_longest', const _Bubble(1),
            session: party({}), prepare: _loadTables, act: _typed),
        SmokeCase('remark_exchange', const _Bubble(2),
            session: party({}), prepare: _loadTables, act: (tester) async {
          await _typed(tester);
          // The answer, from the other side.
          await tester.tap(find.byKey(const Key('remark_next')));
          await _typed(tester);
        }),
        SmokeCase(
          'remark_built_bone_casters_hut',
          const _Town(),
          session: party({}),
          prepare: _loadTables,
          act: (tester) async {
            final card = find.byKey(const Key('town_card_bone_casters_hut'));
            await tester.ensureVisible(card);
            await tester.pump();
            await tester.tap(card);
            // The sheet slides in (a frame to start it, then its time).
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            // The card opened its sheet; its Build button builds.
            final build = find.descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(FilledButton));
            expect(build, findsOneWidget, reason: 'the hut can be built');
            await tester.ensureVisible(build);
            await tester.pump();
            await tester.tap(build);
            // The notice first, then the companion's word over the screen.
            await tester.pump(const Duration(milliseconds: 500));
            expect(await _until(tester, find.byType(CompanionRemarkOverlay)),
                isTrue,
                reason: 'a companion speaks when the hut goes up');
            await _typed(tester);
          },
          after: _dismissed,
        ),
        SmokeCase(
          'remark_temple_mended',
          const _Temple(),
          session: party({'gold': 600}),
          prepare: _loadTables,
          act: (tester) async {
            await tester.tap(find.byKey(const Key('temple_mend')));
            expect(await _until(tester, find.byType(CompanionRemarkOverlay)),
                isTrue,
                reason: 'a companion speaks when the temple mends');
            await _typed(tester);
          },
          after: _dismissed,
        ),
        SmokeCase(
          'remark_temple_blessed',
          const _Temple(),
          session: party({'gold': 600}),
          prepare: _loadTables,
          act: (tester) async {
            await tester.tap(find.byKey(const Key('temple_bless')));
            expect(await _until(tester, find.byType(CompanionRemarkOverlay)),
                isTrue,
                reason: 'a companion speaks when the temple blesses');
            await _typed(tester);
          },
          after: _dismissed,
        ),
      ],
      overrides: [reachedChapterProvider.overrideWithValue(8)],
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}
