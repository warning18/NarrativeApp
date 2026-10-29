// Clan influence in a town's districts (wave 18 step 1, docs/proposals/
// wave18-core.md §4): quests done in a district build a clan's influence
// there; a clan [flipMargin] ahead of the holder takes the district
// (givePlace, cause 'influence'), and a clan holding [influenceTowns]'
// threshold of a town's districts takes the town (cause 'town').
//
// - Influence runs 0..100 per district and clan ([PoliticsState.influence]).
//   A district not moved yet has its holder at [holderStartInfluence] and
//   every other clan at 0.
// - A quest done adds its `influence` (quests.json; else
//   [mainQuestInfluence] for a Main quest, [sideQuestInfluence] for the
//   rest) to the clan the player favoured at its turn-in (the clan the
//   choice taken raises most), else to the quest's own `faction`, in its
//   `district` (else the district the party stands in), wherever the
//   party is (step 2; step 1 counted it only in town).
// - A clan's seat never flips by influence (only by war or the crisis).
// - The flags: `held_<district>_<clan>` for every district with a holder
//   (kept in sync, see [syncHeldFlags]) and `flipped_<district>` once a
//   district changed hands by influence.
//
// Pure rules; the session (a quest turned in) and the playthrough
// simulator play them.
import '../models/story_politics.dart';
import 'clan_power.dart';
import 'factions.dart';
import 'geography.dart';

/// A district's holder's influence there before anything moved it.
const int holderStartInfluence = 20;

/// What a side quest done brings its clan in its district.
const int sideQuestInfluence = 15;

/// What a Main quest done brings.
const int mainQuestInfluence = 25;

/// A clan this far ahead of the holder (at least) takes the district.
const int flipMargin = 15;

const int maxInfluence = 100;

/// The towns a clan takes with their districts, each with how many of its
/// districts the clan must hold (step 2 adds the Ashen Quarter and the
/// Black Reliquary, whose Dead Heart no clan holds: 3 of the other 4).
const Map<String, int> influenceTowns = {
  'saltmouth': 4,
  'ashen_quarter': 3,
  'black_reliquary': 3,
};

/// The flag a district held by [clanId] keeps up (see [syncHeldFlags]).
String heldFlag(String districtId, String clanId) =>
    'held_${districtId}_$clanId';

/// The flag a district changed hands by influence sets, for good.
String districtFlippedFlag(String districtId) => 'flipped_$districtId';

/// [clanId]'s influence in [districtId] now (see the notes above).
int influenceIn(PoliticsState state, Geography geography, String districtId,
    String clanId) {
  final moved = state.influence[districtId];
  if (moved != null) return moved[clanId] ?? 0;
  return clanId.isNotEmpty && holderOf(districtId, geography, state) == clanId
      ? holderStartInfluence
      : 0;
}

/// The clan [picked] (a turn-in choice's politics) favours: the faction of
/// [data] whose standing it raises most; '' when it raises none.
String favouredClanOf(StoryPolitics? picked, ClanData data) {
  var best = '';
  num most = 0;
  for (final e in picked?.standing.entries ?? <MapEntry<String, num>>[]) {
    if (e.value > most && data.faction(e.key) != null) {
      best = e.key;
      most = e.value;
    }
  }
  return best;
}

/// What [quest] (a quests.json record) done brings: its `influence`, else
/// [mainQuestInfluence] or [sideQuestInfluence] by its category.
int questInfluenceAmount(Map<String, dynamic> quest) {
  final own = quest['influence'];
  if (own is num) return own.round();
  return quest['category']?.toString() == 'Main'
      ? mainQuestInfluence
      : sideQuestInfluence;
}

/// What influence did.
class InfluenceResult {
  const InfluenceResult({
    required this.state,
    required this.flags,
    this.districtId = '',
    this.clanId = '',
    this.amount = 0,
    this.flipped,
    this.townTakenBy = '',
  });

  final PoliticsState state;

  /// The flags after: the held flags in sync, `flipped_<district>` added.
  final List<String> flags;
  final String districtId;
  final String clanId;

  /// Influence added (0: nothing counted).
  final int amount;

  /// The district changing hands, or null.
  final TerritoryChange? flipped;

  /// The clan that took the town with its districts, '' for none.
  final String townTakenBy;

  bool get counted => amount > 0;
}

/// [state] with [amount] influence for [clanId] in [districtId] (kept
/// within 0..[maxInfluence]); the district flips to it when it stands
/// [flipMargin] or more over the holder (not a holder's seat), and the town
/// with it at [influenceTowns]' threshold. [flags] come back with the held
/// flags in sync and `flipped_<district>` set on a flip.
InfluenceResult addInfluence(
  PoliticsState state,
  String districtId,
  String clanId,
  int amount, {
  required List<String> flags,
  required ClanData data,
  required Geography geography,
  int chapter = 0,
  int day = 0,
}) {
  if (clanId.isEmpty ||
      amount == 0 ||
      geography.place(districtId)?.level != GeoLevel.district) {
    return InfluenceResult(state: state, flags: flags);
  }
  final holder = holderOf(districtId, geography, state);
  final row = {
    ...state.influence[districtId] ??
        {if (holder.isNotEmpty) holder: holderStartInfluence},
  };
  row[clanId] = ((row[clanId] ?? 0) + amount).clamp(0, maxInfluence);
  var next = state.copyWith(influence: {...state.influence, districtId: row});
  var after = [...flags];
  final changes = <TerritoryChange>[];
  var town = '';
  final seat = data.faction(holder)?.seat ?? '';
  if (clanId != holder &&
      districtId != seat &&
      row[clanId]! >= (row[holder] ?? 0) + flipMargin) {
    next = givePlace(next, districtId, clanId,
        cause: 'influence',
        data: data,
        geography: geography,
        chapter: chapter,
        day: day,
        changes: changes);
    final flag = districtFlippedFlag(districtId);
    if (changes.isNotEmpty && !after.contains(flag)) after.add(flag);
    final city = geography.locationOf(districtId)?.id ?? '';
    final taken = townTurn(next, city,
        data: data, geography: geography, chapter: chapter, day: day);
    next = taken.state;
    town = taken.takenBy;
  }
  after = syncHeldFlags(after, geography, next);
  return InfluenceResult(
    state: next,
    flags: after,
    districtId: districtId,
    clanId: clanId,
    amount: amount,
    flipped: changes.isEmpty ? null : changes.first,
    townTakenBy: town,
  );
}

/// [cityId] (one of [influenceTowns]) after its districts changed hands: a
/// clan holding its threshold of them takes it (givePlace, cause 'town'); a
/// clan that took it and dropped below loses it back to no one.
({PoliticsState state, String takenBy}) townTurn(
  PoliticsState state,
  String cityId, {
  required ClanData data,
  required Geography geography,
  int chapter = 0,
  int day = 0,
}) {
  final threshold = influenceTowns[cityId];
  if (threshold == null) return (state: state, takenBy: '');
  final counts = <String, int>{};
  for (final d in geography.childrenOf(cityId)) {
    if (d.level != GeoLevel.district) continue;
    final h = holderOf(d.id, geography, state);
    if (h.isNotEmpty) counts[h] = (counts[h] ?? 0) + 1;
  }
  final ruler = state.control[cityId] ?? '';
  for (final MapEntry(:key, :value) in counts.entries) {
    if (value >= threshold && key != ruler) {
      final next = givePlace(state, cityId, key,
          cause: 'town',
          data: data,
          geography: geography,
          chapter: chapter,
          day: day);
      return (state: next, takenBy: key);
    }
  }
  if (ruler.isNotEmpty && (counts[ruler] ?? 0) < threshold) {
    return (
      state: state.copyWith(control: {...state.control}..remove(cityId)),
      takenBy: '',
    );
  }
  return (state: state, takenBy: '');
}

/// [quest] (a quests.json record, [questId]) done: its influence (see the
/// notes above) for the clan [picked] favours, else its `faction`, in its
/// `district` (else [partyDistrict]), wherever the party is. Nothing
/// counted without a clan or a district ([InfluenceResult.counted]).
InfluenceResult applyQuestInfluence(
  PoliticsState state,
  Map<String, dynamic> quest, {
  required List<String> flags,
  required ClanData data,
  required Geography geography,
  StoryPolitics? picked,
  String? partyDistrict,
  int chapter = 0,
  int day = 0,
}) {
  final nothing = InfluenceResult(state: state, flags: flags);
  final favoured = favouredClanOf(picked, data);
  final clan =
      favoured.isNotEmpty ? favoured : quest['faction']?.toString() ?? '';
  final own = quest['district']?.toString() ?? '';
  final district = own.isNotEmpty ? own : partyDistrict ?? '';
  if (clan.isEmpty || data.faction(clan) == null || district.isEmpty) {
    return nothing;
  }
  return addInfluence(state, district, clan, questInfluenceAmount(quest),
      flags: flags,
      data: data,
      geography: geography,
      chapter: chapter,
      day: day);
}

/// [flags] with a `held_<district>_<clan>` flag for every district of
/// [geography] with a holder now (holderOf), and none other: a flag for a
/// district held by someone else, or by no one, goes.
List<String> syncHeldFlags(
    List<String> flags, Geography geography, PoliticsState state) {
  final districts = [
    for (final place in geography.places.values)
      if (place.level == GeoLevel.district) place.id,
  ];
  if (districts.isEmpty) return flags;
  final wanted = <String>{
    for (final d in districts)
      if (holderOf(d, geography, state) case final h when h.isNotEmpty)
        heldFlag(d, h),
  };
  final prefixes = [for (final d in districts) 'held_${d}_'];
  bool isHeld(String f) =>
      f.startsWith('held_') && prefixes.any((p) => f.startsWith(p));
  final kept = [
    for (final f in flags)
      if (!isHeld(f) || wanted.contains(f)) f,
  ];
  final next = [
    ...kept,
    for (final f in wanted)
      if (!kept.contains(f)) f,
  ];
  if (next.length == flags.length &&
      [for (var i = 0; i < next.length; i++) next[i] == flags[i]]
          .every((same) => same)) {
    return flags;
  }
  return next;
}
