/// Where and when an item first came into the pack (v1.204): the place
/// the story stood in (a geography.json location or district id, '' when
/// the scene has none) and the chapter reached. Recorded once, on the
/// first acquisition, by every way an item enters the inventory (see
/// `PlayerSession.itemOrigins`); the inventory's detail dialog reads it
/// as "Yours since the Lower Town, chapter 1".
class ItemOrigin {
  const ItemOrigin({this.placeId = '', required this.chapter});

  final String placeId;
  final int chapter;

  Map<String, dynamic> toJson() => {'placeId': placeId, 'chapter': chapter};

  /// [json] read; null when it is no map.
  static ItemOrigin? tryParse(Object? json) {
    if (json is! Map) return null;
    return ItemOrigin(
      placeId: json['placeId']?.toString() ?? '',
      chapter: (json['chapter'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ItemOrigin &&
      other.placeId == placeId &&
      other.chapter == chapter;

  @override
  int get hashCode => Object.hash(placeId, chapter);

  @override
  String toString() => 'ItemOrigin($placeId, chapter $chapter)';
}

/// [origins] with [origin] recorded for every id of [itemIds] that has
/// none yet: the first acquisition wins, a copy found again later changes
/// nothing. [origins] itself when there is nothing to add.
Map<String, ItemOrigin> withItemOrigins(
  Map<String, ItemOrigin> origins,
  Iterable<String> itemIds,
  ItemOrigin? origin,
) {
  if (origin == null) return origins;
  Map<String, ItemOrigin>? next;
  for (final id in itemIds) {
    if (id.isEmpty ||
        origins.containsKey(id) ||
        next?.containsKey(id) == true) {
      continue;
    }
    (next ??= {...origins})[id] = origin;
  }
  return next ?? origins;
}
