// The factions' "How it is ruled" text (factions.json `ruling` and
// `ruling_fr`, read by records.dart and shown on the clan card) is in the
// data editor's schema, so Edit Mode shows it and saves it.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/gamedata/field_schema.dart';

void main() {
  test('the factions schema edits ruling and ruling_fr as long text', () {
    for (final key in ['ruling', 'ruling_fr']) {
      final field = factionsSchema.fields.where((f) => f.key == key);
      expect(field, hasLength(1), reason: key);
      expect(field.single.type, FieldType.multilineText, reason: key);
    }
  });
}
