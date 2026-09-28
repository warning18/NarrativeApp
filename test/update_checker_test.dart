// Unit coverage for the version-comparison logic behind Settings > Check
// for Updates. This is the one piece of that feature with no platform
// dependency (network, file system, installer) — cheap to get exhaustively
// right, and exactly the kind of off-by-one string parsing that's easy to
// silently break while editing nearby code.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/providers/update_checker.dart';

void main() {
  group('isNewerVersion', () {
    test('a higher patch/minor/major is newer', () {
      expect(isNewerVersion('1.2.4', '1.2.3'), isTrue);
      expect(isNewerVersion('1.3.0', '1.2.9'), isTrue);
      expect(isNewerVersion('2.0.0', '1.9.9'), isTrue);
    });

    test('an equal version is not newer', () {
      expect(isNewerVersion('1.49.2', '1.49.2'), isFalse);
    });

    test('a lower version is not newer', () {
      expect(isNewerVersion('1.49.1', '1.49.2'), isFalse);
      expect(isNewerVersion('1.0.0', '1.49.2'), isFalse);
    });

    test('a leading "v" (as in GitHub tag names) is ignored', () {
      expect(isNewerVersion('v1.50.0', '1.49.2'), isTrue);
      expect(isNewerVersion('v1.49.2', '1.49.2'), isFalse);
    });

    test('a trailing build number is ignored on either side', () {
      expect(isNewerVersion('1.50.0+75', '1.49.2+74'), isTrue);
      expect(isNewerVersion('1.49.2+74', '1.49.2+999'), isFalse);
    });

    test('missing trailing segments are treated as zero', () {
      expect(isNewerVersion('1.50', '1.49.2'), isTrue);
      expect(isNewerVersion('1.49', '1.49.0'), isFalse);
      expect(isNewerVersion('2', '1.99.99'), isTrue);
    });
  });

  group('the file a release carries for this device', () {
    // As the latest release lists them since v1.172: the APK, then the IPA
    // added by the iPhone job.
    const assets = [
      {'name': 'app-release.apk', 'id': 1},
      {'name': 'NarrativeApp-1.172.0.ipa', 'id': 2},
    ];

    test('Android takes the APK and iPhone the IPA', () {
      expect(pickUpdateAsset(assets, '.apk')?['id'], 1);
      expect(pickUpdateAsset(assets, '.ipa')?['id'], 2);
      expect(
          pickUpdateAsset(const [
            {'name': 'App.IPA', 'id': 3}
          ], '.ipa'),
          isNotNull,
          reason: 'whatever the case of the name');
      expect(
          pickUpdateAsset(const [
            {'name': 'app-release.apk'}
          ], '.ipa'),
          isNull,
          reason: 'a release from before iPhone builds');
    });

    test('by platform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(updateFileExtension, '.ipa');
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(updateFileExtension, '.apk');
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(updateFileExtension, isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
