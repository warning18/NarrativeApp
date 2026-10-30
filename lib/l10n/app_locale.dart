import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { en, fr }

const String _languagePrefsKey = 'app_language';

class _AppLanguageNotifier extends StateNotifier<AppLanguage> {
  _AppLanguageNotifier() : super(AppLanguage.en) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_languagePrefsKey);
    if (saved == AppLanguage.fr.name) state = AppLanguage.fr;
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languagePrefsKey, language.name);
  }
}

final appLanguageProvider =
    StateNotifierProvider<_AppLanguageNotifier, AppLanguage>(
        (ref) => _AppLanguageNotifier());
