// The throne room (v1.247): the Lantern Throne on its dais in pixel art, its
// braziers flickering, and every banner the player has earned hanging along
// the walls and swaying. Drawn by tool/gen_throne_room.py (assets/visuals/
// throne/, and the flame strip in pixel_fx/); the banners are the ones of
// pixel_banner.dart. A clan's banner hangs once it is the player's friend
// (the Open Hand's once it is raised), then the Shroud's recovered pieces.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/factions.dart';
import '../data/throne.dart' show throneFactionName;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/player_session_provider.dart';
import 'pixel_banner.dart';
import 'pixel_sprite.dart';

/// One banner hanging in the hall.
class HungBanner {
  const HungBanner({required this.id, required this.name, this.caption = ''});

  /// The banner sprite's id (see pixel_banner.dart).
  final String id;

  /// What it is called.
  final String name;

  /// A line under its name when picked (a clan's standing).
  final String caption;
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

/// Room each banner has: its height and the space between two.
const double _bannerRow = 144;

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
          name: data.faction(id)?.nameFor(lang) ?? id,
          caption: id == 'open_hand'
              ? trFor(lang, 'open_hand_banner_raised')
              : trFor(lang, standingTierKey(politics.tierOf(id, data))),
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

/// The hall itself: the throne's section with up to four banners beside it,
/// then, for the rest, a long carpet with a banner each side of every row.
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

class _ThroneRoomState extends State<ThroneRoom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: const Duration(seconds: 6));
  bool _still = false;

  @override
  void initState() {
    super.initState();
    PixelStrips.preload(const ['throne_flame']);
    for (final b in widget.banners) {
      _BannerImages.of(b.id);
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
      _BannerImages.of(b.id);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  Widget _banner(int index) {
    final banner = widget.banners[index];
    return GestureDetector(
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
                        color: const Color(0xFFF2C14E).withValues(alpha: 0.55),
                        blurRadius: 14),
                  ]
                : null,
          ),
          child: CustomPaint(
            size: const Size(64, 128),
            painter: _SwayPainter(
              id: banner.id,
              clock: _clock,
              phase: index * 1.7,
              still: _still,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tiled(String asset, {ImageRepeat repeat = ImageRepeat.repeat}) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF18121C),
          image: DecorationImage(
            image: AssetImage('assets/visuals/throne/$asset.png'),
            repeat: repeat,
            scale: 0.5,
            filterQuality: FilterQuality.none,
            alignment: Alignment.topCenter,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final n = widget.banners.length;
    final beside = math.min(n, 4);
    final rows = ((n - beside) / 2).ceil();
    final hallHeight = _throneSectionHeight + rows * _bannerRow;
    return SizedBox(
      key: const Key('throne_hall'),
      width: throneSceneWidth,
      height: hallHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // The long hall: a floor with the carpet down its middle.
          if (rows > 0)
            Positioned(
              left: 0,
              right: 0,
              top: _throneSectionHeight,
              bottom: 0,
              child: _tiled('floor_tile'),
            ),
          if (rows > 0)
            Positioned(
              left: (throneSceneWidth - 72) / 2,
              width: 72,
              top: _throneSectionHeight,
              bottom: 0,
              child: _tiled('carpet_tile', repeat: ImageRepeat.repeatY),
            ),
          // The throne's wall, glowing a little with the lantern.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: _throneSectionHeight,
            child: _tiled('wall_tile'),
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
                        center: const Alignment(0, -0.35),
                        radius: 0.75,
                        colors: [
                          const Color(0xFFF2C14E)
                              .withValues(alpha: 0.14 + 0.08 * pulse),
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
          // Up to four banners beside the throne: two a side...
          for (var i = 0; i < beside; i++)
            Positioned(
              left: i.isEven ? 0 : throneSceneWidth - 64,
              top: 24 + (i ~/ 2) * _bannerRow,
              width: 64,
              height: 128,
              child: _banner(i),
            ),
          // ...and the rest down the long hall, a pair to a row.
          for (var i = beside; i < n; i++)
            Positioned(
              left: i.isEven ? 8 : throneSceneWidth - 72,
              top: _throneSectionHeight + ((i - beside) ~/ 2) * _bannerRow + 8,
              width: 64,
              height: 128,
              child: _banner(i),
            ),
        ],
      ),
    );
  }
}

/// A banner's sprite, drawn in strips four pixels high that swing a little
/// further the lower they hang, the pole at the top held still.
class _SwayPainter extends CustomPainter {
  _SwayPainter({
    required this.id,
    required this.clock,
    required this.phase,
    required this.still,
  }) : super(repaint: Listenable.merge([clock, _BannerImages.loaded]));

  final String id;
  final Animation<double> clock;
  final double phase;
  final bool still;

  static const int _strip = 4;
  static const int _pole = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final image = _BannerImages.of(id);
    if (image == null) return;
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    final w = image.width.toDouble();
    final sx = size.width / image.width;
    final sy = size.height / image.height;
    for (var y = 0; y < image.height; y += _strip) {
      final hang = ((y - _pole) / (image.height - _pole)).clamp(0.0, 1.0);
      final swing = still
          ? 0
          : (math.sin(clock.value * 2 * math.pi + phase + y * 0.07) *
                  3.2 *
                  hang *
                  hang)
              .round();
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, y.toDouble(), w, _strip.toDouble()),
        Rect.fromLTWH(swing * sx, y * sy, size.width, _strip * sy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SwayPainter old) =>
      old.id != id || old.phase != phase || old.still != still;
}

/// The banner sprites, loaded once and kept.
class _BannerImages {
  _BannerImages._();

  static final Map<String, ui.Image> _images = {};
  static final Set<String> _asked = {};

  /// Counts the sprites in, for a painter to repaint on.
  static final ValueNotifier<int> loaded = ValueNotifier(0);

  static ui.Image? of(String id) {
    final image = _images[id];
    if (image == null && _asked.add(id)) _load(id);
    return image;
  }

  static Future<void> _load(String id) async {
    try {
      final data = await rootBundle.load('assets/visuals/banners/$id.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _images[id] = frame.image;
      loaded.value++;
    } catch (_) {
      _asked.remove(id);
    }
  }
}
