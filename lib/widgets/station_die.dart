// A hand's die at their station on the ship (v1.218, see
// combat/station_dice.dart): a small cube that tumbles when the turn opens
// or the hand moves to another room, and lands on the face its room can
// use; its other sides carry the room's other faces. A room the die has no
// face for shows a pale blank cube.
import 'package:flutter/material.dart';

import '../combat/station_dice.dart';
import '../utils/face_style.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'die_3d.dart';
import 'die_skins.dart';

class StationDie extends StatefulWidget {
  const StationDie({
    super.key,
    required this.die,
    required this.roll,
    required this.turn,
    required this.accent,
    this.skin,
    this.size = 24,
    this.still = false,
  });

  final CrewDie die;
  final StationRoll roll;

  /// The battle's turn: a new one tumbles the die again.
  final int turn;
  final Color accent;
  final DieSkin? skin;
  final double size;
  final bool still;

  @override
  State<StationDie> createState() => _StationDieState();
}

class _StationDieState extends State<StationDie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _roll = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _rolling = false);
      }
    });
  bool _rolling = false;

  @override
  void initState() {
    super.initState();
    if (!widget.still) _tumble();
  }

  void _tumble() {
    _rolling = true;
    _roll.forward(from: 0);
  }

  @override
  void didUpdateWidget(StationDie old) {
    super.didUpdateWidget(old);
    if (!widget.still &&
        (old.turn != widget.turn || old.roll.room != widget.roll.room)) {
      _tumble();
    }
  }

  @override
  void dispose() {
    _roll.dispose();
    super.dispose();
  }

  DieCubeFace _side(StationFace? face) {
    final s = widget.size;
    if (face == null) {
      return DieCubeFace(
          glyph: Icon(FaceKind.empty.icon, size: s * 0.5, color: Colors.grey),
          color: Colors.grey);
    }
    final kind = face.kind;
    final skill = face.face.type == 'Skill';
    return DieCubeFace(
      color: kind.color,
      glyph: skill
          ? SkillPixelIcon(
              face.face.linkedSkillID.isEmpty
                  ? 'heavy_attack'
                  : face.face.linkedSkillID,
              size: s * 0.7)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(kind.icon, size: s * 0.38, color: kind.color),
                if (face.value > 0)
                  Text('${face.value}',
                      style: TextStyle(
                          fontSize: s * 0.26,
                          fontWeight: FontWeight.bold,
                          height: 1,
                          color: kind.color)),
              ],
            ),
    );
  }

  /// The landed face in front, the room's others round it.
  List<DieCubeFace> _sides() {
    final landed = widget.roll.face;
    final pool = widget.die.forRoom(widget.roll.room);
    if (landed == null || pool.isEmpty) {
      return List.filled(6, _side(null));
    }
    final start = pool.indexOf(landed);
    return [
      for (var i = 0; i < 6; i++) _side(pool[(start + i) % pool.length]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final landed = widget.roll.face;
    return Die3D(
      key: ValueKey('station_die_${widget.roll.crewId}'),
      faces: _sides(),
      accent: widget.accent,
      size: widget.size,
      roll: _roll,
      rolling: _rolling,
      fx: landed == null ? null : dieFxOf(landed.kind),
      big: landed != null && landed.face.type == 'Skill',
      dim: landed == null,
      still: widget.still,
      skin: widget.skin,
      keywords: landed?.face.keywords ?? const {},
      element: landed?.face.element ?? 'None',
    );
  }
}
