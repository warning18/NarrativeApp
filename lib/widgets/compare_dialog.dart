import 'package:flutter/material.dart';

/// One stat line in a comparison table: a label plus two numeric values to
/// contrast. [higherIsBetter] controls delta coloring — true colors a
/// bigger B green, false colors a smaller B green, null shows the delta
/// with no coloring (purely informational stats like cost).
class CompareRow {
  const CompareRow({
    required this.label,
    required this.valueA,
    required this.valueB,
    this.higherIsBetter = true,
  });

  final String label;
  final num valueA;
  final num valueB;
  final bool? higherIsBetter;
}

/// Shows a two-column comparison table (e.g. two items or two skills) with
/// a colored delta indicator on the right-hand entry, for every stat in
/// [rows]. Rows where both values are zero are skipped to keep the table
/// focused on stats that actually apply to either entry.
/// Formats [n] without float artifacts (e.g. 1.5 - 1.2 == 0.29999999999999993
/// in double arithmetic) — whole numbers print as ints, others round to 2dp.
String _formatNum(num n) =>
    n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);

Future<void> showCompareDialog(
  BuildContext context, {
  required String titleA,
  required String titleB,
  required List<CompareRow> rows,
  required String closeLabel,
  String? vsLabel,
}) {
  final visibleRows =
      rows.where((r) => r.valueA != 0 || r.valueB != 0).toList();
  return showDialog<void>(
    context: context,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(vsLabel ?? '$titleA vs $titleB'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(flex: 2, child: SizedBox()),
                    Expanded(
                      child: Text(
                        titleA,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        titleB,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                if (visibleRows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '—',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ...visibleRows.map((row) {
                  final delta = row.valueB - row.valueA;
                  Color? deltaColor;
                  if (row.higherIsBetter != null && delta != 0) {
                    final isBetter =
                        row.higherIsBetter! ? delta > 0 : delta < 0;
                    deltaColor = isBetter ? Colors.green : colorScheme.error;
                  }
                  final deltaText = delta == 0
                      ? '='
                      : (delta > 0
                          ? '+${_formatNum(delta)}'
                          : _formatNum(delta));
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(row.label)),
                        Expanded(
                          child: Text(_formatNum(row.valueA),
                              textAlign: TextAlign.center),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(_formatNum(row.valueB),
                                  textAlign: TextAlign.center),
                              Text(
                                deltaText,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: deltaColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(closeLabel),
          ),
        ],
      );
    },
  );
}
