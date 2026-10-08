import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/map_charts.dart';
import '../data/world_map.dart';
import '../widgets/chart_map_painter.dart' show ChartCalque;

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

/// Which of the chart's three geographies the player chose; the Ring
/// (world B) until they choose.
class MapShapeNotifier extends StateNotifier<MapShape> {
  MapShapeNotifier() : super(MapShape.archipelago) {
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

const String chartCalquePrefsKey = 'world_map_calque';

/// Which calque lies over the chart (v1.199): none until the player picks
/// one; the pick is kept.
class ChartCalqueNotifier extends StateNotifier<ChartCalque> {
  ChartCalqueNotifier() : super(ChartCalque.none) {
    _load();
  }

  bool _chosen = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(chartCalquePrefsKey);
    if (_chosen || name == null) return;
    for (final calque in ChartCalque.values) {
      if (calque.name == name) state = calque;
    }
  }

  Future<void> choose(ChartCalque calque) async {
    _chosen = true;
    state = calque;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chartCalquePrefsKey, calque.name);
  }
}

final chartCalqueProvider =
    StateNotifierProvider<ChartCalqueNotifier, ChartCalque>(
        (ref) => ChartCalqueNotifier());

const String chartGlobePrefsKey = 'world_map_globe';

/// Whether the Journey's world map is looked at as a sphere (v1.200);
/// flat until the player asks, and the pick is kept.
class ChartGlobeNotifier extends StateNotifier<bool> {
  ChartGlobeNotifier() : super(false) {
    _load();
  }

  bool _chosen = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final on = prefs.getBool(chartGlobePrefsKey);
    if (_chosen || on == null) return;
    state = on;
  }

  Future<void> choose(bool on) async {
    _chosen = true;
    state = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(chartGlobePrefsKey, on);
  }
}

final chartGlobeProvider = StateNotifierProvider<ChartGlobeNotifier, bool>(
    (ref) => ChartGlobeNotifier());

const String chartWeatherPrefsKey = 'world_map_weather';

/// Whether the weather moves over the world map (v1.204, see
/// chart_weather.dart): on until the player turns it off, and the pick is
/// kept.
class ChartWeatherNotifier extends StateNotifier<bool> {
  ChartWeatherNotifier() : super(true) {
    _load();
  }

  bool _chosen = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final on = prefs.getBool(chartWeatherPrefsKey);
    if (_chosen || on == null) return;
    state = on;
  }

  Future<void> choose(bool on) async {
    _chosen = true;
    state = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(chartWeatherPrefsKey, on);
  }
}

final chartWeatherProvider = StateNotifierProvider<ChartWeatherNotifier, bool>(
    (ref) => ChartWeatherNotifier());
