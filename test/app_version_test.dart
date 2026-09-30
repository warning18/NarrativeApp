// The version the app reports (AppInfo, which the in-app updater compares
// with a release's tag) is the one pubspec.yaml builds: a stale one makes
// every installed build offer itself as an update.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/app_info.dart';

void main() {
  test('AppInfo.version is pubspec.yaml\'s version name', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    final name = line.split(':')[1].trim().split('+').first;
    expect(AppInfo.version, name);
  });
}
