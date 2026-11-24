// "A merge is ready": the plate at the top of the Skills screen while the
// character knows the two skills of a recipe and not yet its result
// (v1.990, UX-2). The recipe in three icons (the result in its rarity's
// frame), a line on what becomes what, and one way on: "Craft at the
// Skillwright" when it stands, else what it costs and, at the camp, the
// way there. Core's data decides everything (skill_craft.dart); this only
// draws it. The camp tab's dot says the same thing from the camp's side.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camp_state.dart' show CampPresence;
import '../data/skill_craft.dart';
import '../gamedata/db_schema.dart'
    show housesSchema, skillMergesSchema, skillsSchema;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/camp_presence_provider.dart';
import '../providers/game_db_providers.dart'
    show gameDbProvider, localizedDbProvider;
import '../providers/home_tab_provider.dart';
import '../providers/player_session_provider.dart';
import '../screens/skills/skill_sheet.dart' show openCraft;
import '../theme/icon_sizes.dart';
import '../theme/pixel_chip.dart';
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'clan_offer_gifts.dart' show CardTier;
import 'story_panel.dart' show StoryFrame, StoryPlate, storyInkOn;

/// The rarity a skill record names, as a frame tier.
CardTier _tierOf(Object? rarity) => switch (rarity?.toString()) {
      'legendary' => CardTier.legendary,
      'epic' => CardTier.epic,
      'rare' => CardTier.rare,
      'uncommon' => CardTier.uncommon,
      _ => CardTier.common,
    };

/// The Camp tab's place among the play tabs (Journey, Character, Camp,
/// Other).
const int _campTab = 2;

class MergeReadyPlate extends ConsumerWidget {
  const MergeReadyPlate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final known = ref.watch(
        playerSessionProvider.select((s) => s.unlockedSkillIds.toList()));
    final built = skillCraftOpen(
        ref.watch(playerSessionProvider.select((s) => s.builtHouseIds)));
    final merges = ref.watch(localizedDbProvider(skillMergesSchema)).value ??
        const <String, dynamic>{};
    final ready = [
      for (final recipe in craftRecipesFor(
          merges: merges, unlockedSkillIds: known, language: lang))
        if (recipe.ready) recipe,
    ];
    if (ready.isEmpty) return const SizedBox.shrink();
    final recipe = ready.first;
    final skills = ref.watch(localizedDbProvider(skillsSchema)).value ??
        const <String, dynamic>{};
    final houses = ref.watch(gameDbProvider(housesSchema)).value ?? const {};
    final cost =
        ((houses[skillwrightHouseId] as Map?)?['buildCost'] as num?)?.toInt() ??
            0;
    final atCamp = ref.watch(campPresenceProvider) == CampPresence.atCamp;
    final theme = Theme.of(context);
    final ink = InkColors.of(context);

    Widget icon(String id) => Container(
          width: 36,
          height: 36,
          decoration: ShapeDecoration(
            color: theme.colorScheme.surface,
            shape: PixelChipBorder(
                side: BorderSide(color: ink.seam, width: 1.5),
                step: 2,
                steps: 2),
          ),
          alignment: Alignment.center,
          child: SkillPixelIcon(id, size: IconSize.s32 - 6),
        );
    final a = recipe.inputs.first;
    final b = recipe.inputs.last;
    final result = recipe.result;
    final body = tr(ref, 'merge_ready_body')
        .replaceAll('{a}', a.name)
        .replaceAll('{b}', b.name)
        .replaceAll('{c}', result.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: StoryPlate(
        key: const Key('merge_ready_plate'),
        title: tr(ref, 'merge_ready_title'),
        color: ink.tide,
        lead: Icon(Icons.auto_fix_high,
            size: IconSize.s16, color: storyInkOn(ink.tide)),
        trail: ready.length > 1
            ? Text(
                tr(ref, 'merge_ready_more')
                    .replaceAll('{n}', '${ready.length - 1}'),
                key: const Key('merge_ready_more'),
                style: TextStyle(
                    fontFamily: InkFonts.system,
                    fontSize: 10,
                    color: storyInkOn(ink.tide)))
            : null,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              icon(a.id),
              const SizedBox(width: 6),
              Text('+', style: theme.textTheme.titleMedium),
              const SizedBox(width: 6),
              icon(b.id),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: IconSize.s16, color: ink.ash),
              const SizedBox(width: 8),
              // The result wears its rarity's frame.
              StoryFrame(
                tier: _tierOf((skills[result.id] as Map?)?['rarity']),
                band: 0.5,
                padding: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: SkillPixelIcon(result.id, size: IconSize.s32 - 6),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(body,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontFamily: InkFonts.prose, height: 1.4)),
            const SizedBox(height: 10),
            if (built)
              FilledButton.icon(
                key: const Key('merge_ready_craft'),
                onPressed: () => openCraft(context, ref),
                icon: const Icon(Icons.auto_fix_high, size: IconSize.s16),
                label: Text(tr(ref, 'craft_skill_button')),
              )
            else ...[
              Text(tr(ref, 'merge_ready_unbuilt').replaceAll('{gold}', '$cost'),
                  key: const Key('merge_ready_unbuilt'),
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: InkFonts.prose,
                      fontStyle: FontStyle.italic,
                      color: ink.ash)),
              // The camp tab is there to go to while the party is at the camp.
              if (atCamp) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('merge_ready_go_camp'),
                  onPressed: () {
                    // The Skills screen is a page over the tabs: leave it.
                    Navigator.of(context).maybePop();
                    ref.read(homeTabIndexProvider.notifier).state = _campTab;
                  },
                  icon: const Icon(Icons.local_fire_department_outlined,
                      size: IconSize.s16),
                  label: Text(tr(ref, 'merge_ready_go_camp')),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
