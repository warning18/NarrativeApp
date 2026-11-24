// The skins of the Tower's dice in ink (v1.1005): a black die with a cold grey
// edge, or with a red edge and glow for the one that is in play or lit.
import 'package:flutter/painting.dart';

import '../../../widgets/die_skins.dart';
import 'ink_palette.dart';

const DieSkin inkDieSkin =
    DieSkin('Ink', inkOnPaper, Color(0xFFB7C0C4), DiePattern.none);
const DieSkin inkDieSkinLit =
    DieSkin('Ink', inkOnPaper, inkRed, DiePattern.none, inkRed);
