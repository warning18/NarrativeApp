// "1 Stat Point" / "2 Stat Points" and the French singular (v1.278).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/screens/character_screen.dart';

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  Future<List<String>> texts(WidgetTester tester, {bool french = false}) async {
    SharedPreferences.setMockInitialValues({if (french) 'app_language': 'fr'});
    final out = <String>[];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Consumer(builder: (context, ref, _) {
          out
            ..clear()
            ..addAll([
              for (final n in [0, 1, 2]) statPointsText(ref, n)
            ]);
          return const SizedBox();
        }),
      ),
    ));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    return out;
  }

  testWidgets('English: one point, then points', (tester) async {
    expect(await texts(tester),
        ['0 Stat Points', '1 Stat Point', '2 Stat Points']);
  });

  testWidgets('French: the singular for none and one', (tester) async {
    expect(await texts(tester, french: true), [
      '0 Point de statistique',
      '1 Point de statistique',
      '2 Points de statistique',
    ]);
  });
}
