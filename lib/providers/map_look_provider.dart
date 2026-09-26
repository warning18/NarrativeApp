import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/map_charts.dart';
import '../data/world_map.dart';

const String mapLookPrefsKey = 'world_map_look';

/// Which of the world map's three looks the player chose; the night map
/// until they choose.
class MapLookNotifier extends StateNotifier<MapLook> {
  MapLookNotifier() : super(MapLook.night) {
    _load();
  }

  bool _chosen = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(mapLookPrefsKey);
    if (_chosen || name == null) return;
    for (final look in MapLook.values) {
      if (look.name == name) state = look;
    }
  }

  Future<void> choose(MapLook look) async {
    _chosen = true;
    state = look;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(mapLookPrefsKey, look.name);
  }
}

final mapLookProvider =
    StateNotifierProvider<MapLookNotifier, MapLook>((ref) => MapLookNotifier());

const String mapShapePrefsKey = 'world_map_shape';

/// Which of the chart's three geographies the player chose; the
/// continent until they choose.
class MapShapeNotifier extends StateNotifier<MapShape> {
  MapShapeNotifier() : super(MapShape.continental) {
    _load();
  }

  bool _chosen = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(mapShapePrefsKey);
    if (_chosen || name == null) return;
    for (final shape in MapShape.values) {
      if (shape.name == name) state = shape;
    }
  }

  Future<void> choose(MapShape shape) async {
    _chosen = true;
    state = shape;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(mapShapePrefsKey, shape.name);
  }
}

final mapShapeProvider = StateNotifierProvider<MapShapeNotifier, MapShape>(
    (ref) => MapShapeNotifier());
