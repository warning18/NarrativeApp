// Unit coverage for StoryPlayNotifier's visitedNodeIds tracking -- the
// fog-of-war set the story map uses outside Edit Mode to shadow nodes the
// player hasn't actually reached yet. Covers that it grows monotonically
// (a goBack never un-visits a node), resets on a deliberate restart, and
// survives the autosave round trip, including for a save written before
// this field existed.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/story_providers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts with only the start node visited', () {
    final notifier = StoryPlayNotifier('100');
    expect(notifier.state.visitedNodeIds, {'100'});
  });

  test('choose adds the destination node to the visited set', () {
    final notifier = StoryPlayNotifier('100');
    notifier.choose('200');
    expect(notifier.state.visitedNodeIds, {'100', '200'});
    expect(notifier.state.currentNodeId, '200');
  });

  test('goBack does not remove the node it leaves from the visited set', () {
    final notifier = StoryPlayNotifier('100');
    notifier.choose('200');
    notifier.choose('300');
    notifier.goBack();
    expect(notifier.state.currentNodeId, '200');
    expect(notifier.state.visitedNodeIds, {'100', '200', '300'});
  });

  test('restart clears the visited set back to just the new start node', () {
    final notifier = StoryPlayNotifier('100');
    notifier.choose('200');
    notifier.choose('300');
    notifier.restart('100');
    expect(notifier.state.visitedNodeIds, {'100'});
    expect(notifier.state.history, isEmpty);
  });

  test(
      'loadState unions the restored path into the visited set without dropping later progress',
      () {
    final notifier = StoryPlayNotifier('100');
    notifier.choose('200');
    notifier.choose('999'); // progress beyond the checkpoint being restored
    notifier.loadState('200', ['100']);
    expect(notifier.state.currentNodeId, '200');
    expect(notifier.state.visitedNodeIds, {'100', '200', '999'});
  });

  test('a save on a scene the story took out picks up where it went', () {
    final notifier = StoryPlayNotifier('100');
    notifier.loadState('5001', ['3001_camp', '4999_camp']);
    expect(notifier.state.currentNodeId, '4999_camp');
    notifier.loadState('5002', ['4999_camp']);
    expect(notifier.state.currentNodeId, '4999_camp');
    expect(liveNodeId('5003'), '5003');
  });

  test('visited set persists across autosave load', () async {
    final first = StoryPlayNotifier('100');
    // Let the constructor's own autosave load (which finds nothing, since
    // prefs starts empty) settle before driving it -- otherwise that
    // pending load can resume later and race the choose() calls below.
    await Future<void>.delayed(Duration.zero);
    first.choose('200');
    first.choose('300');
    // choose() fires _persistAutosave() without awaiting it; give the
    // pending SharedPreferences writes a tick to land before reloading.
    await Future<void>.delayed(Duration.zero);

    final second = StoryPlayNotifier('100');
    await Future<void>.delayed(Duration.zero);
    expect(second.state.currentNodeId, '300');
    expect(second.state.visitedNodeIds, {'100', '200', '300'});
  });

  test(
      'a pre-fog-of-war autosave (no visited key) backfills from history + node',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('autosave_story_node', '300');
    await prefs.setString(
        'autosave_story_history', json.encode(['100', '200']));

    final notifier = StoryPlayNotifier('100');
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.currentNodeId, '300');
    expect(notifier.state.visitedNodeIds, {'100', '200', '300'});
  });
}
