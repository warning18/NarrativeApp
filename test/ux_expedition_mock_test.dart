// A mock of the proposed expedition page (UX, for the user to approve before
// anything is built): the zone's title and intro, a step rail (as the
// backstory's age timeline), one scene card, two choice cards with effect
// chips, a retreat link. Built from the existing widgets (AbilityPill, the
// app theme) and the real zone data; the scene and the choices are sample
// text. UX_SHOTS=<folder> takes docs/ux-shots/expedition-page-mock.png.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/ability_visuals.dart';

Future<void> _loadFonts() async {
  const families = {
    'PixelifySans': [
      'assets/fonts/PixelifySans-Regular.ttf',
      'assets/fonts/PixelifySans-SemiBold.ttf',
    ],
    'Spectral': [
      'assets/fonts/Spectral-Regular.ttf',
      'assets/fonts/Spectral-Medium.ttf',
      'assets/fonts/Spectral-Italic.ttf',
    ],
    'IMFellEnglishSC': ['assets/fonts/IMFellEnglishSC-Regular.ttf'],
  };
  for (final family in families.entries) {
    final loader = FontLoader(family.key);
    for (final path in family.value) {
      loader.addFont(Future.value(ByteData.view(
          Uint8List.fromList(File(path).readAsBytesSync()).buffer)));
    }
    await loader.load();
  }
  // The icons, so the picture shows them (the tests' own font is blocks).
  final icons = File(
      '/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(
          ByteData.view(Uint8List.fromList(icons.readAsBytesSync()).buffer)));
    await loader.load();
  }
}

/// The backstory's age timeline, with a label under each dot and the boss
/// (a crown) last.
class _StepRail extends StatelessWidget {
  const _StepRail({required this.labels, required this.current});

  final List<String> labels;
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final last = labels.length - 1;
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                color: i <= current
                    ? colors.primary.withValues(alpha: 0.5)
                    : colors.outlineVariant,
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: i == current ? 22 : 16,
                height: i == current ? 22 : 16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < current ? colors.primary : colors.surface,
                  border: Border.all(
                    color: i <= current ? colors.primary : colors.outline,
                    width: i == current ? 3 : 1.5,
                  ),
                ),
                child: i == last
                    ? Icon(Icons.workspace_premium,
                        size: 11,
                        color: i < current ? colors.surface : colors.primary)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                style: theme.textTheme.labelMedium?.copyWith(
                  color: i == current
                      ? colors.primary
                      : colors.onSurface.withValues(alpha: 0.75),
                  fontWeight: i == current ? FontWeight.w700 : null,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A choice as a card: its words, then what it does as chips.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.label, required this.chips});

  final String label;
  final List<(IconData, String, Color)> chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontSize: 17, height: 1.4)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (final (icon, text, color) in chips)
                AbilityPill(icon: icon, label: text, color: color),
            ]),
          ],
        ),
      ),
    );
  }
}

Widget _page(Map<String, dynamic> zone) {
  return Builder(builder: (context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(zone['zoneName'] as String)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              zone['flavorText'] as String,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            const _StepRail(labels: ['1', '2', '3', '4', 'Boss'], current: 2),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: Text('STAGE 3 · THE LOWER LANDING',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    )),
              ),
              Text('3 / 5',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: colors.onSurfaceVariant)),
            ]),
            const SizedBox(height: 6),
            Text('A candle that should not be lit',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Text(
                'The water has taken the next turn of the stair to the knee, '
                'and on the landing above it a single candle burns in a '
                'saucer, dry and steady. Someone lit it within the hour. '
                'Behind it, a door hangs open on a room of wet ledgers.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontSize: 18, height: 1.6, letterSpacing: 0.1),
              ),
            ),
            const SizedBox(height: 18),
            const _ChoiceCard(
              label: 'Wade up to the landing and search the room.',
              chips: [
                (Icons.balance, 'Dexterity DC 12', Color(0xFF8FB0E0)),
                (Icons.paid_outlined, '+40 gold', Color(0xFFE0B64F)),
                (Icons.favorite_border, 'Fail: −6 health', Color(0xFFE07A6B)),
              ],
            ),
            const SizedBox(height: 10),
            const _ChoiceCard(
              label:
                  'Snuff the candle and wait in the dark for whoever lit it.',
              chips: [
                (
                  Icons.casino_outlined,
                  'A fight: the Ledger-keeper’s clerk',
                  Color(0xFFE07A6B)
                ),
                (Icons.shield_outlined, '+2 alignment', Color(0xFF9BC59A)),
              ],
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.directions_walk, size: 18),
                label: const Text('Retreat'),
              ),
            ),
          ],
        ),
      ),
    );
  });
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('a picture of the proposed expedition page (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    final zones =
        jsonDecode(File('assets/gamedata/zones.json').readAsStringSync())
            as Map<String, dynamic>;
    final zone = zones['z_drowned_stair'] as Map<String, dynamic>;
    tester.view.physicalSize = const Size(780, 1860);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      home: RepaintBoundary(key: key, child: _page(zone)),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/expedition-page-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}
