// The eight abilities as one shape (v1.224): a radar with each ability's
// short name and value at its corner. With a [before] shape, that one is
// drawn dashed behind it and every corner that moved shows its change.
import 'package:flutter/material.dart';

import '../data/element_points.dart';
import '../combat/skill_vfx.dart';
import 'radar_chart.dart';

/// The abilities in the order the radar draws them, clockwise from the top.
const List<String> abilityRadarOrder = [
  'strength',
  'dexterity',
  'constitution',
  'intelligence',
  'wisdom',
  'perception',
  'luck',
  'charisma',
];

/// The l10n key of an ability's short name.
String abilityAbbrevKey(String ability) => switch (ability) {
      'strength' => 'str_abbrev',
      'dexterity' => 'dex_abbrev',
      'constitution' => 'con_abbrev',
      'intelligence' => 'int_abbrev',
      'wisdom' => 'wis_abbrev',
      'perception' => 'per_abbrev',
      'luck' => 'luck_abbrev',
      _ => 'cha_abbrev',
    };

/// A shape's colour for the abilities, the change colours, and a quiet one
/// for what a shape is compared with.
const Color radarGold = Color(0xFFF2C14E);
const Color radarMore = Color(0xFF6FD08C);
const Color radarLess = Color(0xFFEF5350);
const Color radarCompare = Color(0xFF9FB0C2);

class AbilityRadar extends StatelessWidget {
  const AbilityRadar({
    super.key,
    required this.values,
    required this.t,
    this.before,
    this.color = radarGold,
    this.beforeLabel,
    this.nowLabel,
    this.size = 320,
    this.compact = false,
    this.onAxisTap,
  });

  /// A tap on an ability's corner (its key, as in [abilityRadarOrder]); null
  /// for a radar that only shows.
  final void Function(String ability)? onAxisTap;

  /// Small: each corner reads "STR 8" on one line (see [RadarChart.compact]).
  final bool compact;

  /// Ability key -> value, for every key of [abilityRadarOrder].
  final Map<String, int> values;

  /// The shape to compare with, dashed behind.
  final Map<String, int>? before;

  /// Looks up an l10n key.
  final String Function(String key) t;
  final Color color;
  final String? beforeLabel;
  final String? nowLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = [
      for (final k in abilityRadarOrder) (values[k] ?? 0).toDouble()
    ];
    final was = before == null
        ? null
        : [for (final k in abilityRadarOrder) (before![k] ?? 0).toDouble()];
    final highest = [...now, ...?was].fold(0.0, (m, v) => v > m ? v : m);
    final max = chartScaleFor(highest.ceil(), floor: 6, step: 3);
    final axes = [
      for (final (i, k) in abilityRadarOrder.indexed)
        RadarAxis(
          label: compact
              ? '${t(abilityAbbrevKey(k))} ${now[i].round()}'
              : t(abilityAbbrevKey(k)),
          value: compact ? null : '${now[i].round()}',
          sub: was != null && now[i] != was[i]
              ? '${now[i] > was[i] ? '+' : '-'}${(now[i] - was[i]).abs().round()}'
              : null,
          subColor: was != null && now[i] < was[i] ? radarLess : radarMore,
          onTap: onAxisTap == null ? null : () => onAxisTap!(k),
        ),
    ];
    Widget legend(Color c, String label, {bool dashed = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 0,
              decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: c,
                          width: dashed ? 2 : 3,
                          style:
                              dashed ? BorderStyle.solid : BorderStyle.solid))),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.8))),
          ],
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RadarChart(
          compact: compact,
          size: size,
          max: max,
          axes: axes,
          layers: [
            if (was != null)
              RadarLayer(
                  values: was,
                  color: radarCompare,
                  fill: 0,
                  dashed: true,
                  width: 2),
            RadarLayer(values: now, color: color),
          ],
          semanticsLabel: [
            for (final (i, k) in abilityRadarOrder.indexed)
              '${t('${k}_label')} ${now[i].round()}',
          ].join(', '),
        ),
        if (beforeLabel != null && nowLabel != null) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 18,
            children: [
              legend(radarCompare, beforeLabel!, dashed: true),
              legend(color, nowLabel!),
            ],
          ),
        ],
      ],
    );
  }
}

/// The elements as a card with four views of the same points (v1.224): one
/// radar with damage and resistance as two shapes, two radars, a rose, and
/// plain rows. [t] looks up an l10n key.
class ElementsCard extends StatefulWidget {
  const ElementsCard({super.key, required this.points, required this.t});

  final ElementPoints points;
  final String Function(String key) t;

  @override
  State<ElementsCard> createState() => _ElementsCardState();
}

class _ElementsCardState extends State<ElementsCard> {
  int _view = 0;

  static const Color _damage = Color(0xFFFF8A5C);
  static const Color _resist = Color(0xFF9FC2D6);

  /// An element's name for a chart's corner: the long one (Lightning) as
  /// its short form.
  String _name(String element) => (element == 'Electricity'
          ? widget.t('element_short_electricity')
          : widget.t('element_name_${element.toLowerCase()}'))
      .toUpperCase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = widget.t;
    final p = widget.points;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: p.isEmpty
            ? Text(t('elements_empty'),
                key: const Key('elements_empty'),
                style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    color: scheme.onSurface.withValues(alpha: 0.8)))
            : Column(
                children: [
                  SegmentedButton<int>(
                    key: const Key('elements_views'),
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                          value: 0, label: Text(t('elements_view_radar'))),
                      ButtonSegment(
                          value: 1, label: Text(t('elements_view_split'))),
                      ButtonSegment(
                          value: 2, label: Text(t('elements_view_rose'))),
                      ButtonSegment(
                          value: 3, label: Text(t('elements_view_rows'))),
                    ],
                    selected: {_view},
                    onSelectionChanged: (s) => setState(() => _view = s.first),
                  ),
                  const SizedBox(height: 12),
                  _chart(context),
                ],
              ),
      ),
    );
  }

  Widget _legend(ThemeData theme, ColorScheme scheme) => Wrap(
        spacing: 18,
        children: [
          for (final (c, key) in [
            (_damage, 'elements_damage'),
            (_resist, 'elements_resist'),
          ])
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 18,
                  height: 0,
                  decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c, width: 3)))),
              const SizedBox(width: 6),
              Text(widget.t(key),
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.8))),
            ]),
        ],
      );

  Widget _chart(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = widget.points;
    final max = chartScaleFor(p.highest, floor: 10, step: 5);
    final dmg = p.damageInOrder();
    final res = p.resistInOrder();
    Color colorOf(String e) => Color(paletteForElement(e).primary);
    String semantic() => [
          for (final e in elementChartOrder)
            '${widget.t('element_name_${e.toLowerCase()}')} '
                '${p.damage[e]} ${widget.t('elements_damage')}, '
                '${p.resist[e]} ${widget.t('elements_resist')}',
        ].join('; ');
    switch (_view) {
      case 0:
        return Column(
          key: const Key('elements_view_0'),
          children: [
            RadarChart(
              size: 320,
              max: max,
              rings: 4,
              semanticsLabel: semantic(),
              axes: [
                for (final e in elementChartOrder)
                  RadarAxis(
                      label: _name(e),
                      color: colorOf(e),
                      value: '${p.damage[e]}/${p.resist[e]}'),
              ],
              layers: [
                RadarLayer(
                    values: res,
                    color: _resist,
                    fill: 0.18,
                    dashed: true,
                    width: 2),
                RadarLayer(values: dmg, color: _damage, fill: 0.28),
              ],
            ),
            _legend(theme, scheme),
          ],
        );
      case 1:
        return Column(
          key: const Key('elements_view_1'),
          children: [
            for (final (values, color, key) in [
              (dmg, _damage, 'elements_damage'),
              (res, _resist, 'elements_resist'),
            ]) ...[
              Text(widget.t(key).toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(color: color)),
              RadarChart(
                size: 300,
                max: max,
                rings: 4,
                axes: [
                  for (final (i, e) in elementChartOrder.indexed)
                    RadarAxis(
                        label: _name(e),
                        color: colorOf(e),
                        value: '${values[i].round()}'),
                ],
                layers: [
                  RadarLayer(values: values, color: color, fill: 0.3, width: 2)
                ],
              ),
            ],
          ],
        );
      case 2:
        return Column(
          key: const Key('elements_view_2'),
          children: [
            RoseChart(
              size: 320,
              max: max,
              outer: dmg,
              inner: res,
              innerColor: _resist,
              semanticsLabel: semantic(),
              axes: [
                for (final e in elementChartOrder)
                  RadarAxis(
                      label: _name(e),
                      color: colorOf(e),
                      value: '${p.damage[e]}/${p.resist[e]}'),
              ],
            ),
            _legend(theme, scheme),
          ],
        );
      default:
        return Column(
          key: const Key('elements_view_3'),
          children: [
            for (final e in elementChartOrder)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: colorOf(e))),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 92,
                      child: Text(widget.t('element_name_${e.toLowerCase()}'),
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontSize: 16)),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _bar((p.damage[e] ?? 0) / max, _damage, scheme),
                          const SizedBox(height: 3),
                          _bar((p.resist[e] ?? 0) / max, _resist, scheme),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: Text('${p.damage[e]} / ${p.resist[e]}',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: scheme.onSurface)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            _legend(theme, scheme),
          ],
        );
    }
  }

  Widget _bar(double share, Color color, ColorScheme scheme) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: share.clamp(0.0, 1.0),
          minHeight: 6,
          color: color,
          backgroundColor: scheme.surfaceContainerHighest,
        ),
      );
}
