import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/town_rulers.dart';
import 'city_provider.dart';
import 'clans_provider.dart';
import 'geography_provider.dart';

/// Who rules each town and each district of a town now, in what colours
/// (town_rulers.dart's townRulers): place id -> TownRuler. It follows the
/// politics, so a place changing hands at a chapter's turn re-tints it.
/// The cove camp (a town by its city plan only) joins once city_plans.json
/// has loaded.
final townRulersProvider = Provider<Map<String, TownRuler>>((ref) => townRulers(
      ref.watch(geographyProvider),
      ref.watch(politicsProvider),
      ref.watch(factionsProvider),
      planIds: ref.watch(cityPlanRecordsProvider).value?.keys ?? const [],
    ));

/// Who rules [placeId] (a town or a district of one) now; null for a place
/// that is neither.
TownRuler? rulerOfTown(WidgetRef ref, String placeId) =>
    ref.watch(townRulersProvider.select((rulers) => rulers[placeId]));
