// The crisis and the fall (v5.2 step 6, PR 2b, the user: "If the falling
// clan is YOUR main clan, it first asks for your help with a crisis";
// docs/proposals/territory-power-nemesis.md addendum A, Narrative's words
// in territory-texts.md 3 and 4).
//
// - The crisis: when a chapter's turn would take your main clan's seat
//   (or its last place), the change waits ([PoliticsState.crisis]) and a
//   scene comes on the next road at rest. Defend it (a fight with the
//   attacker's hunter: won, the seat holds, the attacker loses
//   [defendAttackerPower] power, your clan gains [defendClanPower] and
//   [defendStanding] standing; lost, you may still pay or refuse), pay
//   ([crisisGoldPerChapter] gold a chapter: the attacker takes a lesser
//   place of your clan instead, when it has one; or [crisisMaterialsPrice]
//   in timber and stone, the same), or refuse
//   ([refuseStanding] standing: the seat falls).
// - The fall: your main clan left with no place (crisis or not), a scene
//   asks you to choose. Bend the knee: your standing with the fallen clan
//   moves to the winner (sworn to it when it was Sworn), the fallen clan
//   drops to Resented, and the winner takes a tithe ([titheShare] of your
//   gold). Or stay of the fallen clan: no new oath and no patron's
//   stats, its gifts kept, the winner your nemesis, until you raise a
//   banner of your own (the Open Hand's: the fallen clan pledges to your
//   Host) or the clan rises again.
//
// Pure rules; the story player serves the scenes, the session applies the
// choices' politics.
import 'dart:math';

import '../l10n/app_locale.dart';
import '../models/story_node.dart';
import 'clan_power.dart';
import 'factions.dart';
import 'geography.dart';
import 'patron_stats.dart' show statPatron;
import 'rival_hunters.dart' show rivalHunterPool;

const int defendAttackerPower = 10;
const int defendClanPower = 5;
const int defendStanding = 5;
const int refuseStanding = -10;
const int crisisGoldPerChapter = 40;
const double titheShare = 0.2;

/// The crisis paid in materials instead of gold (the clan's buildings
/// mended): its item ids and counts.
const Map<String, int> crisisMaterialsPrice = {
  'material_timber': 3,
  'material_cut_stone': 2,
};

/// Whether [materials] (counts by item id) hold [crisisMaterialsPrice].
bool holdsCrisisMaterials(Map<String, int> materials) =>
    crisisMaterialsPrice.entries
        .every((e) => (materials[e.key] ?? 0) >= e.value);

/// The standing the fallen clan drops to when you bend the knee: Resented.
const double kneelFallenStanding = -20;

/// Your main clan: the sworn one, else your patron (patron_stats.dart).
String mainClanOf(PoliticsState state) =>
    state.swornFactionId.isNotEmpty ? state.swornFactionId : statPatron(state);

/// The id prefix of the crisis and fall scenes, whose politics the story
/// player applies though they are met on a road.
const String clanCrisisNodePrefix = 'clan_crisis_';
bool isClanCrisisNode(String? nodeId) =>
    nodeId?.startsWith(clanCrisisNodePrefix) ?? false;

/// The fall waiting for your choice: your main clan fallen and not yet
/// chosen over; null for none.
({String clan, String winner})? pendingFall(PoliticsState state) {
  final main = mainClanOf(state);
  if (main.isEmpty || !state.fallen.contains(main)) return null;
  if (state.fallenOf == main) return null;
  return (clan: main, winner: state.fellTo[main] ?? '');
}

/// [state] after the crisis [how] ('held', 'paid' or 'refused') settles:
/// the crisis cleared. (The rest is the choice's politics.)
PoliticsState settleCrisis(PoliticsState state, String how) =>
    state.copyWith(crisis: const {});

/// [state] with the character bending the knee to [winner]: their
/// standing with their fallen main clan moves to it (sworn when it was
/// Sworn), the fallen clan drops to [kneelFallenStanding].
PoliticsState bendTheKnee(
  PoliticsState state,
  String winner,
  ClanData data, {
  int chapter = 0,
  int day = 0,
}) {
  final fallen = mainClanOf(state);
  if (fallen.isEmpty || winner.isEmpty || winner == fallen) return state;
  final carried = state.standingOf(fallen, data);
  var next = setStandingValue(
          state, fallen, min(carried, kneelFallenStanding), 'kneel:$winner',
          data: data, chapter: chapter, day: day)
      .state;
  if (next.standingOf(winner, data) < carried) {
    next = setStandingValue(next, winner, carried, 'kneel:$winner',
            data: data, chapter: chapter, day: day)
        .state;
  }
  return next.copyWith(fallenOf: '', fallenWinner: '');
}

/// [state] with the character staying of their fallen main clan [clan]:
/// clanless, the winner their nemesis, until a banner of their own.
PoliticsState stayOfFallen(PoliticsState state, String clan) => state.copyWith(
      fallenOf: clan,
      fallenWinner: state.fellTo[clan] ?? '',
      nemesis: state.fellTo[clan] ?? state.nemesis,
    );

/// [state] with the fallen clan's hold on the character let go when it is
/// over: a banner raised ([bannerRaised]: the clan pledges to the Host) or
/// the clan risen again. Unchanged otherwise.
PoliticsState settleFallenLoyalty(PoliticsState state,
    {required bool bannerRaised}) {
  final clan = state.fallenOf;
  if (clan.isEmpty) return state;
  if (!bannerRaised && state.fallen.contains(clan)) return state;
  return state.copyWith(
    fallenOf: '',
    fallenWinner: '',
    nemesis: state.nemesis == state.fallenWinner ? '' : state.nemesis,
    pledged: bannerRaised && !state.pledged.contains(clan)
        ? [...state.pledged, clan]
        : null,
  );
}

String _name(ClanData data, String id, bool fr) =>
    data.faction(id)?.nameFor(fr ? AppLanguage.fr : AppLanguage.en) ?? id;

/// The crisis scene for [state]'s crisis (Narrative's 3), or null for
/// none: Defend (a fight with a hunter of the attacker, [enemies] for
/// [chapter]), Pay ([crisisGoldPerChapter] a chapter, when [gold] holds
/// it) and Refuse.
StoryNode? buildCrisisNode(
  PoliticsState state, {
  required ClanData data,
  required Geography geography,
  required Map<String, dynamic> enemies,
  required int chapter,
  required int gold,
  required Random random,
  Map<String, int> materials = const {},
}) {
  final clan = state.crisis['clan'] ?? '';
  final attacker = state.crisis['attacker'] ?? '';
  final placeId = state.crisis['place'] ?? '';
  final place = geography.place(placeId);
  if (clan.isEmpty || attacker.isEmpty || place == null) return null;
  String fill(String line, bool fr) => line
      .replaceAll('{clan}', _name(data, clan, fr))
      .replaceAll('{attacker}', _name(data, attacker, fr))
      .replaceAll('{seat}', place.nameFor(fr))
      .replaceAll('{gold}', '${crisisGoldPerChapter * max(1, chapter)}');
  // The attacker's hunter, or any of its fighters met on the roads.
  final pool = rivalHunterPool(
      enemies: enemies, clanId: attacker, chapter: max(chapter, 3));
  final defender = pool.isEmpty ? null : pool[random.nextInt(pool.length)];
  final int price = crisisGoldPerChapter * (chapter < 1 ? 1 : chapter);
  // A lesser place the attacker takes when paid off, if the clan has one.
  final lesser =
      placesOf(clan, geography, state).where((p) => p != placeId).toList();
  return StoryNode(
    id: '$clanCrisisNodePrefix${clan}_${random.nextInt(1 << 30)}',
    description: fill(_crisisBodyEn, false),
    descriptionFr: fill(_crisisBodyFr, true),
    contextNote: fill(_crisisTitleEn, false),
    contextNoteFr: fill(_crisisTitleFr, true),
    choices: [
      if (defender != null)
        StoryChoice(
          text: fill('Defend {seat}', false),
          textFr: fill('Défendre {seat}', true),
          nextId: '',
          triggerEnemyId: defender,
          politics: StoryPolitics(
            standing: {clan: defendStanding},
            power: {clan: defendClanPower, attacker: -defendAttackerPower},
            settleCrisis: 'held',
          ),
        ),
      if (gold >= price)
        StoryChoice(
          text: fill('Pay {gold} gold', false),
          textFr: fill('Payer {gold} pièces d’or', true),
          nextId: '',
          goldMod: -price,
          politics: StoryPolitics(
            control: {if (lesser.isNotEmpty) lesser.last: attacker},
            settleCrisis: 'paid',
          ),
        ),
      if (holdsCrisisMaterials(materials))
        StoryChoice(
          text: 'Send timber and stone',
          textFr: 'Envoyer bois et pierre',
          nextId: '',
          grantMaterials: {
            for (final e in crisisMaterialsPrice.entries) e.key: -e.value,
          },
          politics: StoryPolitics(
            control: {if (lesser.isNotEmpty) lesser.last: attacker},
            settleCrisis: 'paid',
          ),
        ),
      StoryChoice(
        text: 'Refuse',
        textFr: 'Refuser',
        nextId: '',
        politics: StoryPolitics(
          standing: {clan: refuseStanding},
          control: {placeId: attacker},
          settleCrisis: 'refused',
        ),
      ),
    ],
  );
}

/// The fall's scene for [state] (Narrative's 4b), or null when no fall
/// waits: bend the knee to the winner (its tithe, [titheShare] of [gold])
/// or stay of the fallen clan.
StoryNode? buildFallNode(
  PoliticsState state, {
  required ClanData data,
  required Geography geography,
  required int gold,
  required Random random,
}) {
  final fall = pendingFall(state);
  if (fall == null) return null;
  final seatId = data.faction(fall.clan)?.seat ?? '';
  final seat = geography.place(seatId);
  String fill(String line, bool fr) => line
      .replaceAll('{clan}', _name(data, fall.clan, fr))
      .replaceAll('{winner}', _name(data, fall.winner, fr))
      .replaceAll(
          '{seat}', seat?.nameFor(fr) ?? (fr ? 'son siège' : 'its seat'));
  return StoryNode(
    id: '$clanCrisisNodePrefix${fall.clan}_fall_${random.nextInt(1 << 30)}',
    description: fill(_fallBodyEn, false),
    descriptionFr: fill(_fallBodyFr, true),
    contextNote: fill('The banner comes down.', false),
    contextNoteFr: fill('La bannière descend.', true),
    choices: [
      if (fall.winner.isNotEmpty)
        StoryChoice(
          text: fill('Bend the knee to {winner}', false),
          textFr: fill('Plier le genou devant {winner}', true),
          nextId: '',
          goldMod: -(gold * titheShare).floor(),
          politics: StoryPolitics(bendKnee: fall.winner),
        ),
      StoryChoice(
        text: fill('Stay of {clan}', false),
        textFr: fill('Rester de {clan}', true),
        nextId: '',
        politics: StoryPolitics(stayFallen: fall.clan),
      ),
    ],
  );
}

/// The crisis or the fall due on a road at rest, as a one-node chain, or
/// null: the crisis first.
List<StoryNode>? clanCrisisRoadEvent(
  PoliticsState state, {
  required ClanData data,
  required Geography geography,
  required Map<String, dynamic> enemies,
  required int chapter,
  required int gold,
  required Random random,
  Map<String, int> materials = const {},
}) {
  final crisis = buildCrisisNode(state,
      data: data,
      geography: geography,
      enemies: enemies,
      chapter: chapter,
      gold: gold,
      random: random,
      materials: materials);
  if (crisis != null) return [crisis];
  final fall = buildFallNode(state,
      data: data, geography: geography, gold: gold, random: random);
  return fall == null ? null : [fall];
}

// --- Narrative's words (territory-texts.md 3 and 4) ----------------------

const String _crisisTitleEn = '{clan} sends for you.';
const String _crisisTitleFr = '{clan} vous fait appeler.';
const String _crisisBodyEn =
    'A rider finds you on the road at dusk. {attacker} is at the gates of '
    '{seat}, and {clan} has nothing left to hold them with but you. “It is '
    'not a command. It is the last thing we have to ask.”';
const String _crisisBodyFr =
    'À la nuit tombante, un messager vous rejoint sur la route. {attacker} '
    'est aux portes de {seat}, et {clan} n’a plus que vous pour les '
    'retenir. « Ce n’est pas un ordre. C’est la dernière chose qu’il '
    'nous reste à demander. »';
const String _fallBodyEn =
    'The last banner over {seat} is folded. {winner}’s people stand in the '
    'yard, and {clan}’s survivors look at you the way you look at a road '
    'that has ended. “You do not have to follow us into the dark,” they '
    'say. “But nobody will think the worse of you if you do.”';
const String _fallBodyFr =
    'La dernière bannière sur {seat} est pliée. Les gens de {winner} sont '
    'dans la cour, et les survivants de {clan} vous regardent comme on '
    'regarde une route qui s’arrête. « Vous n’avez pas à nous suivre '
    'dans le noir, disent-ils. Mais personne ne vous en voudra si vous le '
    'faites. »';
