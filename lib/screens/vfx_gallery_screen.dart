import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/dice_faces.dart';
import '../combat/skill_vfx.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../widgets/combat_vfx.dart';

/// The stand-in foe's health, for a real skill's share of it.
const int _foeHealth = 60;

/// Shares of the foe's health a previewed skill's blow can take.
const List<double> _shares = [0.05, 0.15, 0.35];

/// Edit Mode: plays any skill effect at any power, between a stand-in hero
/// and foe, to see how a style looks from a light touch to a mighty blow;
/// or a real skill at the power a fight would give it (its rarity, its
/// upgrades, the share of the foe's health it takes, a critical).
class VfxGalleryScreen extends ConsumerStatefulWidget {
  const VfxGalleryScreen({super.key});

  @override
  ConsumerState<VfxGalleryScreen> createState() => _VfxGalleryScreenState();
}

class _VfxGalleryScreenState extends ConsumerState<VfxGalleryScreen> {
  final CombatVfxController _vfx = CombatVfxController();
  final GlobalKey _hero = GlobalKey();
  final GlobalKey _foe = GlobalKey();
  VfxStyle _style = VfxStyle.slash;
  String _element = 'Fire';
  VfxTier _tier = VfxTier.normal;

  // A real skill's preview.
  String? _skillId;
  int _upgrades = 0;
  double _share = _shares[1];
  bool _critical = false;

  @override
  void dispose() {
    _vfx.dispose();
    super.dispose();
  }

  /// A support style lands on the hero, as a heal or a shield would; the
  /// rest fly from the hero to the foe.
  bool get _onHero => supportVfxStyles.contains(_style);

  void _play(VfxTier tier, {int delayMs = 0}) {
    final power = vfxPowerOfTier(tier);
    _vfx.play(
      style: _style,
      target: _onHero ? _hero : _foe,
      source: _onHero ? null : _hero,
      element: _element,
      delayMs: delayMs,
      text: _onHero ? '+${_amountFor(tier)}' : '-${_amountFor(tier)}',
      textKind: _onHero ? VfxTextKind.heal : VfxTextKind.damage,
      power: power,
    );
  }

  /// Every tier in turn, from light to mighty, each once the last is done.
  void _playAll() {
    var delay = 0;
    for (final tier in VfxTier.values) {
      _play(tier, delayMs: delay);
      delay += (vfxDurationMs(_style) * vfxDurationFactor(tier)).round() + 350;
    }
  }

  /// The power a fight would give [skill] with the preview's settings (see
  /// [vfxPowerFor]).
  double _skillPower(Map<String, dynamic> skill) => vfxPowerFor(
        rarity: skill['rarity']?.toString(),
        tier: _upgrades,
        amount: (_share * _foeHealth).round(),
        targetMaxHealth: _foeHealth,
        critical: _critical,
      );

  void _pickSkill(String? id, Map<String, dynamic> skills) {
    final skill = skills[id] as Map<String, dynamic>?;
    setState(() {
      _skillId = id;
      if (skill == null) return;
      _style = styleForFace('Skill', skill);
      final element = skill['element']?.toString() ?? 'None';
      if (vfxElementNames.contains(element)) _element = element;
    });
  }

  /// Plays the picked skill as a fight would: on the hero for a heal, at
  /// the foe for the rest.
  void _playSkill(Map<String, dynamic> skill) {
    final support = isSupportSkill(skill);
    final amount = (_share * _foeHealth).round();
    _vfx.play(
      style: _style,
      target: support ? _hero : _foe,
      source: support ? null : _hero,
      element: _element,
      text: support ? '+$amount' : '-$amount',
      textKind: support
          ? VfxTextKind.heal
          : _critical
              ? VfxTextKind.crit
              : VfxTextKind.damage,
      power: _skillPower(skill),
    );
  }

  static int _amountFor(VfxTier tier) => switch (tier) {
        VfxTier.light => 3,
        VfxTier.normal => 9,
        VfxTier.strong => 18,
        VfxTier.mighty => 34,
      };

  String _tierLabel(VfxTier tier) => tr(ref, 'vfx_tier_${tier.name}');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const styles = VfxStyle.values;
    final lang = ref.watch(appLanguageProvider);
    final skills = ref.watch(localizedDbProvider(skillsSchema)).value ??
        const <String, dynamic>{};
    final skillIds = [
      for (final entry in skills.entries)
        if (!isEnemyOnlySkill(entry.value as Map<String, dynamic>?)) entry.key,
    ]..sort((a, b) => skillDisplayName(a, language: lang)
        .compareTo(skillDisplayName(b, language: lang)));
    final skill = skills[_skillId] as Map<String, dynamic>?;
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'vfx_gallery_title'))),
      body: Column(
        children: [
          // The stage: a hero below left, a foe above right, the effect
          // layer over both.
          SizedBox(
            key: const Key('vfx_gallery_stage'),
            height: 280,
            child: ClipRect(
              child: ColoredBox(
                color: const Color(0xFF1B1A22),
                child: Stack(
                  children: [
                    Positioned(
                      left: 24,
                      bottom: 24,
                      width: 130,
                      height: 72,
                      child: KeyedSubtree(
                        key: _hero,
                        child: VfxRecoil(
                          controller: _vfx,
                          anchor: _hero,
                          child: _StandIn(
                              icon: Icons.person,
                              label: tr(ref, 'vfx_gallery_hero')),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 32,
                      top: 40,
                      width: 120,
                      height: 110,
                      child: KeyedSubtree(
                        key: _foe,
                        child: VfxRecoil(
                          controller: _vfx,
                          anchor: _foe,
                          child: _StandIn(
                              icon: Icons.pest_control,
                              label: tr(ref, 'vfx_gallery_foe')),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CombatVfxLayer(controller: _vfx),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(tr(ref, 'vfx_gallery_intro'),
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                // A real skill, at the power a fight would give it.
                DropdownButtonFormField<String?>(
                  key: const Key('vfx_gallery_skill'),
                  initialValue: _skillId,
                  isExpanded: true,
                  decoration:
                      InputDecoration(labelText: tr(ref, 'vfx_gallery_skill')),
                  items: [
                    DropdownMenuItem<String?>(
                        value: null,
                        child: Text(tr(ref, 'vfx_gallery_no_skill'))),
                    for (final id in skillIds)
                      DropdownMenuItem<String?>(
                          value: id,
                          child: Text(skillDisplayName(id, language: lang),
                              overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (id) => _pickSkill(id, skills),
                ),
                if (skill != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    key: const Key('vfx_gallery_skill_power'),
                    '${tr(ref, 'skill_rarity_${skill['rarity'] ?? 'common'}')}'
                    ' · ${tr(ref, 'vfx_gallery_power')} '
                    '${_skillPower(skill).toStringAsFixed(2)} · '
                    '${_tierLabel(vfxTierFor(_skillPower(skill)))}',
                    style: theme.textTheme.titleSmall,
                  ),
                  Row(
                    children: [
                      Text('${tr(ref, 'vfx_gallery_upgrades')} $_upgrades'),
                      Expanded(
                        child: Slider(
                          value: _upgrades.toDouble(),
                          max: 5,
                          divisions: 5,
                          label: '$_upgrades',
                          onChanged: (v) =>
                              setState(() => _upgrades = v.round()),
                        ),
                      ),
                    ],
                  ),
                  Text(tr(ref, 'vfx_gallery_share'),
                      style: theme.textTheme.labelLarge),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final share in _shares)
                        ChoiceChip(
                          label: Text('${(share * 100).round()} %'),
                          selected: _share == share,
                          onSelected: (_) => setState(() => _share = share),
                        ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr(ref, 'vfx_gallery_critical')),
                    value: _critical,
                    onChanged: (v) => setState(() => _critical = v),
                  ),
                  FilledButton.icon(
                    key: const Key('vfx_gallery_play_skill'),
                    onPressed: () => _playSkill(skill),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(tr(ref, 'vfx_gallery_play_skill')),
                  ),
                ],
                const Divider(height: 28),
                Text(tr(ref, 'vfx_gallery_power'),
                    style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                SegmentedButton<VfxTier>(
                  segments: [
                    for (final tier in VfxTier.values)
                      ButtonSegment(value: tier, label: Text(_tierLabel(tier))),
                  ],
                  selected: {_tier},
                  showSelectedIcon: false,
                  onSelectionChanged: (picked) =>
                      setState(() => _tier = picked.first),
                ),
                const SizedBox(height: 6),
                Text(
                  '${tr(ref, 'vfx_gallery_power')} '
                  '${vfxPowerOfTier(_tier).toStringAsFixed(2)} · '
                  '×${vfxCountFactor(_tier).toStringAsFixed(1)} '
                  '${tr(ref, 'vfx_gallery_particles')} · '
                  '${(vfxDurationMs(_style) * vfxDurationFactor(_tier)).round()} ms',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('vfx_gallery_play'),
                        onPressed: () => _play(_tier),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(tr(ref, 'vfx_gallery_play')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('vfx_gallery_play_all'),
                        onPressed: _playAll,
                        icon: const Icon(Icons.stacked_line_chart),
                        label: Text(tr(ref, 'vfx_gallery_play_all')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(tr(ref, 'vfx_gallery_element'),
                    style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final element in vfxElementNames)
                      ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor:
                              Color(paletteForElement(element).primary),
                          radius: 6,
                        ),
                        label: Text(element),
                        selected: _element == element,
                        onSelected: (_) => setState(() => _element = element),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(tr(ref, 'vfx_gallery_style'),
                    style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final style in styles)
                      ChoiceChip(
                        key: Key('vfx_gallery_style_${style.name}'),
                        label: Text(vfxStyleIds[style] ?? style.name),
                        selected: _style == style,
                        onSelected: (_) {
                          setState(() => _style = style);
                          _play(_tier);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A stand-in card for the stage.
class _StandIn extends StatelessWidget {
  const _StandIn({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2A36),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4A4658)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFBDB6CC), size: 28),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Color(0xFFBDB6CC), fontSize: 12)),
        ],
      ),
    );
  }
}
