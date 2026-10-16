import '../combat/gear_effects.dart' show SetBonusTier;
import '../combat/spec_variants.dart' show specVariantPlaceholders;
import '../combat/spells.dart' show SpellSpec;
import '../l10n/app_locale.dart';
import 'text_placeholders.dart';

/// The tables whose descriptions may carry placeholders
/// (text_placeholders.dart), by schema id, and the text fields of a record
/// (or, for item_sets, of each bonus tier) that are filled.
const Map<String, List<String>> placeholderTextFields = {
  'spells': ['description', 'description_fr'],
  'item_sets': ['description', 'descriptionFr'],
  'skills': ['description', 'description_fr'],
  'spec_variants': ['text', 'text_fr', 'voice', 'voice_fr'],
};

/// The numbers record [id] of table [schemaId] offers its texts (see
/// [placeholderTextFields]); for item_sets, [record] is one bonus tier.
Map<String, num> placeholderValuesFor(
    String schemaId, String id, Map<String, dynamic> record) {
  switch (schemaId) {
    case 'spells':
      return SpellSpec.fromJson(id, record).placeholders;
    case 'item_sets':
      return SetBonusTier.fromJson(record).placeholders;
    case 'skills':
      return skillPlaceholderValues(record);
    case 'spec_variants':
      return specVariantPlaceholders(id);
  }
  return const {};
}

AppLanguage _languageOf(String field) =>
    field.endsWith('_fr') || field.endsWith('Fr')
        ? AppLanguage.fr
        : AppLanguage.en;

/// [records] of table [schemaId] with every placeholder their texts carry
/// filled, English and French fields alike; the originals are untouched,
/// and a table with no placeholders comes back as it is. For showing data:
/// the data editor keeps the placeholders.
Map<String, dynamic> withResolvedPlaceholders(
    String schemaId, Map<String, dynamic> records) {
  final fields = placeholderTextFields[schemaId];
  if (fields == null) return records;
  var changed = false;
  Map<String, dynamic> resolved(String id, Map<String, dynamic> record) {
    if (!fields.any((f) => record[f] is String && record[f].contains('{'))) {
      return record;
    }
    changed = true;
    final values = placeholderValuesFor(schemaId, id, record);
    return {
      ...record,
      for (final field in fields)
        if (record[field] case final String text)
          field: resolvePlaceholders(text, values, _languageOf(field)),
    };
  }

  final out = <String, dynamic>{
    for (final MapEntry(:key, :value) in records.entries)
      key: switch (value) {
        final Map record
            when schemaId == 'item_sets' && record['bonuses'] is List =>
          {
            ...record.cast<String, dynamic>(),
            'bonuses': [
              for (final tier in record['bonuses'] as List)
                tier is Map ? resolved(key, tier.cast()) : tier,
            ],
          },
        final Map record => resolved(key, record.cast()),
        _ => value,
      },
  };
  return changed ? out : records;
}

/// Every placeholder in [records] of table [schemaId] that its record can't
/// fill, as 'id: {name}' (the content test keeps this empty).
List<String> unresolvedPlaceholdersIn(
    String schemaId, Map<String, dynamic> records) {
  final fields = placeholderTextFields[schemaId] ?? const [];
  final found = <String>[];
  void check(String id, Map<String, dynamic> record) {
    final values = placeholderValuesFor(schemaId, id, record);
    for (final field in fields) {
      if (record[field] case final String text) {
        for (final name in unresolvedPlaceholders(text, values)) {
          found.add('$id.$field: $name');
        }
      }
    }
  }

  for (final MapEntry(:key, :value) in records.entries) {
    if (value is! Map) continue;
    final record = value.cast<String, dynamic>();
    if (schemaId == 'item_sets') {
      for (final tier in (record['bonuses'] as List?) ?? const []) {
        if (tier is Map) check(key, tier.cast());
      }
    } else {
      check(key, record);
    }
  }
  return found;
}
