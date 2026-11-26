// The Tower's ink palette (v1.1004, UX-2): near-black, cold greys and paper
// white; deep red only for what matters (health, your turn, the aimed foe, a
// x3, the lit die, the one button that goes on). The five greys are the
// ones of docs/art/palette-apollo.md's ink set.
import 'package:flutter/material.dart';

/// The page: near-black.
const Color inkBlack = Color(0xFF05060A);

/// The ink of the sprites and plates (the darkest of the five greys).
const Color inkDeep = Color(0xFF090A14);

/// Cold greys, dark to light.
const Color inkDark = Color(0xFF202E37);
const Color inkSlate = Color(0xFF394A50);
const Color inkGrey = Color(0xFF9AA3A7);

/// Paper white.
const Color inkPaper = Color(0xFFEFEDE8);

/// The one accent.
const Color inkRed = Color(0xFFC1121A);

/// The ink text of a paper panel.
const Color inkOnPaper = Color(0xFF0B0C14);

/// The deep red of dried ink, a wax seal, the foot of a blood bar.
const Color inkRedDeep = Color(0xFF8E141A);

/// The dust and the sand of the weather on a piece.
const Color inkSand = Color(0xFFB9A27A);

/// The card styles of the Tower's tables (v2.10.26, the user's pick): the
/// gold edge and band of a rank-up and of a purse, the violet stock of a spell
/// and the iron stock of gear. Gift cards use the clan's own hue; a bundle
/// uses [inkSand].
const Color inkGold = Color(0xFFC9A24B);
const Color inkViolet = Color(0xFF1B1533);
const Color inkIron = Color(0xFF454E53);
