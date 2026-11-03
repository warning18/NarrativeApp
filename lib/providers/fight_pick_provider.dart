import 'package:flutter_riverpod/legacy.dart';

/// The companions the next fight fields, picked on the pre-fight sheet
/// (UX's, the user's rule, v1.664); null fields the seated ones. The fight
/// builds its party from it (party_pick.dart's fightLineup) and sets it
/// back to null as the fight starts, so a pick is for one fight only.
final fightPickProvider = StateProvider<List<String>?>((ref) => null);
