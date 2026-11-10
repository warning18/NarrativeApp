// The app's one waiting state (v1.892): a gold ring around the brass lantern,
// centred on the page's own ground, and, only after a wait of two seconds, a
// quiet line saying what is awaited. It replaces the bare
// `Center(child: CircularProgressIndicator())` written out all over
// lib/screens (guard: test/ink_loading_test.dart).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../theme/motion.dart';
import '../utils/pixel_icons/pixel_icon.dart';

class InkLoading extends ConsumerStatefulWidget {
  /// [wordKey] is the string key of what is awaited ("Reading the map..."),
  /// shown once the wait is long; the default is a general line.
  const InkLoading({
    super.key,
    this.wordKey = 'loading_wait',
    this.slowAfter = const Duration(seconds: 2),
    this.centered = true,
  });

  final String wordKey;
  final Duration slowAfter;

  /// False inside a box that already centres it (a dialog, a card).
  final bool centered;

  @override
  ConsumerState<InkLoading> createState() => _InkLoadingState();
}

class _InkLoadingState extends ConsumerState<InkLoading> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(child: CircularProgressIndicator(strokeWidth: 3)),
              PixelIcon('assets/icons/items/material_lantern_brass.png',
                  size: 28),
            ],
          ),
        ),
        // Its room is kept from the start, so nothing jumps when it fades in.
        const SizedBox(height: 12),
        AnimatedOpacity(
          duration: Motion.slow,
          opacity: _slow ? 1 : 0,
          child: Text(tr(ref, widget.wordKey),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ],
    );
    return widget.centered ? Center(child: body) : body;
  }
}
