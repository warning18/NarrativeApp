import '../l10n/app_locale.dart';
import 'factions.dart';
import 'road_events.dart' show stableHash;

/// What a shop has on its shelf (v1.197), and who keeps it.
///
/// Most shops sell their `initialStock`. A wandering shop (the Wayfarer's
/// Caravan) carries a `stockPool` and draws `stockDraw` of it each chapter,
/// always including one thing from the chapter ahead when the pool holds
/// one: the same draw for the same chapter on every device.

/// The item ids on [shop]'s shelf in [chapter].
List<String> shopStockFor(Map<String, dynamic> shop, {required int chapter}) {
  final pool = _ids(shop['stockPool']);
  final draw = (shop['stockDraw'] as num?)?.toInt() ?? 0;
  if (pool.isEmpty) return _ids(shop['initialStock']);
  if (draw <= 0 || draw >= pool.length) return pool;
  final seed = stableHash('${shop['shopID']}@$chapter');
  final order = [...pool]..sort((a, b) {
      final ha = stableHash('$seed:$a'), hb = stableHash('$seed:$b');
      return ha != hb ? ha.compareTo(hb) : a.compareTo(b);
    });
  final picked = order.take(draw).toList();
  return picked;
}

/// [shopStockFor], with one item of the chapter ahead (its `lootChapter`
/// past [chapter]) swapped in when the draw holds none and the pool does.
List<String> shopStockWithAhead(Map<String, dynamic> shop,
    {required int chapter, required Map<String, dynamic> items}) {
  final picked = shopStockFor(shop, chapter: chapter);
  final pool = _ids(shop['stockPool']);
  if (pool.isEmpty || picked.length == pool.length) return picked;
  int lootChapter(String id) =>
      ((items[id] as Map<String, dynamic>?)?['lootChapter'] as num?)?.toInt() ??
      0;
  if (picked.any((id) => lootChapter(id) > chapter)) return picked;
  final ahead = pool.where((id) => lootChapter(id) > chapter).toList();
  if (ahead.isEmpty) return picked;
  final seed = stableHash('${shop['shopID']}@$chapter:ahead');
  ahead
      .sort((a, b) => stableHash('$seed:$a').compareTo(stableHash('$seed:$b')));
  return [...picked.take(picked.length - 1), ahead.first];
}

/// Everything [shop] may ever sell: the shelf, or the whole pool.
List<String> allShopStock(Map<String, dynamic>? shop) {
  if (shop == null) return const [];
  final pool = _ids(shop['stockPool']);
  return pool.isEmpty ? _ids(shop['initialStock']) : pool;
}

List<String> _ids(Object? raw) =>
    (raw as List?)?.map((e) => e.toString()).toList() ?? const [];

/// The keeper's name in [language], or null for a shop with no keeper.
String? shopKeeperName(Map<String, dynamic> shop, AppLanguage language) {
  final fr = shop['keeperName_fr']?.toString().trim();
  final en = shop['keeperName']?.toString().trim();
  final name = language == AppLanguage.fr && (fr ?? '').isNotEmpty ? fr : en;
  return (name ?? '').isEmpty ? null : name;
}

/// What the keeper says to a character standing at [tier] with the shop's
/// faction (null: no faction): their Wary line below Unknown, their
/// Trusted or Sworn line above Known, their plain line otherwise, and the
/// plain line again where a shop has no line for the tier.
String? shopKeeperLine(Map<String, dynamic> shop, AppLanguage language,
    {StandingTier? tier}) {
  String? line(String key) {
    final fr = shop['${key}_fr']?.toString().trim();
    final en = shop[key]?.toString().trim();
    final text = language == AppLanguage.fr && (fr ?? '').isNotEmpty ? fr : en;
    return (text ?? '').isEmpty ? null : text;
  }

  final special = switch (tier) {
    StandingTier.hunted ||
    StandingTier.hostile ||
    StandingTier.wary =>
      line('keeperLineWary'),
    StandingTier.trusted => line('keeperLineTrusted'),
    StandingTier.sworn => line('keeperLineSworn') ?? line('keeperLineTrusted'),
    _ => null,
  };
  return special ?? line('keeperLine');
}
