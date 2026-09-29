// The Data tab's record editor keeps list fields one entry per line
// (v1.169): entries are often sentences with commas in them (companion
// remarks, NPC dialogue, encounter texts), and saving a record must not
// cut them apart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/screens/game_db_record_editor_screen.dart';

void main() {
  testWidgets('a companion remark keeps its commas through the editor',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(navigatorKey: navigator, home: const Scaffold()),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(Scaffold)));
    final table = await tester.runAsync(() => container
        .read(gameDbProvider(companionRemarksSchema).notifier)
        .whenLoaded());
    final record =
        Map<String, dynamic>.from(table!['sable_kindDisapproved'] as Map);
    final lines = List<String>.from(record['lines'] as List);
    expect(lines.first, contains(','), reason: 'the case this is about');

    navigator.currentState!.push(MaterialPageRoute(
      builder: (_) => GameDbRecordEditorScreen(
        schema: companionRemarksSchema,
        recordKey: 'sable_kindDisapproved',
        initialRecord: record,
      ),
    ));
    await tester.pumpAndSettle();

    // One line per row in the field.
    final linesField = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        (widget.decoration?.labelText ?? '')
            .startsWith('Lines (one per line)'));
    expect(tester.widget<TextField>(linesField).controller!.text,
        lines.join('\n'));
    expect(find.textContaining('(one per line)', skipOffstage: false),
        findsWidgets);

    // Saved untouched: the lines come back exactly as they were.
    await tester.tap(find.byTooltip('Save'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    final saved = container
        .read(gameDbProvider(companionRemarksSchema))
        .value!['sable_kindDisapproved'] as Map<String, dynamic>;
    expect(saved['lines'], lines);
    expect(saved['lines_fr'], record['lines_fr']);
    expect(saved['companionID'], 'sable');
    expect(saved['trigger'], 'kindDisapproved');

    // Edited: one entry per line, commas and all.
    navigator.currentState!.push(MaterialPageRoute(
      builder: (_) => GameDbRecordEditorScreen(
        schema: companionRemarksSchema,
        recordKey: 'sable_kindDisapproved',
        initialRecord: saved,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(linesField,
        'Generous, expensive, generous.\n\n  Charity, love, pays nothing.  ');
    await tester.tap(find.byTooltip('Save'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    final edited = container
        .read(gameDbProvider(companionRemarksSchema))
        .value!['sable_kindDisapproved'] as Map<String, dynamic>;
    expect(edited['lines'],
        ['Generous, expensive, generous.', 'Charity, love, pays nothing.']);
    expect(tester.takeException(), isNull);
  });
}
