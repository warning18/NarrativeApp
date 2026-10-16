// The throne room (v1.247, restaged v1.248): the Lantern Throne on its dais
// in pixel art, centred on a dark stage with its braziers flickering, and
// every banner the player has earned on a tall standard beside it, blowing in
// the wind. Drawn by tool/gen_throne_room.py (assets/visuals/
// throne/, and the flame strip in pixel_fx/); the banners are the ones of
// pixel_banner.dart. A clan's banner hangs once it is the player's friend
// (the Open Hand's once it is raised), then the Shroud's recovered pieces.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clan_power.dart' show hasPower, powerOf, powerTierFor;
import '../data/factions.dart';
import '../data/throne.dart' show throneFactionName;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/player_session_provider.dart';
import 'clan_peek.dart';
import 'clan_power_block.dart' show powerTierKey;
import 'pixel_banner.dart';
import 'pixel_sprite.dart';
import 'wind_banner.dart';

/// One banner hanging in the hall.
class HungBanner {
  const HungBanner({
    required this.id,
    required this.name,
    this.caption = '',
    this.factionId,
  });

  /// The banner sprite's id (see pixel_banner.dart).
  final String id;

  /// What it is called.
  final String name;

  /// A line under its name when picked (a clan's standing).
  final String caption;

  /// The clan whose banner it is, for its details on a long press (none for
  /// a piece of the Shroud).
  final String? factionId;
}

/// The clan banners the player has earned: those of the clans that are at
/// least [StandingTier.friend] to them, and the Open Hand's once it is
/// raised -- in the order of [clanBannerFactionIds].
List<String> earnedClanBannerFactionIds({
  required ClanData data,
  required PoliticsState politics,
  required Iterable<String> flags,
}) =>
    [
      for (final id in clanBannerFactionIds)
        if (id == 'open_hand'
            ? bannerRaisedIn(flags)
            : data.faction(id) != null &&
                politics.tierOf(id, data).isAtLeast(StandingTier.friend))
          id,
    ];

/// The scene's width in logical pixels: a throne at x2, a column of
/// banners each side of it.
const double throneSceneWidth = 384;

/// Height of the throne's own part of the hall.
const double _throneSectionHeight = 312;

class ThroneRoomTab extends ConsumerStatefulWidget {
  const ThroneRoomTab({super.key});

  @override
  ConsumerState<ThroneRoomTab> createState() => _ThroneRoomTabState();
}

class _ThroneRoomTabState extends ConsumerState<ThroneRoomTab> {
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(clanDataProvider);
    final politics = ref.watch(politicsProvider);
    final session = ref.watch(playerSessionProvider);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final flags = session.flags;
    final holder = session.politics.throneWinner;
    final claim = session.politics.claim;

    final hung = <HungBanner>[
      for (final id in earnedClanBannerFactionIds(
          data: data, politics: politics, flags: flags))
        HungBanner(
          id: clanBannerId(id)!,
          factionId: data.faction(id) == null ? null : id,
          name: data.faction(id)?.nameFor(lang) ?? id,
          caption: id == 'open_hand'
              ? trFor(lang, 'open_hand_banner_raised')
              : [
                  trFor(lang, standingTierKey(politics.tierOf(id, data))),
                  // Its strength (Wave 12), and the red of a nemesis.
                  if (hasPower(id, data))
                    trFor(
                        lang,
                        powerTierKey(
                            powerTierFor(powerOf(politics, id, data)))),
                  if (politics.nemesis == id) trFor(lang, 'clan_nemesis_tag'),
                ].join(' · '),
        ),
      for (final id in shroudPieceIds)
        if (session.bannerPiecesCollected.contains(id))
          HungBanner(
              id: id,
              name: trFor(lang, 'banner_piece_$id'),
              caption: trFor(lang, 'banner_pieces_title')),
    ];
    HungBanner? picked;
    for (final b in hung) {
      if (b.id == _picked) picked = b;
    }

    final line = holder.isNotEmpty
        ? trFor(lang, 'throne_room_held')
            .replaceAll('{name}', throneFactionName(holder, data, lang))
        : claim.isNotEmpty
            ? trFor(lang, 'throne_your_claim')
                .replaceAll('{name}', throneFactionName(claim, data, lang))
            : trFor(lang, 'throne_room_empty');

    return ListView(
      key: const Key('throne_room'),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(trFor(lang, 'throne_room_title'),
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(line,
                  key: const Key('throne_room_line'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(
                  hung.isEmpty
                      ? trFor(lang, 'throne_room_none')
                      : '${hung.length} ${trFor(lang, 'throne_room_count')}',
                  key: const Key('throne_room_count'),
                  style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  picked == null
                      ? trFor(lang, 'throne_room_hint')
                      : '${picked.name} · ${picked.caption}',
                  key: ValueKey(picked?.id ?? 'hint'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: picked == null
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ThroneRoom(
              banners: hung,
              pickedId: _picked,
              onPick: (b) =>
                  setState(() => _picked = _picked == b.id ? null : b.id),
            ),
          ),
        ),
      ],
    );
  }
}

/// The hall itself: a dark stage with the throne in the middle, a standard
/// on each side of it (a banner on a tall gilt pole, blowing in the wind),
/// then, for the rest, a long carpet with a standard each side of every row.
class ThroneRoom extends StatefulWidget {
  const ThroneRoom({
    super.key,
    required this.banners,
    this.pickedId,
    this.onPick,
  });

  final List<HungBanner> banners;
  final String? pickedId;
  final ValueChanged<HungBanner>? onPick;

  @override
  State<ThroneRoom> createState() => _ThroneRoomState();
}

/// A standard's own size: room for the cloth to blow, the banner, a pole
/// below it and a foot.
const double _standardWidth = 88;
const double _standardTop = 14;
const double _standardFoot = 8;

/// The pole under the banner, by the throne and in the rows down the hall.
const double _poleByThrone = 128;
const double _poleInRows = 64;

/// How much a row of the long hall takes.
const double _hallRow = _standardTop + 128 + _poleInRows + _standardFoot + 8;

class _ThroneRoomState extends State<ThroneRoom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: _windPeriod);
  bool _still = false;

  /// One wind cycle: everything that moves loops seamlessly over it.
  static const Duration _windPeriod = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    PixelStrips.preload(const ['throne_flame']);
    for (final b in widget.banners) {
      BannerImages.of(b.id);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_still) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void didUpdateWidget(ThroneRoom old) {
    super.didUpdateWidget(old);
    for (final b in widget.banners) {
      BannerImages.of(b.id);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  /// Banner [index] on its standard, [pole] pixels of pole under the cloth.
  Widget _standard(int index, double pole) {
    final banner = widget.banners[index];
    final height = _standardTop + 128 + pole + _standardFoot;
    return SizedBox(
      width: _standardWidth,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The pole, from the rod to the floor, behind the cloth.
          Positioned(
            left: (_standardWidth - 6) / 2,
            width: 6,
            top: _standardTop + 4,
            bottom: 6,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/visuals/throne/pole_tile.png'),
                  repeat: ImageRepeat.repeatY,
                  filterQuality: FilterQuality.none,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: (_standardWidth - 30) / 2,
            bottom: 0,
            width: 30,
            height: 12,
            child: Image.asset('assets/visuals/throne/standard_foot.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
                isAntiAlias: false),
          ),
          Positioned(
            left: (_standardWidth - 12) / 2,
            top: 0,
            width: 12,
            height: 16,
            child: Image.asset('assets/visuals/throne/finial.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
                isAntiAlias: false),
          ),
          Positioned(
            left: 0,
            top: _standardTop,
            width: _standardWidth,
            height: 128,
            child: ClanPeek(
              factionId: banner.factionId,
              child: GestureDetector(
                key: Key('throne_banner_${banner.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onPick?.call(banner),
                child: Semantics(
                  label: '${banner.name}, ${banner.caption}',
                  button: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: widget.pickedId == banner.id
                          ? [
                              BoxShadow(
                                  color: const Color(0xFFF2C14E)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 16),
                            ]
                          : null,
                    ),
                    child: CustomPaint(
                      size: const Size(_standardWidth, 128),
                      painter: WindPainter(
                        id: banner.id,
                        clock: _clock,
                        phase: index * 1.7,
                        still: _still,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.banners.length;
    final beside = math.min(n, 2);
    final rows = ((n - beside) / 2).ceil();
    final hallHeight = _throneSectionHeight + rows * _hallRow;
    const poleHeightByThrone =
        _standardTop + 128 + _poleByThrone + _standardFoot;
    // The standards by the throne stand on the dais's floor line.
    const byThroneTop = 300 - poleHeightByThrone;
    return SizedBox(
      key: const Key('throne_hall'),
      width: throneSceneWidth,
      height: hallHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // A dark stage, lit from above and by a pool of light on the floor.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF12141B), Color(0xFF07080B)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: _throneSectionHeight,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _clock,
                builder: (context, _) {
                  final pulse =
                      0.5 + 0.5 * math.sin(_clock.value * 2 * math.pi);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.2),
                        radius: 0.85,
                        colors: [
                          Color.lerp(const Color(0xFF7A84A6),
                                  const Color(0xFFA6624A), pulse)!
                              .withValues(alpha: 0.30),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            top: 236,
            height: 150,
            child: IgnorePointer(
              child: Transform.scale(
                scaleY: 0.4,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0x66B0483C), Color(0x00B0483C)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // The carpet down the middle of the long hall.
          if (rows > 0)
            Positioned(
              left: (throneSceneWidth - 72) / 2,
              width: 72,
              top: _throneSectionHeight,
              bottom: 0,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/visuals/throne/carpet_tile.png'),
                    repeat: ImageRepeat.repeatY,
                    scale: 0.5,
                    filterQuality: FilterQuality.none,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 64,
            top: 24,
            width: 256,
            height: 288,
            child: Image.asset(
              'assets/visuals/throne/throne.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
              isAntiAlias: false,
            ),
          ),
          for (final (i, x) in [(0, 80.0), (1, 256.0)]) ...[
            Positioned(
              left: x,
              top: 212,
              width: 48,
              height: 80,
              child: Image.asset(
                'assets/visuals/throne/brazier.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
              ),
            ),
            Positioned(
              left: x,
              top: 180,
              width: 48,
              height: 48,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _clock,
                  builder: (context, _) => CustomPaint(
                    painter: PixelStripPainter(
                      names: const ['throne_flame'],
                      progress: _still ? 0 : (_clock.value * 4 + i * 0.37) % 1,
                      scale: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
          // A standard each side of the throne...
          for (var i = 0; i < beside; i++)
            Positioned(
              left: i.isEven ? 0 : throneSceneWidth - _standardWidth,
              top: byThroneTop,
              child: _standard(i, _poleByThrone),
            ),
          // ...and the rest down the long hall, a pair to a row.
          for (var i = beside; i < n; i++)
            Positioned(
              left: i.isEven ? 0 : throneSceneWidth - _standardWidth,
              top: _throneSectionHeight + ((i - beside) ~/ 2) * _hallRow + 8,
              child: _standard(i, _poleInRows),
            ),
          // Wind-blown specks drifting across it all.
          if (!_still)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _BreezePainter(_clock)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Specks of dust and light blown across the hall, left to right.
class _BreezePainter extends CustomPainter {
  _BreezePainter(this.clock) : super(repaint: clock);

  final Animation<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final u = clock.value;
    final paint = Paint()
      ..isAntiAlias = false
      ..strokeWidth = 1;
    for (var i = 0; i < 18; i++) {
      // Each speck's own row, speed (a whole number of crossings a cycle)
      // and length, spread out by a fixed hash of its number.
      final h = (i * 0.6180339887) % 1.0;
      final y = 20 + (i * 37 % 29) / 29 * (size.height - 40);
      final crossings = 1 + i % 3;
      final x = ((h + u * crossings) % 1.0) * (size.width + 40) - 20;
      final len = 5.0 + (i % 4) * 3;
      final wobble = math.sin(2 * math.pi * (u * 3 + h)) * 2;
      paint.color = Colors.white.withValues(alpha: 0.10 + 0.02 * (i % 4));
      canvas.drawLine(
          Offset(x, y + wobble), Offset(x + len, y + wobble * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_BreezePainter old) => false;
}
