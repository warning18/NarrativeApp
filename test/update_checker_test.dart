// Unit coverage for the version-comparison logic behind Settings > Check
// for Updates. This is the one piece of that feature with no platform
// dependency (network, file system, installer) — cheap to get exhaustively
// right, and exactly the kind of off-by-one string parsing that's easy to
// silently break while editing nearby code.

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
}
