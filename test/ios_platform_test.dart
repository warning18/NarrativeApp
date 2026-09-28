// The app on an iPhone (v1.171): read-aloud asks iOS to play through the
// Ring/Silent switch, and Settings doesn't offer the Android updater (an
// APK the app installs itself), saying where new versions come from
// instead.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/tts_provider.dart';
import 'package:narrative_data_app/screens/settings_screen.dart';

List<MethodCall> _listenToTts() {
  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('flutter_tts'),
          (call) async {
    calls.add(call);
    return 1;
  });
  return calls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('on an iPhone, read-aloud sets up its own audio session', () async {
    final calls = _listenToTts();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      TtsNotifier().dispose();
      await Future<void>.delayed(Duration.zero);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
    final shared = calls.where((c) => c.method == 'setSharedInstance');
    expect(shared.single.arguments, isTrue);

    // Android has no such thing to ask for.
    calls.clear();
    TtsNotifier().dispose();
    await Future<void>.delayed(Duration.zero);
    expect(calls.where((c) => c.method == 'setSharedInstance'), isEmpty);
  });

  testWidgets('on an iPhone, Settings says where updates come from',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    _listenToTts();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: SettingsScreen())));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      expect(find.byKey(const Key('updates_elsewhere_note')), findsOneWidget);
      expect(find.text('Check for Updates', skipOffstage: false), findsNothing);
      expect(
          find.byIcon(Icons.system_update, skipOffstage: false), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }

    // On Android the updater stays.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SettingsScreen())));
    await tester.pump();
    expect(find.byKey(const Key('updates_elsewhere_note')), findsNothing);
    expect(find.text('Check for Updates', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
