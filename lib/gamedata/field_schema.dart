enum FieldType {
  text,
  multilineText,
  integer,
  decimal,
  boolean,
  enumeration,
  stringList,
  json,
  reference,
  referenceList,
  multiEnum,
}

/// Special [FieldSchema.referenceSchemaId] value meaning the field
/// references story node IDs (assets/Cleaned_Narrative_DAG.json) rather
/// than one of the gamedata database schemas.
const String storyEventsReferenceId = 'story_events';

class FieldSchema {
  FieldSchema({
    required this.key,
    required this.label,
    required this.type,
    this.enumOptions = const [],
    this.defaultValue,
    this.referenceSchemaId,
  });

  final String key;
  final String label;
  final FieldType type;
  final List<String> enumOptions;
  final dynamic defaultValue;

  /// For [FieldType.reference] / [FieldType.referenceList]: the id of the
  /// [DbSchema] (see db_schema.dart) whose existing record keys populate
  /// this field's picker, or [storyEventsReferenceId] for story node ids.
  final String? referenceSchemaId;
}
