import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/dice_faces.dart';
import '../combat/enemy_intent.dart' show elementLabel;
import '../combat/face_keywords.dart';
import '../combat/face_smithing.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/face_style.dart';
import '../utils/game_icons.dart';
import 'immersive_notice.dart';
import 'player_stats_bar.dart';

/// Opens the Hammersmith's dice smithing (v1.182, see face_smithing.dart):
/// the party's dice, face by face.
Future<void> showDiceSmithingSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.9,
      child: _DiceSmithingSheet(),
    ),
  );
}

class _DiceSmithingSheet extends ConsumerStatefulWidget {
  const _DiceSmithingSheet();

  @override
  ConsumerState<_DiceSmithingSheet> createState() => _DiceSmithingSheetState();
}

class _DiceSmithingSheetState extends ConsumerState<_DiceSmithingSheet> {
  /// 'player', or a recruited companion's id.
  String _owner = 'player';
  int? _faceIndex;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerSessionProvider);
    final dice = ref.watch(localizedDbProvider(diceSchema)).value ??
        const <String, dynamic>{};
    final companions = ref.watch(localizedDbProvider(companionsSchema)).value ??
        const <String, dynamic>{};
    final items = ref.watch(localizedDbProvider(itemsSchema)).value ??
        const <String, dynamic>{};
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);

    // Who has a die here: the player's equipped one, and each companion
    // still with the party (their signature die).
    final owners = <({String id, String name, String? dieId})>[
      (
        id: 'player',
        name: session.characterName.isNotEmpty
            ? session.characterName
            : trFor(lang, 'you_label'),
        dieId: session.equippedDiceId,
      ),
      for (final ally in session.recruitedAllies)
        if (!session.lostAllyIds.contains(ally.companionId) &&
            !session.departedAllyIds.contains(ally.companionId))
          (
            id: ally.companionId,
            name: (companions[ally.companionId]
                        as Map<String, dynamic>?)?['companionName']
                    ?.toString() ??
                ally.companionId,
            dieId: (companions[ally.companionId]
                    as Map<String, dynamic>?)?['signatureDiceId']
                ?.toString(),
          ),
    ];
    final owner =
        owners.firstWhere((o) => o.id == _owner, orElse: () => owners.first);
    final dieId = owner.dieId;
    // A companion's die is worked apart from the player's own copy of it.
    final companionId = owner.id == 'player' ? null : owner.id;
    final rawFaces =
        ((dice[dieId ?? ''] as Map<String, dynamic>?)?['faces'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
    final upgrades =
        session.upgradesOfDie(dieId, companionId: companionId) ?? const {};
    final faces = smithedFaces(rawFaces, upgrades);
    final assignments = owner.id == 'player'
        ? session.diceSkillAssignments[dieId ?? ''] ?? const <String, String>{}
        : session.recruitedAllies
            .firstWhere((a) => a.companionId == owner.id)
            .diceSkillAssignments;

    int carried(String id) =>
        session.inventoryItemIds.where((i) => i == id).length;
    final trophies = trophyItemIds.fold<int>(0, (n, id) => n + carried(id));
    String itemName(String id) {
      final item = items[id] as Map<String, dynamic>?;
      return item?['itemName']?.toString() ?? id;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(trFor(lang, 'smith_title'),
                    style: theme.textTheme.titleMedium),
              ),
              const GoldBadge(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child:
              Text(trFor(lang, 'smith_hint'), style: theme.textTheme.bodySmall),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            '${itemName(ironOreId)}: ${carried(ironOreId)} · '
            '${trFor(lang, 'smith_trophy_label')}: $trophies',
            style: theme.textTheme.labelMedium,
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final o in owners)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(o.name),
                    selected: o.id == owner.id,
                    onSelected: (_) => setState(() {
                      _owner = o.id;
                      _faceIndex = null;
                    }),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (dieId != null)
                Text(dieDisplayName(dieId, language: lang),
                    style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(trFor(lang, 'smith_pick_face'),
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < faces.length; i++)
                    _faceTile(faces[i], i, assignments, lang,
                        worked: !(upgrades[i.toString()]?.isEmpty ?? true)),
                ],
              ),
              if (_faceIndex != null &&
                  dieId != null &&
                  _faceIndex! < rawFaces.length) ...[
                const SizedBox(height: 16),
                ..._workOptions(
                  dieId: dieId,
                  companionId: companionId,
                  index: _faceIndex!,
                  rawFaces: rawFaces,
                  current: upgrades[_faceIndex.toString()] ?? FaceUpgrade.none,
                  lang: lang,
                  itemName: itemName,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _faceTile(Map<String, dynamic> face, int index,
      Map<String, String> assignments, AppLanguage lang,
      {required bool worked}) {
    final colorScheme = Theme.of(context).colorScheme;
    final type = face['type']?.toString() ?? '';
    final kind = faceKind(type);
    final name = faceDisplayName(face,
        assignedSkillId: assignments[index.toString()], language: lang);
    final value = (face['value'] as num?)?.toInt() ?? 0;
    final element = face['element']?.toString() ?? 'None';
    final selected = _faceIndex == index;
    return InkWell(
      onTap: () => setState(() => _faceIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 96,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: kind.color.withValues(alpha: selected ? 0.25 : 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(kind.icon, size: 16, color: kind.color),
                if (type != 'Skill' && value > 0) ...[
                  const SizedBox(width: 3),
                  Text('$value',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: kind.color)),
                ],
                if (element != 'None') ...[
                  const SizedBox(width: 3),
                  Icon(elementIcon(element), size: 13),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaceKeywordBadges(faceKeywordsOf(face), size: 12),
                if (worked)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Tooltip(
                      message: trFor(lang, 'smith_worked_label'),
                      child: const Icon(Icons.hardware, size: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _workOptions({
    required String dieId,
    required String? companionId,
    required int index,
    required List<Map<String, dynamic>> rawFaces,
    required FaceUpgrade current,
    required AppLanguage lang,
    required String Function(String) itemName,
  }) {
    final face = rawFaces[index];
    final notifier = ref.read(playerSessionProvider.notifier);
    final theme = Theme.of(context);
    String costLine(SmithingCost cost) => [
          '${cost.gold} ${trFor(lang, 'gold_label')}',
          if (cost.iron > 0) '${itemName(ironOreId)} ×${cost.iron}',
          if (cost.trophies > 0)
            '${trFor(lang, 'smith_trophy_label')} ×${cost.trophies}',
        ].join(' · ');

    Future<void> work(SmithingWork kind,
        {String? element, FaceKeyword? keyword, String? recastType}) async {
      final done = await notifier.smithFace(
        dieId: dieId,
        companionId: companionId,
        faceIndex: index,
        faces: rawFaces,
        work: kind,
        element: element,
        keyword: keyword,
        recastType: recastType,
      );
      if (!done || !mounted) return;
      showImmersiveNotice(
        context,
        icon: Icons.hardware,
        message: trFor(lang, 'smith_done')
            .replaceAll('{work}', trFor(lang, smithingWorkLabelKey(kind))),
      );
    }

    final baseType = face['type']?.toString() ?? '';
    final type = current.recastType ?? baseType;
    // The number a Recast to [target] leaves on the face (see recastValue).
    int recastNumber(String target) =>
        recastValue((face['value'] as num?)?.toInt() ?? 0, target, rawFaces) +
        current.hones * honeStep;
    final options = <Widget>[];
    for (final kind in SmithingWork.values) {
      if (!canSmith(kind, face, current)) continue;
      final cost = smithingCostFor(kind, current);
      final affordable = notifier.canPaySmithing(cost);
      final List<({String label, String? tip, VoidCallback onTap})> picks =
          switch (kind) {
        SmithingWork.hone => [
            (
              label: '+$honeStep',
              tip: null,
              onTap: () => work(SmithingWork.hone),
            ),
          ],
        SmithingWork.temper => [
            for (final element in temperableElements(face, current))
              (
                label: elementLabel(element, lang),
                tip: null,
                onTap: () => work(SmithingWork.temper, element: element),
              ),
          ],
        SmithingWork.inscribe => [
            for (final keyword in inscribableKeywords(face, current))
              (
                label: trFor(lang, keywordLabelKey(keyword)),
                tip: trFor(lang, keywordDescriptionKey(keyword)),
                onTap: () => work(SmithingWork.inscribe, keyword: keyword),
              ),
          ],
        SmithingWork.recast => [
            for (final target in smithableBasicTypes)
              if (target != type)
                (
                  label: '${trFor(lang, basicFaceLabelKey(target))} '
                      '${recastNumber(target)}',
                  tip: null,
                  onTap: () => work(SmithingWork.recast, recastType: target),
                ),
          ],
      };
      if (picks.isEmpty) continue;
      options.add(Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trFor(lang, smithingWorkLabelKey(kind)),
                  style: theme.textTheme.titleSmall),
              Text(trFor(lang, smithingWorkDescriptionKey(kind)),
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text('${trFor(lang, 'smith_cost_label')}: ${costLine(cost)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: affordable ? null : theme.colorScheme.error)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final pick in picks)
                    Tooltip(
                      message: pick.tip ?? pick.label,
                      child: FilledButton.tonal(
                        onPressed: affordable ? pick.onTap : null,
                        child: Text(pick.label),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ));
    }
    if (options.isEmpty) {
      return [
        Text(trFor(lang, 'smith_nothing'), style: theme.textTheme.bodySmall),
      ];
    }
    return options;
  }
}
