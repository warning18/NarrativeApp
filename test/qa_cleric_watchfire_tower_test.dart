// QA guard, the user's report "For the cleric when using Mending Light the
// watchfire countdown doesn't accumulate": the Tower's fight, under its detached session.
// The story's fight is held by Core's qa_mending_light_watchfire_test.dart.
// The play and the checks are in support/qa_cleric_watchfire.dart.
import 'package:flutter_test/flutter_test.dart';

import 'support/qa_cleric_watchfire.dart';

void main() {
  testWidgets(
      'Tower fight (detached session): each Mending Light builds the Watchfire',
      (tester) => playClericCasts(tester, detached: true));
}
