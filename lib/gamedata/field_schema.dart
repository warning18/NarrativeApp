enum FieldType {
  text,
  multilineText,
  integer,
  decimal,
  boolean,
  enumeration,
  stringList,
  json,
}

class FieldSchema {
  FieldSchema({
    required this.key,
    required this.label,
    required this.type,
    this.enumOptions = const [],
    this.defaultValue,
  });

  final String key;
  final String label;
  final FieldType type;
  final List<String> enumOptions;
  final dynamic defaultValue;
}
