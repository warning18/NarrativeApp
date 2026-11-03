// The session's saves (v1.713): changes made before a write encodes share
// it, and every caller still awaits a write that holds its change.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';

PlayerSession _named(String name) => PlayerSession.fromJson(
    {'raceId': 'human', 'professionId': 'warrior', 'characterName': name});

Future<String?> _savedName() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('player_session');
  return raw == null
      ? null
      : (json.decode(raw) as Map<String, dynamic>)['characterName'] as String?;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a burst of changes is written once, holding the last', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    await notifier.loadSession(_named('Ada'));
    notifier.sessionWrites = 0;

    final first = notifier.loadSession(_named('Bea'));
    final second = notifier.loadSession(_named('Cy'));
    await first;
    // The first caller's write already holds the later change too.
    expect(await _savedName(), 'Cy');
    await second;
    expect(notifier.sessionWrites, 1);
  });

  test('changes awaited one by one are each written', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    await notifier.loadSession(_named('Ada'));
    notifier.sessionWrites = 0;

    await notifier.loadSession(_named('Bea'));
    expect(await _savedName(), 'Bea');
    await notifier.loadSession(_named('Cy'));
    expect(await _savedName(), 'Cy');
    expect(notifier.sessionWrites, 2);
  });
}
