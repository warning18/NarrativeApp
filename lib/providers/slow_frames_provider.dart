// The slow-frames switch and what it needs (v1.765): the saved setting (off by
// default), the routes on the navigator (to say which screen a frame was drawn
// on) and the meter itself (see utils/slow_frames.dart).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../utils/slow_frames.dart';
import 'app_mode_provider.dart';
import 'combat_active_provider.dart';
import 'combat_settings_provider.dart' show PersistedFlagNotifier;
import 'home_tab_provider.dart';

/// Whether the player asked for the slow-frames counter. Off by default; when
/// off nothing runs at all.
final slowFramesProvider = StateNotifierProvider<PersistedFlagNotifier, bool>(
    (ref) => PersistedFlagNotifier('slow_frames_enabled', defaultValue: false));

/// Watches the navigator's routes so the meter knows which screen is on top.
class SlowFrameRoutes extends NavigatorObserver {
  final List<Route<dynamic>> stack = [];

  /// The route name of the screen on top ('/' is the main menu, the game's own
  /// is [gameRouteName]); null for an unnamed one.
  String? get topName => stack.isEmpty ? null : stack.last.settings.name;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      stack.add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      stack.remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      stack.remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final at = oldRoute == null ? -1 : stack.indexOf(oldRoute);
    if (at >= 0) stack.removeAt(at);
    if (newRoute != null) {
      stack.insert(at < 0 ? stack.length : at, newRoute);
    }
  }
}

final slowFrameRoutesProvider =
    Provider<SlowFrameRoutes>((ref) => SlowFrameRoutes());

/// The screen the player is on, in words for the report: a fight, one of the
/// game's tabs, the main menu, or another screen on top of them.
String slowFrameScreenName(Ref ref) {
  if (ref.read(combatActiveProvider)) return 'Fight';
  final top = ref.read(slowFrameRoutesProvider).topName;
  if (top == '/') return 'Main menu';
  if (top != null && top != gameRouteName) return top;
  final edit = ref.read(appModeProvider) == AppMode.edit;
  final tab = ref.read(homeTabIndexProvider);
  if (top == null) {
    // A screen pushed with no name (a settings page, a shop...): the tab under
    // it is not where the frames were drawn.
    return 'Another screen';
  }
  return switch (tab) {
    journeyTabIndex =>
      slowFrameHint == null ? 'Journey' : 'Journey, $slowFrameHint',
    0 => edit ? 'Story reader' : 'Story',
    1 => edit ? 'Play' : 'Character',
    2 => 'Camp or ship',
    3 => edit ? 'Data' : 'Other',
    _ => 'Tab $tab',
  };
}

/// The meter, one for the app. Starting and stopping it follows
/// [slowFramesProvider] (see SlowFramesOverlay).
final slowFrameMeterProvider = Provider<SlowFrameMeter>((ref) {
  final meter = SlowFrameMeter(screen: () => slowFrameScreenName(ref));
  ref.onDispose(meter.stop);
  return meter;
});
