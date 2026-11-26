// Swipe a card up to choose it (v2.10.22, the user: "tap and validate as now,
// or swipe the card to the top to choose it"). It wraps any card of a
// Tower offer: a drag upward follows the finger; past about a third of the
// card's height, or on a fling, the card flies up and off and [onChosen] runs
// (the same as Take); under it, the card springs back. A tap still reaches the
// card inside. Reduce motion: no fly-off, a quick fade. Swipe is an extra: tap
// and Take always work.
import 'package:flutter/material.dart';

/// How far, as a share of the card's height, a drag must go to choose it.
const double towerSwipeShare = 0.3;

/// A fling at least this fast (logical pixels a second, upward) chooses it.
const double towerSwipeFling = 700;

class TowerSwipeToChoose extends StatefulWidget {
  const TowerSwipeToChoose({
    super.key,
    required this.child,
    required this.onChosen,
    this.onLift,
    this.enabled = true,
  });

  final Widget child;

  /// The card is chosen (the same as Take on it).
  final VoidCallback onChosen;

  /// The card starts to lift: it comes to the front (the offer selects it).
  final VoidCallback? onLift;
  final bool enabled;

  @override
  State<TowerSwipeToChoose> createState() => _TowerSwipeToChooseState();
}

class _TowerSwipeToChooseState extends State<TowerSwipeToChoose>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    // The reduce-motion fade must still run its own time.
    animationBehavior: AnimationBehavior.preserve,
  );

  /// How far up the card is now (a positive number of pixels).
  double _up = 0;
  double _from = 0;
  double _to = 0;
  bool _flying = false;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      if (!mounted) return;
      setState(() {
        final t = Curves.easeOut.transform(_anim.value);
        _up = _from + (_to - _from) * (_flying ? _anim.value : t);
      });
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  double get _height => context.size?.height ?? 300;

  void _start(DragStartDetails d) {
    if (!widget.enabled || _flying) return;
    _anim.stop();
    widget.onLift?.call();
  }

  void _update(DragUpdateDetails d) {
    if (!widget.enabled || _flying) return;
    setState(() => _up = (_up - d.delta.dy).clamp(0.0, _height * 1.5));
  }

  Future<void> _end(DragEndDetails d) async {
    if (!widget.enabled || _flying) return;
    final fling = -(d.primaryVelocity ?? 0) >= towerSwipeFling;
    if (_up >= _height * towerSwipeShare || (fling && _up > 8)) {
      await _choose();
    } else {
      _from = _up;
      _to = 0;
      _flying = false;
      _anim.duration = const Duration(milliseconds: 220);
      await _anim.forward(from: 0);
    }
  }

  Future<void> _choose() async {
    final reduced = MediaQuery.of(context).disableAnimations;
    setState(() => _flying = true);
    _from = _up;
    _to = reduced ? _up : _height * 1.3;
    _anim.duration = Duration(milliseconds: reduced ? 140 : 280);
    await _anim.forward(from: 0);
    if (mounted) widget.onChosen();
  }

  @override
  Widget build(BuildContext context) {
    final fade = _flying ? 1 - Curves.easeIn.transform(_anim.value) : 1.0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: widget.enabled ? _start : null,
      onVerticalDragUpdate: widget.enabled ? _update : null,
      onVerticalDragEnd: widget.enabled ? _end : null,
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -_up),
          child: widget.child,
        ),
      ),
    );
  }
}
