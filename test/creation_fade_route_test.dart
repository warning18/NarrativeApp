// The character's screen fades into the Blind Beggar's page (after-opening
// option 3): the sigil whispers in the middle of the fade, the page beneath
// is there to be tapped, and with reduced motion there is just the cut.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/creation_fade_route.dart';

Future<void> _open(WidgetTester tester, {required bool still}) async {
  late BuildContext context;
  await tester.pumpWidget(MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: MaterialApp(
      home: Builder(builder: (c) {
        context = c;
        return const Scaffold(body: Text('story page'));
      }),
    ),
  ));
  Navigator.of(context).push<bool>(creationToStoryRoute<bool>(
      (_) => const Scaffold(body: Text('character page'))));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('leaving fades the character out with the sigil in the middle',
      (tester) async {
    await _open(tester, still: false);
    expect(find.text('character page'), findsOneWidget);
    expect(find.byKey(const Key('creation_sigil')), findsNothing);

    Navigator.of(tester.element(find.text('character page'))).pop(true);
    await tester.pump();
    await tester.pump(creationFadeOut ~/ 2);
    final sigil =
        tester.widget<Opacity>(find.byKey(const Key('creation_sigil')));
    expect(sigil.opacity, closeTo(creationSigilPeak, 0.03));
    expect(find.text('story page'), findsOneWidget);

    await tester.pump(creationFadeOut);
    await tester.pumpAndSettle();
    expect(find.text('character page'), findsNothing);
    expect(find.byKey(const Key('creation_sigil')), findsNothing);
  });

  testWidgets('with reduced motion there is no sigil', (tester) async {
    await _open(tester, still: true);
    Navigator.of(tester.element(find.text('character page'))).pop(true);
    await tester.pump();
    await tester.pump(creationFadeOut ~/ 2);
    expect(find.byKey(const Key('creation_sigil')), findsNothing);
  });
}
