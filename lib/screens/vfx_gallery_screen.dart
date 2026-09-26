import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/skill_vfx.dart';
import '../l10n/app_strings.dart';
import '../widgets/combat_vfx.dart';

/// Edit Mode: plays any skill effect at any power, between a stand-in hero
/// and foe, to see how a style looks from a light touch to a mighty blow.
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
                      child: _StandIn(
                          key: _hero,
                          icon: Icons.person,
                          label: tr(ref, 'vfx_gallery_hero')),
                    ),
                    Positioned(
                      right: 32,
                      top: 40,
                      width: 120,
                      height: 110,
                      child: _StandIn(
                          key: _foe,
                          icon: Icons.pest_control,
                          label: tr(ref, 'vfx_gallery_foe')),
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
  const _StandIn({super.key, required this.icon, required this.label});

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
