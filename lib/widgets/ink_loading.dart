// The app's one waiting state (v1.886): a gold ring around the lantern, on the
// page's own ground, and after a second or two a line saying what is awaited.
// It replaces `Center(child: CircularProgressIndicator())`, written out in 34
// places.
import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/pixel_icons/pixel_icon.dart';

class InkLoading extends StatefulWidget {
  const InkLoading(
      {super.key, this.label, this.slowAfter = const Duration(seconds: 2)});

  /// What is awaited ("Reading the map..."); shown once the wait is long.
  final String? label;
  final Duration slowAfter;

  @override
  State<InkLoading> createState() => _InkLoadingState();
}

class _InkLoadingState extends State<InkLoading> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    if (widget.label != null) {
      _timer = Timer(widget.slowAfter, () {
        if (mounted) setState(() => _slow = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox.expand(
                    child: CircularProgressIndicator(strokeWidth: 3)),
                const PixelIcon('assets/icons/items/material_lantern_brass.png',
                    size: 28),
              ],
            ),
          ),
          if (_slow && widget.label != null) ...[
            const SizedBox(height: 12),
            Text(widget.label!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
