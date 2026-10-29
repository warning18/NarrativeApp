// The story's forced prices (issue #583): a choice that is the only way on
// after a failed check and names a price (`shortfallWounds`) takes what the
// purse holds; what it cannot pay is taken as a wound, a point of health
// for each gold missing, never the last point. A price the player may turn
// down is a `pays` choice instead, shut to a short purse.

/// The wound [goldMod] (a cost, negative) leaves on a purse of [gold]: the
/// gold missing, as a negative heal; 0 when the purse covers it.
int shortfallWound({required int gold, required int goldMod}) {
  if (goldMod >= 0) return 0;
  final left = gold + goldMod;
  return left < 0 ? left : 0;
}
