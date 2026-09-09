import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _apiKeyPrefsKey = 'gemini_api_key';

class ApiKeyNotifier extends StateNotifier<String?> {
  ApiKeyNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_apiKeyPrefsKey);
  }

  Future<void> setKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefsKey, key);
    state = key;
  }

  Future<void> clearKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPrefsKey);
    state = null;
  }
}

final apiKeyProvider =
    StateNotifierProvider<ApiKeyNotifier, String?>((ref) => ApiKeyNotifier());
