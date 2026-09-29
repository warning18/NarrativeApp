// The app on an iPhone (v1.171): read-aloud asks iOS to play through the
// Ring/Silent switch. Since v1.172 the updater works there too, fetching
// the release's IPA instead of its APK; a device the app can't update
// (a desktop) says where new versions are instead.
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

  testWidgets('Settings offers the updater on Android and iPhone only',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    _listenToTts();
    Future<void> openSettings(TargetPlatform platform) async {
      debugDefaultTargetPlatformOverride = platform;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: SettingsScreen())));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }

    try {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        await openSettings(platform);
        expect(
            find.text('Check for Updates', skipOffstage: false), findsOneWidget,
            reason: '$platform');
        expect(find.byKey(const Key('updates_elsewhere_note')), findsNothing);
      }
      await openSettings(TargetPlatform.linux);
      expect(find.byKey(const Key('updates_elsewhere_note')), findsOneWidget);
      expect(find.text('Check for Updates', skipOffstage: false), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
