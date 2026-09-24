// The expedition card's description on demand, and the gold badge.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/player_stats_bar.dart';
import 'package:narrative_data_app/widgets/zone_card.dart';

const _zone = {
  'zoneName': 'Tanner\'s Court',
  'flavorText': 'The smell reaches you before the court does.',
  'bossEnemyId': 'plague_hound',
  'tier': 1,
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      'a zone card keeps its description for a tap or long press, '
      'and can begin from there', (tester) async {
    var begun = 0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ZoneCard(
            zoneId: 'z_tanners_court',
            zone: _zone,
            zones: const {'z_tanners_court': _zone},
            enemies: const {
              'plague_hound': {'enemyName': 'Plague Hound'},
            },
            enabled: true,
            onBegin: () async => begun++,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tanner\'s Court'), findsOneWidget);
    expect(find.textContaining('Plague Hound'), findsOneWidget);
    expect(find.text(_zone['flavorText']! as String), findsNothing);

    await tester.longPress(find.text('Tanner\'s Court'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(_zone['flavorText']! as String), findsOneWidget);

    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
    await tester.pumpAndSettle();
    expect(begun, 1);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the gold badge follows the purse', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: Scaffold(body: Center(child: GoldBadge()))),
    ));
    await tester.pumpAndSettle();
    final container =
        ProviderScope.containerOf(tester.element(find.byType(GoldBadge)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({'gold': 345})));
    await tester.pumpAndSettle();
    expect(find.text('345'), findsOneWidget);
  });
}
