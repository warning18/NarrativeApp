// Mercy for a rival's hunter (v1.387, the user: "You can spare them, but
// depending on their alignment vs yours they may stab you in the back. You
// can know their alignment if your Perception is high."). A rival hunter
// (rival_hunters.dart) beaten yields; the party spares it or finishes it.
//
// - Spared: the fight's experience, no gold and no loot (it keeps them),
//   and [spareStanding] with its clan (the usual ripple: its rivals, your
//   own patron among them, lose a little). A betrayal is rolled at
//   [betrayalChance]: the same hunter comes back on a road at rest
//   [betrayalMinRoads] to [betrayalMaxRoads] roads later and strikes first
//   (an ambush), and can't be spared again. Otherwise it is gone for good.
// - Finished: the spoils as ever, and [finishStanding] with its clan.
// - Perception [readAlignmentPerception] or more reads the hunter's
//   alignment on the choice: its side, and whether it is close to yours.
//
// The state is kept in the session's flags: `betrayal_<enemy>_<roads>`
// (a betrayal on its way), `betrayer_<enemy>` (no mercy twice) and
// `spared_<enemy>` (gone). Pure rules; the fight screen, the story's roads
// and the playthrough simulator play them.
import 'dart:math';

import '../models/story_node.dart';
import 'alignment_events.dart' show alignmentThreshold;

const int spareStanding = 3;
const int finishStanding = -2;

const double betrayalBase = 0.10;
const double betrayalPerPoint = 0.004;
const double betrayalMax = 0.60;

/// The Perception that reads a hunter's alignment.
const int readAlignmentPerception = 5;

/// Within this much of yours, a hunter's alignment reads "close".
const int closeAlignment = 30;

const int betrayalMinRoads = 1;
const int betrayalMaxRoads = 4;

/// A hunter's alignment (enemies.json's `alignment`; 0 when unwritten).
int hunterAlignmentOf(Map<String, dynamic>? enemy) =>
    (enemy?['alignment'] as num?)?.toInt() ?? 0;

/// The chance a hunter of [hunter] alignment spared by a character of
/// [player] alignment comes back to stab them.
double betrayalChance(int hunter, int player) =>
    min(betrayalMax, betrayalBase + betrayalPerPoint * (hunter - player).abs());

/// How a high Perception reads a hunter: its side ('good', 'neutral',
/// 'evil') and whether it is close to the reader's alignment.
({String side, bool close}) readHunter(int hunter, int player) => (
      side: hunter >= alignmentThreshold
          ? 'good'
          : hunter <= -alignmentThreshold
              ? 'evil'
              : 'neutral',
      close: (hunter - player).abs() <= closeAlignment,
    );

String betrayerFlag(String enemyId) => 'betrayer_$enemyId';
String sparedFlag(String enemyId) => 'spared_$enemyId';
String betrayalFlag(String enemyId, int roads) => 'betrayal_${enemyId}_$roads';

final RegExp _betrayal = RegExp(r'^betrayal_(.+)_(\d+)$');

/// The betrayals on their way in [flags]: enemy id → roads left.
Map<String, int> pendingBetrayals(Iterable<String> flags) => {
      for (final flag in flags)
        if (_betrayal.firstMatch(flag) case final m?)
          m.group(1)!: int.parse(m.group(2)!),
    };

/// Whether [enemyId] may be spared: it has never betrayed the party.
bool sparable(String enemyId, Iterable<String> flags) =>
    !flags.contains(betrayerFlag(enemyId));

/// The roads before a betrayal comes, rolled.
int betrayalRoads(Random random) =>
    betrayalMinRoads + random.nextInt(betrayalMaxRoads - betrayalMinRoads + 1);

const String _backstabEn =
    '{name} steps out of cover behind you. You spared that life, and this is what came of it. {cry}';
const String _backstabFr =
    '{name} surgit derrière vous. Vous aviez épargné cette vie ; voici ce qu’elle en a fait. {cry}';

/// The betrayal's ambush: a one-node chain in which [enemyId] (from
/// [enemies]) strikes first.
StoryNode betrayalAmbushNode(
    String enemyId, Map<String, dynamic> enemies, Random random) {
  final enemy = enemies[enemyId] as Map<String, dynamic>? ?? const {};
  String text(String key) => enemy[key]?.toString() ?? '';
  final nameFr =
      text('enemyName_fr').isEmpty ? text('enemyName') : text('enemyName_fr');
  return StoryNode(
    id: 'betrayal_${enemyId}_${random.nextInt(1 << 30)}',
    description: _backstabEn
        .replaceAll('{name}', text('enemyName'))
        .replaceAll('{cry}', text('battleCry')),
    descriptionFr: _backstabFr
        .replaceAll('{name}', nameFr)
        .replaceAll('{cry}', text('battleCry_fr')),
    choices: [
      StoryChoice(
        text: 'Turn and fight',
        textFr: 'Se retourner et combattre',
        nextId: '',
        triggerEnemyId: enemyId,
        isHunterAmbush: true,
        forcedCondition: 'ambush',
      ),
    ],
  );
}
