// The figure the player's hero stands as (fight_sprites.dart's table by people
// and calling), read from the session where a widget is drawn. A widget with
// no provider scope above it, or a hero not made yet, gets the ronin.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_session_provider.dart';
import 'fight_sprites.dart';

FightSpriteSet heroSpriteOf(BuildContext context) {
  try {
    final session = ProviderScope.containerOf(context, listen: false)
        .read(playerSessionProvider);
    return heroSpriteFor(session.raceId, session.professionId);
  } catch (_) {
    return roninSprite;
  }
}
