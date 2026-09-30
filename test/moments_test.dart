// The small moments (v1.178): the achievement toast and the chapter card
// come and go on their own and let taps through; with reduced motion the
// effects stay out of the way.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/moments.dart';

void main() {
  testWidgets('an achievement toast slides in, then goes', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        ctx = context;
        return const Scaffold();
      }),
    ));
    announceAchievements(ctx, ['First Blood'], 'ACHIEVEMENT');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('achievement_toast')), findsOneWidget);
    expect(find.text('First Blood'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('achievement_toast')), findsNothing);
  });

  testWidgets('the chapter card shows its title and lets taps through',
      (tester) async {
    late BuildContext ctx;
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        ctx = context;
        return Scaffold(
          body: Center(
            child:
                TextButton(onPressed: () => taps++, child: const Text('under')),
          ),
        );
      }),
    ));
    showChapterCard(ctx,
        number: 'Chapter 3', title: 'The Spire', colour: Colors.orange);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byKey(const ValueKey('chapter_card')), findsOneWidget);
    await tester.tap(find.text('under'), warnIfMissed: false);
    expect(taps, 1);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chapter_card')), findsNothing);
  });

  testWidgets('with reduced motion no card or seal is drawn', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(builder: (context) {
          ctx = context;
          return const Scaffold();
        }),
      ),
    ));
    showChapterCard(ctx, number: '3', title: 'T', colour: Colors.orange);
    showQuestSeal(ctx);
    await tester.pump();
    expect(find.byKey(const ValueKey('chapter_card')), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
