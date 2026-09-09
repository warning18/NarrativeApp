import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'db_schema.dart';

class GameDbRepository {
  GameDbRepository(this.schema);

  final DbSchema schema;

  String get _prefsKey => 'gamedb_${schema.id}';

  Future<Map<String, dynamic>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      return json.decode(saved) as Map<String, dynamic>;
    }
    final raw = await rootBundle.loadString(schema.assetPath);
    return json.decode(raw) as Map<String, dynamic>;
  }

  Future<void> saveRecords(Map<String, dynamic> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode(records));
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
