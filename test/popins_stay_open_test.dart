// The hold-to-peek popins (v1.555): a long press opens the stat, item, skill
// and title popins and they stay open when the finger lifts; a tap outside
// closes them (and so does the back gesture). The clan's card, which used to
// close on release, is in offer_dialog_test.dart and throne_room_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/detail_dialog.dart';
import 'package:narrative_data_app/widgets/stat_sheet.dart';

Widget _host(void Function(BuildContext) open) => ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: GestureDetector(
                key: const Key('held'),
                onLongPress: () => open(context),
                child: const SizedBox(width: 120, height: 60, child: Text('x')),
              ),
            ),
          ),
        ),
      ),
    );

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _holdAndLetGo(WidgetTester tester) async {
  final hold = await tester
      .startGesture(tester.getCenter(find.byKey(const Key('held'))));
  await tester.pump(const Duration(milliseconds: 700));
  await hold.up();
  await _frames(tester);
}

void main() {
  testWidgets(
      'an item, skill or title popin stays open, and a tap outside closes it',
      (tester) async {
    await tester.pumpWidget(_host((context) => showDetailDialog(context,
        title: 'The Juggernaut',
        description: 'You take the blow to give back a worse one.',
        rows: const [MapEntry('Constitution', '+1')])));
    await _holdAndLetGo(tester);
    expect(find.text('The Juggernaut'), findsOneWidget,
        reason: 'it stays open when the finger lifts');
    expect(find.textContaining('Release'), findsNothing);
    await tester.tapAt(const Offset(4, 4));
    await _frames(tester);
    expect(find.text('The Juggernaut'), findsNothing);

    // Opened again: the back gesture closes it.
    await _holdAndLetGo(tester);
    expect(find.text('The Juggernaut'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _frames(tester);
    expect(find.text('The Juggernaut'), findsNothing);
  });

  testWidgets('the stat popin stays open, and a tap outside closes it',
      (tester) async {
    await tester
        .pumpWidget(_host((context) => showStatSheet(context, 'strength')));
    await _holdAndLetGo(tester);
    expect(find.byType(StatSheet), findsOneWidget,
        reason: 'it stays open when the finger lifts');
    await tester.tapAt(const Offset(4, 4));
    await _frames(tester);
    expect(find.byType(StatSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
