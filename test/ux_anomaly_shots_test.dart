// PICTURES (UX_SHOTS=<folder>): the fight's field anomalies as a full-screen
// atmosphere over the real fight screen, with the omen and active warnings.
// PROTOTYPE painters: the real ones come after the user picks.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/combat/field_anomaly.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/fight_screen.dart'
    show anomalyEffectText, anomalyIcon;
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart' show InkFonts;
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';

import 'support/fonts.dart';

/// The real app on a Tower fight at 412 wide: the app's container.
Future<ProviderContainer> _bootFight(WidgetTester tester, GlobalKey key,
    {int seed = 5,
    int? floor,
    int events = 0,
    double width = 412,
    bool stopAtFloor = false,
    bool stopAtMenu = false,
    Widget? overlay,
    int settleSeconds = 0}) async {
  await tester.runAsync(loadAppFonts);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  final data = towerDataFromAssets();
  var run = towerStart(
      seed: seed,
      raceId: 'human',
      professionId: Platform.environment['SHOT_JOB'] ?? 'warrior',
      data: data);
  if (floor != null) run = run.copyWith(floor: floor, events: events, crest: 0);
  SharedPreferences.setMockInitialValues({
    towerRunPrefsKey: jsonEncode(run.toJson()),
    'tutorial_enabled': false,
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 860);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: Stack(textDirection: TextDirection.ltr, children: [
        const ProviderScope(child: MyApp()),
        if (overlay != null) overlay,
      ])));
  Future<void> settle([int n = 8]) async {
    for (var i = 0; i < n; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tapKey(String k) async {
    final f = find.byKey(Key(k));
    await tester.ensureVisible(f.first);
    await tester.pump();
    await tester.tap(f.first);
    await settle(10);
  }

  await settle(12);
  final c = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(
      () => c.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
  await settle(4);
  await tapKey('menu_tower');
  if (stopAtMenu) {
    await settle(settleSeconds * 10);
    return c;
  }
  await tapKey('tower_continue');
  if (stopAtFloor) return c;
  await tapKey('tower_fight');
  await settle(12);
  final enter = find.text('Enter Battle');
  if (enter.evaluate().isNotEmpty) {
    await tester.ensureVisible(enter);
    await tester.pump();
    await tester.tap(enter);
    await settle(14);
  }
  return c;
}

double _h(int i, int salt) {
  final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

/// The prototype atmosphere of an anomaly family over the whole fight body.
/// [level]: 0.3 on the omen, 1 while active. Translucent, never a wall: the
/// dice, the face row, the buttons and the bars stay readable under it.
class _Atmosphere extends CustomPainter {
  _Atmosphere(this.family, this.level);
  final AnomalyFamily family;
  final double level;

  void _veil(Canvas c, Size s, Color color, double a) =>
      c.drawRect(Offset.zero & s, Paint()..color = color.withValues(alpha: a));

  void _vignette(Canvas c, Size s, Color color, double a, {double from = .45}) {
    final r = Rect.fromLTWH(0, 0, s.width, s.height);
    c.drawRect(
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 0.1),
            radius: 1.0,
            colors: [color.withValues(alpha: 0), color.withValues(alpha: a)],
            stops: [from, 1],
          ).createShader(r));
  }

  void _edge(Canvas c, Size s, Color color, double a, double depth) {
    for (final e in [
      (
        Alignment.topCenter,
        Alignment.bottomCenter,
        Rect.fromLTWH(0, 0, s.width, depth)
      ),
      (
        Alignment.bottomCenter,
        Alignment.topCenter,
        Rect.fromLTWH(0, s.height - depth, s.width, depth)
      ),
      (
        Alignment.centerLeft,
        Alignment.centerRight,
        Rect.fromLTWH(0, 0, depth, s.height)
      ),
      (
        Alignment.centerRight,
        Alignment.centerLeft,
        Rect.fromLTWH(s.width - depth, 0, depth, s.height)
      ),
    ]) {
      c.drawRect(
          e.$3,
          Paint()
            ..shader = LinearGradient(
              begin: e.$1,
              end: e.$2,
              colors: [color.withValues(alpha: a), color.withValues(alpha: 0)],
            ).createShader(e.$3));
    }
  }

  @override
  void paint(Canvas canvas, Size s) {
    switch (family) {
      case AnomalyFamily.light:
        // The eclipse: the room dims to violet-black; a corona hangs at the top.
        _veil(canvas, s, const Color(0xFF0A0614), 0.28 * level);
        _vignette(canvas, s, const Color(0xFF140A2A), 0.42 * level, from: .6);
        final at = Offset(s.width * 0.5, -4);
        final r = Rect.fromCircle(center: at, radius: 120);
        canvas.drawCircle(
            at,
            120,
            Paint()
              ..shader = RadialGradient(colors: [
                const Color(0xFF05060F).withValues(alpha: 0),
                const Color(0xFFBFB6FF).withValues(alpha: 0.55 * level),
                const Color(0xFFBFB6FF).withValues(alpha: 0),
              ], stops: const [
                0.4,
                0.52,
                1
              ]).createShader(r));
        canvas.drawCircle(
            at,
            52,
            Paint()
              ..color =
                  const Color(0xFF05060F).withValues(alpha: 0.95 * level));
      case AnomalyFamily.storm:
        _veil(canvas, s, const Color(0xFF0B1220), 0.24 * level);
        _vignette(canvas, s, const Color(0xFF05080F), 0.4 * level, from: .55);
        final rain = Paint()
          ..color = const Color(0xFFCFE0F0).withValues(alpha: 0.32 * level)
          ..strokeWidth = 1.2;
        for (var i = 0; i < 120 * level; i++) {
          final x = _h(i, 1) * s.width;
          final y = _h(i, 2) * s.height;
          final len = 14 + 16 * _h(i, 3);
          canvas.drawLine(Offset(x, y), Offset(x - len * 0.28, y + len), rain);
        }
        // A flash: a pale wash and a bolt down the right side.
        _veil(canvas, s, const Color(0xFFEAF2FF), 0.07 * level);
        final bolt = Path()
          ..moveTo(s.width * 0.86, 0)
          ..lineTo(s.width * 0.80, s.height * 0.10)
          ..lineTo(s.width * 0.85, s.height * 0.14)
          ..lineTo(s.width * 0.76, s.height * 0.30);
        canvas.drawPath(
            bolt,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..color = const Color(0xFFBFD4FF).withValues(alpha: 0.28 * level)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawPath(
            bolt,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.white.withValues(alpha: 0.9 * level));
      case AnomalyFamily.cold:
        _veil(canvas, s, const Color(0xFF9CC8E8), 0.08 * level);
        _edge(canvas, s, const Color(0xFFE4F4FF), 0.5 * level, 46);
        final ice = Paint()
          ..color = Colors.white.withValues(alpha: 0.75 * level)
          ..strokeWidth = 1.4;
        for (var i = 0; i < 46; i++) {
          // Crystals growing in from the edges.
          final side = i % 4;
          final u = _h(i, 5);
          final len = 8 + 22 * _h(i, 6);
          final p = switch (side) {
            0 => Offset(u * s.width, 0),
            1 => Offset(u * s.width, s.height),
            2 => Offset(0, u * s.height),
            _ => Offset(s.width, u * s.height),
          };
          final d = switch (side) {
            0 => const Offset(0, 1),
            1 => const Offset(0, -1),
            2 => const Offset(1, 0),
            _ => const Offset(-1, 0),
          };
          final tilt = (_h(i, 7) - 0.5) * 0.9;
          final dir = Offset(d.dx + tilt * d.dy, d.dy - tilt * d.dx);
          canvas.drawLine(p, p + dir * len, ice);
          canvas.drawLine(p + dir * len * 0.55,
              p + dir * len * 0.55 + Offset(-dir.dy, dir.dx) * 6, ice);
        }
      case AnomalyFamily.heat:
        _veil(canvas, s, const Color(0xFF3A0E05), 0.12 * level);
        final haze =
            Rect.fromLTWH(0, s.height * 0.35, s.width, s.height * 0.65);
        canvas.drawRect(
            haze,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFFFF7A2A).withValues(alpha: 0.3 * level),
                  const Color(0xFFFF7A2A).withValues(alpha: 0),
                ],
              ).createShader(haze));
        final shimmer = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFFFFD9A0).withValues(alpha: 0.12 * level);
        for (var k = 0; k < 16; k++) {
          final y = s.height * (0.42 + k * 0.034);
          final p = Path()..moveTo(0, y);
          for (var x = 0.0; x <= s.width; x += 8) {
            p.lineTo(x, y + math.sin(x * 0.06 + k) * 2.6);
          }
          canvas.drawPath(p, shimmer);
        }
        for (var i = 0; i < 36 * level; i++) {
          final x = _h(i, 8) * s.width;
          final y = s.height * (0.3 + 0.7 * _h(i, 9));
          canvas.drawRect(Rect.fromLTWH(x, y, 2, 2),
              Paint()..color = const Color(0xFFFFB04A).withValues(alpha: 0.85));
        }
      case AnomalyFamily.water:
        _veil(canvas, s, const Color(0xFF0C3A4A), 0.2 * level);
        _vignette(canvas, s, const Color(0xFF04202C), 0.4 * level);
        final band = Paint()
          ..color = Colors.white.withValues(alpha: 0.06 * level);
        for (var k = 0; k < 4; k++) {
          final x = s.width * (0.1 + 0.25 * k);
          final p = Path()
            ..moveTo(x, 0)
            ..lineTo(x + 46, 0)
            ..lineTo(x - 70, s.height)
            ..lineTo(x - 116, s.height)
            ..close();
          canvas.drawPath(p, band);
        }
        final ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFFBFE8F2).withValues(alpha: 0.4 * level);
        for (var i = 0; i < 26; i++) {
          final at =
              Offset(_h(i, 10) * s.width, s.height * (0.3 + 0.6 * _h(i, 11)));
          final r = 3 + 11 * _h(i, 12);
          canvas.drawOval(
              Rect.fromCenter(center: at, width: r * 2.4, height: r * 0.9),
              ring);
        }
        // A rising line of water at the foot, under the buttons' row.
        final wave = Path()..moveTo(0, s.height);
        for (var x = 0.0; x <= s.width; x += 6) {
          wave.lineTo(x, s.height * 0.8 + math.sin(x * 0.05) * 3);
        }
        wave
          ..lineTo(s.width, s.height)
          ..close();
        canvas.drawPath(
            wave,
            Paint()
              ..color =
                  const Color(0xFF2C7F96).withValues(alpha: 0.13 * level));
      case AnomalyFamily.ground:
        _veil(canvas, s, const Color(0xFF1A130C), 0.16 * level);
        _vignette(canvas, s, const Color(0xFF0B0805), 0.45 * level, from: .5);
        final dust =
            Rect.fromLTWH(0, s.height * 0.45, s.width, s.height * 0.55);
        canvas.drawRect(
            dust,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFFB89A6A).withValues(alpha: 0.32 * level),
                  const Color(0xFFB89A6A).withValues(alpha: 0),
                ],
              ).createShader(dust));
        // Cracks run up the two sides, never across the dice.
        for (final (seed, x0) in [
          (3, 0.05),
          (9, 0.95),
          (14, 0.2),
          (21, 0.82)
        ]) {
          var x = s.width * x0;
          var y = s.height;
          final p = Path()..moveTo(x, y);
          for (var k = 0; k < 6; k++) {
            x += (_h(seed + k, 2) - 0.5) * 36 + (x0 < 0.5 ? -4 : 4);
            y -= 34 + 26 * _h(seed + k, 3);
            p.lineTo(x.clamp(2.0, s.width - 2), y);
          }
          canvas.drawPath(
              p,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 6
                ..color =
                    const Color(0xFFE08A3C).withValues(alpha: 0.28 * level)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
          canvas.drawPath(
              p,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.8
                ..color =
                    const Color(0xFFFFB46B).withValues(alpha: 0.85 * level));
        }
        for (var i = 0; i < 40 * level; i++) {
          canvas.drawRect(
              Rect.fromLTWH(_h(i, 13) * s.width,
                  s.height * (0.35 + 0.6 * _h(i, 14)), 2, 2),
              Paint()..color = const Color(0xFFD8C39A).withValues(alpha: 0.7));
        }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// The warning toast: on the omen "the light turns strange: Eclipse is
/// coming", then on the break "Eclipse!" with its effect; gone after ~2 s.
Widget _banner(FieldAnomalyPlan plan, bool omen) {
  const lang = AppLanguage.en;
  final name = trFor(lang, 'anomaly_${plan.anomaly.id}');
  final title = omen
      ? trFor(lang, 'anomaly_omen_${plan.anomaly.family.name}')
          .replaceAll('{name}', name)
      : '$name!';
  final line = omen
      ? trFor(lang, 'anomaly_soon')
      : anomalyEffectText(plan, lang).join(' · ');
  TextStyle p(double sz, Color c) => TextStyle(
      fontFamily: InkFonts.prose, fontSize: sz, height: 1.25, color: c);
  return Positioned(
    left: 12,
    right: 12,
    top: 64,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: inkBlack.withValues(alpha: 0.92),
              border: Border.all(color: omen ? inkGold : inkRed, width: 2),
              borderRadius: BorderRadius.circular(6)),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  border: Border.all(color: inkPaper, width: 1.5),
                  borderRadius: BorderRadius.circular(4)),
              child: Icon(anomalyIcon(plan.anomaly.family),
                  size: 24, color: inkPaper),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontFamily: InkFonts.display,
                            fontSize: omen ? 13 : 17,
                            height: 1.1,
                            color: inkPaper)),
                    Text(line, style: p(11.5, inkGrey)),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: omen ? inkGold : inkRed,
              child: Text(omen ? '!' : '3',
                  style: TextStyle(
                      fontFamily: InkFonts.display,
                      fontSize: 14,
                      color: omen ? inkBlack : inkPaper)),
            ),
          ]),
        ),
      ),
    ),
  );
}

FieldAnomalyPlan _plan(String id) => FieldAnomalyPlan(
    anomaly: fieldAnomalies.firstWhere((a) => a.id == id),
    side: AnomalySide.both,
    onset: 2,
    rounds: 3);

Widget _overlay(String id, {bool omen = false, bool banner = true}) {
  final plan = _plan(id);
  return Positioned.fill(
    top: 56,
    child: IgnorePointer(
      child: ClipRect(
          child: Stack(textDirection: TextDirection.ltr, children: [
        Positioned.fill(
            child: CustomPaint(
                painter: _Atmosphere(plan.anomaly.family, omen ? 0.3 : 1))),
        if (banner) _banner(plan, omen),
      ])),
    ),
  );
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });
  for (final (name, id, omen) in [
    ('base', '', false),
    ('eclipse-omen', 'eclipse', true),
    ('eclipse', 'eclipse', false),
    ('thunderstorm', 'thunderstorm', false),
    ('whiteout', 'whiteout', false),
    ('blaze', 'blaze', false),
    ('flash_flood', 'flash_flood', false),
    ('earth_break', 'earth_break', false),
  ]) {
    testWidgets('anomaly $name', skip: shots == null, (tester) async {
      final key = GlobalKey();
      await _bootFight(tester, key,
          floor: 3,
          seed: 5,
          overlay: id.isEmpty ? null : _overlay(id, omen: omen));
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/anomaly-$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
