// The Tower's button on the main menu, in ink (v1.1004, UX-2): a paper panel
// in Art's wide frame with the brush lettering, a tower mark and a red bar at
// its left. Only this button is restyled; the story's keep today's look.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/stitched_ink.dart';
import 'ink_images.dart';
import 'ink_kit.dart';
import 'ink_palette.dart';

class TowerMenuButton extends StatefulWidget {
  const TowerMenuButton({
    super.key,
    required this.buttonKey,
    required this.label,
    required this.detail,
    required this.onPressed,
  });

  /// The key of the tappable part (the menu's `menu_tower`).
  final Key buttonKey;
  final String label;
  final String detail;
  final VoidCallback onPressed;

  @override
  State<TowerMenuButton> createState() => _TowerMenuButtonState();
}

class _TowerMenuButtonState extends State<TowerMenuButton> {
  @override
  void initState() {
    super.initState();
    unawaited(InkImages.preload());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkPaperPanel(
        padding: const EdgeInsets.fromLTRB(36, 12, 18, 12),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(width: 4, height: 34, color: inkRed),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: widget.buttonKey,
                onTap: widget.onPressed,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.fort_outlined, color: inkOnPaper),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.label,
                              style: const TextStyle(
                                fontFamily: InkFonts.display,
                                fontSize: 18,
                                height: 1.1,
                                color: inkOnPaper,
                              ),
                            ),
                            if (widget.detail.isNotEmpty)
                              Text(
                                widget.detail,
                                style: const TextStyle(
                                  fontFamily: InkFonts.system,
                                  fontSize: 10,
                                  color: inkSlate,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
