// loadedGameDb reads localizedDbProvider's cached table (v1.712): the same
// records as the table built afresh on each call before it, for every
// table, in English and in French.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/description_text.dart';
import 'package:narrative_data_app/data/forge_roll.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';

/// The table as loadedGameDb built it before v1.712.
Map<String, dynamic> _builtAfresh(
    DbSchema schema, Map<String, dynamic> loaded, bool french) {
  final records = withResolvedPlaceholders(schema.id, loaded);
  Map<String, dynamic> readable(Map<String, dynamic> r, {bool fr = false}) =>
      schema.id == itemsSchema.id ? withForgedVariants(r, french: fr) : r;
  return french
      ? readable(frenchOverlay(records), fr: true)
      : readable(records);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final language in AppLanguage.values) {
    test('the cached table is the one built afresh (${language.name})',
        () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(appLanguageProvider.notifier).setLanguage(language);
      var filled = 0;
      for (final schema in gameDbSchemas) {
        final loaded =
            await container.read(gameDbProvider(schema).notifier).whenLoaded();
        if (loaded.isNotEmpty) filled++;
        expect(container.read(localizedDbProvider(schema)).value,
            _builtAfresh(schema, loaded, language == AppLanguage.fr),
            reason: schema.id);
      }
      // The tables really loaded (an empty table proves nothing).
      expect(filled, greaterThan(20));
    });
  }
}
