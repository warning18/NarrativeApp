// The aim bar, plank bar, bracket, charge ring and flash, the French line
// tidy-up and the small icon and colour helpers. Cut out of
// ship_battle_panel.dart with no change.
part of '../ship_battle_panel.dart';

/// The aim bar: red edges where the shot goes wide, amber for a plain
/// shot, green in the middle for a critical, and the sweeping marker.
class _AimBarPainter extends CustomPainter {
  const _AimBarPainter({
    required this.position,
    required this.marker,
    required this.wide,
    required this.steady,
    required this.perfect,
  });

  final double position;
  final Color marker;
  final Color wide;
  final Color steady;
  final Color perfect;

  @override
  void paint(Canvas canvas, Size size) {
    final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.25, size.width, size.height * 0.5),
        const Radius.circular(2));
    canvas.save();
    canvas.clipRRect(bar);
    void band(double from, double to, Color color) => canvas.drawRect(
        Rect.fromLTRB(from * size.width, 0, to * size.width, size.height),
        Paint()..color = color);
    band(0, 1, wide.withValues(alpha: 0.55));
    band(0.5 - aimSteadyHalfWidth, 0.5 + aimSteadyHalfWidth,
        steady.withValues(alpha: 0.75));
    band(0.5 - aimPerfectHalfWidth, 0.5 + aimPerfectHalfWidth,
        perfect.withValues(alpha: 0.9));
    canvas.restore();
    final x = position.clamp(0.0, 1.0) * size.width;
    canvas.drawRect(
        Rect.fromLTWH(x - 2, 0, 4, size.height), Paint()..color = marker);
  }

  @override
  bool shouldRepaint(_AimBarPainter old) =>
      old.position != position ||
      old.marker != marker ||
      old.wide != wide ||
      old.steady != steady ||
      old.perfect != perfect;
}

/// A hull bar made of ten planks, filled from the left.
class _PlankBarPainter extends CustomPainter {
  const _PlankBarPainter(
      {required this.ratio, required this.color, required this.empty});

  final double ratio;
  final Color color;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    const planks = 10;
    const gap = 2.0;
    final plank = (size.width - gap * (planks - 1)) / planks;
    final filled = ratio * planks;
    for (var i = 0; i < planks; i++) {
      final left = i * (plank + gap);
      final rect = Rect.fromLTWH(left, 0, plank, size.height);
      canvas.drawRect(rect, Paint()..color = empty);
      final part = (filled - i).clamp(0.0, 1.0);
      if (part > 0) {
        canvas.drawRect(Rect.fromLTWH(left, 0, plank * part, size.height),
            Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PlankBarPainter old) =>
      old.ratio != ratio || old.color != color || old.empty != empty;
}

/// The range between the ships: a line from one to the other with a
/// tick at each end.
class _BracketPainter extends CustomPainter {
  const _BracketPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    final x = size.width / 2;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.3), paint);
    canvas.drawLine(
        Offset(x, size.height * 0.7), Offset(x, size.height), paint);
    canvas.drawLine(Offset(x - 5, 0), Offset(x + 5, 0), paint);
    canvas.drawLine(
        Offset(x - 5, size.height), Offset(x + 5, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _BracketPainter old) => old.color != color;
}

/// A weapon's charge as a ring around its icon.
class _ChargeRing extends StatelessWidget {
  const _ChargeRing({
    required this.value,
    required this.color,
    required this.track,
    required this.size,
    required this.child,
  });

  final double value;
  final Color color;
  final Color track;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: size / 8,
              color: color,
              backgroundColor: track,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// What a shot just did, rising off the room it hit and fading.
class _Flash extends StatelessWidget {
  const _Flash(
      {super.key, required this.text, required this.color, this.size = 15});

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1400),
        builder: (context, t, child) => Opacity(
          opacity: (1 - t * t * t).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -14 * t),
            // Pops in large, settles, then rises and fades.
            child: Transform.scale(
                scale: t < 0.15 ? 1.6 - 4 * t : 1.0, child: child),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: InkFonts.system,
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: color,
            shadows: const [
              Shadow(blurRadius: 4, color: Colors.black),
              Shadow(blurRadius: 1, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}

// Built once: the log is tidied on every refresh, and the clock refreshes
// every second.
final RegExp _deElidedArticle = RegExp(r"\bde L['’]");
final RegExp _deBeforeVowel = RegExp(r'\bde ([AEIOUÉÈÊ])');
final RegExp _articleMidSentence = RegExp('([a-zà-ÿ]) (Le|La|Les) ');

/// A log line with a ship's name dropped in, made to read right: a name
/// that carries its own article ("The Rusty Eel", "Le Rusty Eel") after
/// the line's article, and the French contractions (du, au, d’).
String tidyShipLine(String text, AppLanguage lang) {
  if (lang == AppLanguage.fr) {
    return text
        .replaceAll(' de Le ', ' du ')
        .replaceAll(' de Les ', ' des ')
        .replaceAll(' à Le ', ' au ')
        .replaceAll(' à Les ', ' aux ')
        .replaceAll(' de La ', ' de la ')
        .replaceAllMapped(_deElidedArticle, (_) => 'de l’')
        .replaceAllMapped(_deBeforeVowel, (m) => 'd’${m.group(1)}')
        // "sous Le Rusty Eel": the name's article, mid-sentence.
        .replaceAllMapped(_articleMidSentence,
            (m) => '${m.group(1)} ${m.group(2)!.toLowerCase()} ');
  }
  return text
      .replaceAll('the The ', 'the ')
      .replaceAll('The The ', 'The ')
      // "bear the marks of The Pale Leviathan": the name's article,
      // mid-sentence.
      .replaceAllMapped(_theMidSentence, (m) => '${m.group(1)} the ');
}

final RegExp _theMidSentence = RegExp("([a-z,;:]) The ");

/// The color of damage that is coming but not dealt yet, the same blue
/// the dice fight uses for its preview.
const Color _previewColor = Color(0xFF42A5F5);

/// Boarders met by a hand in the hold come over the rail at this share
/// of their health.
const double _holdMannedBoarderHealth = 0.75;

/// Below this share of her hull the dock tells the player to run for it:
/// a run started lower often fails, the enemy closing as she turns.
const double _runWarningShare = 0.3;

/// A room's own colour, from the Stitched Ink palette; darker on a light
/// page so it still reads.
Color _roomColor(BuildContext context, ShipRoom room) {
  final ink = InkColors.of(context);
  final light = Theme.of(context).brightness == Brightness.light;
  return switch (room) {
    ShipRoom.helm => ink.tide,
    ShipRoom.guns => ink.ember,
    ShipRoom.bulwark =>
      light ? const Color(0xFF4F6275) : const Color(0xFF9FB0C2),
    ShipRoom.hold => light ? const Color(0xFF7A5534) : const Color(0xFFB08A64),
  };
}

IconData _weaponIcon(ShipWeapon weapon) => weapon.incendiary
    ? Icons.local_fire_department
    : weapon.piercing
        ? Icons.bolt
        : Icons.gps_fixed;

IconData _weatherIcon(SeaWeather weather) => switch (weather) {
      SeaWeather.calm => Icons.wb_sunny_outlined,
      SeaWeather.tailwind => Icons.air,
      SeaWeather.crosswind => Icons.cyclone,
      SeaWeather.squall => Icons.thunderstorm_outlined,
      SeaWeather.fog => Icons.foggy,
    };

Color _weatherColor(InkColors ink, SeaWeather weather) => switch (weather) {
      SeaWeather.calm => ink.gold,
      SeaWeather.tailwind => ink.tide,
      SeaWeather.crosswind => ink.voidColor,
      SeaWeather.squall => ink.ash,
      SeaWeather.fog => ink.ash,
    };

IconData _ammoIcon(ShipAmmo ammo) => switch (ammo) {
      ShipAmmo.round => Icons.circle,
      ShipAmmo.chain => Icons.link,
      ShipAmmo.grape => Icons.grain,
      ShipAmmo.heated => Icons.local_fire_department_outlined,
    };

/// A room's mark in the push sheet: what the room does.
IconData _roomIcon(ShipRoom room) => switch (room) {
      ShipRoom.helm => Icons.explore_outlined,
      ShipRoom.guns => Icons.gps_fixed,
      ShipRoom.bulwark => Icons.shield_outlined,
      ShipRoom.hold => Icons.handyman_outlined,
    };

/// An intent's mark (see ShipIntent): the enemy stands above the Eel on
/// the sea, so closing in points down at her and pulling away up.
IconData _intentIcon(ShipIntent intent) => switch (intent) {
      ShipIntent.volley => Icons.gps_fixed,
      ShipIntent.closeIn => Icons.south,
      ShipIntent.pullAway => Icons.north,
      ShipIntent.ram => Icons.keyboard_double_arrow_down,
      ShipIntent.board => Icons.sports_kabaddi,
      ShipIntent.mend => Icons.build,
      ShipIntent.brace => Icons.shield,
      ShipIntent.flee => Icons.sailing,
      ShipIntent.dive => Icons.water,
    };

/// Red for what will hurt, the tide's blue for an opening, gold for a
/// move to answer with the helm.
Color _intentColor(InkColors ink, ShipIntent intent) => switch (intent) {
      ShipIntent.volley => ink.ember,
      ShipIntent.ram || ShipIntent.board || ShipIntent.dive => ink.blood,
      ShipIntent.mend || ShipIntent.brace => ink.tide,
      ShipIntent.closeIn || ShipIntent.pullAway || ShipIntent.flee => ink.gold,
    };

IconData _habitIcon(EnemyHabit habit) => switch (habit) {
      EnemyHabit.none => Icons.sailing,
      EnemyHabit.flee => Icons.directions_run,
      EnemyHabit.marksman => Icons.my_location,
      EnemyHabit.ram => Icons.double_arrow,
      EnemyHabit.boarder => Icons.sports_kabaddi,
    };

IconData _orderIcon(CrewOrder order) => switch (order) {
      CrewOrder.allHands => Icons.handyman,
      CrewOrder.brace => Icons.shield_moon_outlined,
      CrewOrder.grapple => Icons.anchor,
      CrewOrder.bless => Icons.volunteer_activism,
      CrewOrder.shoreUp => Icons.add_moderator,
      CrewOrder.markHelm => Icons.gps_not_fixed,
      CrewOrder.cutRigging => Icons.content_cut,
      CrewOrder.eagleEye => Icons.visibility,
      CrewOrder.voidWard => Icons.blur_on,
    };

/// How a dice fight on a deck ended (see _ShipBattlePanelState._deckFight).
enum _DeckFight { won, lost, fled }
