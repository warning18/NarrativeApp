import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while an ExpeditionScreen is on top of the navigation stack —
/// mirrors [combatActiveProvider]'s own set/cleared-around-the-push
/// pattern. Used to gate Camp's Rest action (see camp_screen.dart): a
/// zone push already covers the bottom nav in practice, so this is mostly
/// a defensive belt-and-suspenders check, not the only thing standing
/// between the player and a free mid-expedition heal.
final expeditionActiveProvider = StateProvider<bool>((ref) => false);
