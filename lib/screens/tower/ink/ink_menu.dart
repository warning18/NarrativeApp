// The home menu's items in ink (v1.1009, UX-2): the one that goes on is a red
// skewed block, the others a paper panel in Art's wide frame. Both carry a
// mark, the label in brush lettering and an optional line under it. The key
// sits on the part that takes the tap (a FilledButton, an InkWell), so the
// screens and their tests read it as before; a null [onPressed] is a dimmed
// item that takes no tap.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/stitched_ink.dart';
import 'ink_images.dart';
import 'ink_kit.dart';
import 'ink_palette.dart';

class InkMenuItem extends StatefulWidget {
  const InkMenuItem({
    super.key,
    required this.itemKey,
    required this.icon,
    required this.label,
    this.detail,
    this.onPressed,
    this.primary = false,
  });

  final Key itemKey;
  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  State<InkMenuItem> createState() => _InkMenuItemState();
}

class _InkMenuItemState extends State<InkMenuItem> {
  @override
  void initState() {
    super.initState();
    unawaited(InkImages.preload());
  }

  Widget _lines(Color title, Color sub) => Row(children: [
        Icon(widget.icon, color: title),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label,
                  style: TextStyle(
                      fontFamily: InkFonts.display,
                      fontSize: 18,
                      height: 1.1,
                      color: title)),
              if (widget.detail case final d? when d.isNotEmpty)
                Text(d,
                    style: TextStyle(
                        fontFamily: InkFonts.system, fontSize: 10, color: sub)),
            ],
          ),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    if (widget.primary) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Transform(
          transform: Matrix4.skewX(-inkSkew),
          child: FilledButton(
            key: widget.itemKey,
            onPressed: widget.onPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 58),
              padding: const EdgeInsets.symmetric(horizontal: 26),
              backgroundColor: inkRed,
              disabledBackgroundColor: inkDark,
              foregroundColor: inkPaper,
              shape: const RoundedRectangleBorder(),
            ),
            child: Transform(
                transform: Matrix4.skewX(inkSkew),
                child: _lines(inkPaper, inkPaper.withValues(alpha: 0.85))),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: InkPaperPanel(
          padding: const EdgeInsets.fromLTRB(40, 12, 18, 12),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: widget.itemKey,
              onTap: widget.onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _lines(inkOnPaper, inkSlate),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
