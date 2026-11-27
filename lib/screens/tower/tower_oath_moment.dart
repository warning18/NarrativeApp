// The oath as its own Yes/No moment after the loot (the user chose version B
// of docs/ux-shots/round-grill/): the clan's colour washes the floor, its
// banner hangs large, "Swear to the {clan}?", what you gain (its die, the
// standing) and Swear / Not now. Never a card. The floor's rail stays at the
// left, drawn by the floor screen around this view.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_hero.dart' show TowerData;
import '../../data/tower/tower_rewards.dart';
import '../../data/tower/tower_run.dart';
import '../../data/tower/tower_tables.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_strings.dart';
import '../../providers/clans_provider.dart';
import '../../theme/stitched_ink.dart';
import '../../widgets/die_tile.dart';
import '../../widgets/pixel_banner.dart';
import 'ink/ink_palette.dart';
import 'tower_offer_view.dart' show towerDieName;

TextStyle _p(double s, Color c, {FontWeight? w}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: s,
    height: 1.25,
    color: c,
    fontWeight: w);
TextStyle _d(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.display, fontSize: s, height: 1.1, color: c);

class TowerOathMoment extends ConsumerStatefulWidget {
  const TowerOathMoment({
    super.key,
    required this.run,
    required this.data,
    required this.onPick,
  });

  final TowerRun run;
  final TowerData data;

  /// The index in [TowerRun.offer] of the oath sworn, or null for Not now
  /// (every oath left is declined: +1 Ash Mark).
  final void Function(int? index) onPick;

  @override
  ConsumerState<TowerOathMoment> createState() => _State();
}

class _State extends ConsumerState<TowerOathMoment> {
  /// Which clan due is on show (more than one: one after the other).
  int _at = 0;
  bool _done = false;

  List<int> get _oaths => [
        for (var i = 0; i < widget.run.offer.length; i++)
          if (widget.run.offer[i].kind == TowerRewardKind.clanOath) i,
      ];

  void _swear(int i) {
    if (_done) return;
    setState(() => _done = true);
    widget.onPick(i);
  }

  void _notNow() {
    if (_done) return;
    if (_at + 1 < _oaths.length) {
      setState(() => _at++);
      return;
    }
    setState(() => _done = true);
    widget.onPick(null);
  }

  @override
  Widget build(BuildContext context) {
    final oaths = _oaths;
    if (oaths.isEmpty) return const SizedBox.shrink();
    final i = oaths[_at.clamp(0, oaths.length - 1)];
    final id = widget.run.offer[i].id;
    final lang = ref.watch(appLanguageProvider);
    final f = ref.watch(factionsProvider)[id];
    final clan = f?.shortFor(lang) ?? id;
    final colour = f == null ? inkRed : Color(f.color | 0xFF000000);
    final dieId = towerClanDieOf(id, widget.data.dice);
    final faces = dieId == null
        ? 0
        : ((widget.data.dice[dieId] as Map)['numberOfFaces'] as int? ?? 0);
    final now = towerStandingOf(widget.run, widget.data)[id] ?? 0;
    final banner = clanBannerId(id);
    return Stack(key: Key('tower_oath_moment_$id'), children: [
      Positioned.fill(
          child: DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
            colour.withValues(alpha: 0.55),
            inkBlack.withValues(alpha: 0.88)
          ])))),
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
        child: Column(children: [
          if (banner != null)
            SizedBox(
                width: 112,
                height: 224,
                child: FittedBox(
                    fit: BoxFit.fill,
                    child: PixelBanner(id: banner, scale: 1))),
          const SizedBox(height: 10),
          Text(clan,
              textAlign: TextAlign.center,
              style: _p(12, inkGrey, w: FontWeight.w700)),
          Text(tr(ref, 'tower_oath_ask').replaceAll('{clan}', clan),
              key: Key('tower_oath_title_$id'),
              textAlign: TextAlign.center,
              style: _d(26, inkPaper)),
          const SizedBox(height: 8),
          Text(tr(ref, 'tower_oath_line_$id'),
              textAlign: TextAlign.center, style: _p(13, inkPaper)),
          const SizedBox(height: 14),
          Row(children: [
            if (dieId != null)
              Expanded(
                child: _Box(
                  child: Row(children: [
                    DieTile(dieId: dieId, faces: faces, size: 44),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr(ref, 'tower_oath_their_die'),
                                style: _p(10, inkGrey)),
                            Text(towerDieName(ref, dieId),
                                style: _d(14, inkPaper)),
                          ]),
                    ),
                  ]),
                ),
              ),
            if (dieId != null) const SizedBox(width: 8),
            Expanded(
              child: _Box(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr(ref, 'tower_oath_standing'),
                          style: _p(10, inkGrey)),
                      Text('$now/$towerOathStep', style: _d(14, inkPaper)),
                      const SizedBox(height: 4),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        for (var s = 0; s < towerOathStep; s++)
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                                color: s < now ? inkPaper : Colors.transparent,
                                border: Border.all(
                                    color: s < now ? inkPaper : inkGrey),
                                borderRadius: BorderRadius.circular(2)),
                          ),
                      ]),
                    ]),
              ),
            ),
          ]),
          const Spacer(),
          FilledButton(
              key: Key('tower_oath_swear_$id'),
              style: FilledButton.styleFrom(
                  backgroundColor: inkRed,
                  foregroundColor: inkPaper,
                  minimumSize: const Size.fromHeight(48)),
              onPressed: () => _swear(i),
              child: Text(tr(ref, 'tower_swear'))),
          TextButton(
              key: const Key('tower_oath_not_now'),
              onPressed: _notNow,
              child: Text(tr(ref, 'tower_not_now'),
                  style: _p(14, inkGold, w: FontWeight.w700))),
        ]),
      ),
    ]);
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            border: Border.all(color: inkSlate),
            borderRadius: BorderRadius.circular(8)),
        child: child,
      );
}
