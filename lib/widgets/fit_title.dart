// An app-bar title that shrinks to fit its line instead of ending in "…"
// (#1139): at 320 dp and 1.3x text "La Tour de Cendre" was cut to "La Tour de C…".
import 'package:flutter/material.dart';

class FitTitle extends StatelessWidget {
  const FitTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(text, maxLines: 1),
      );
}
