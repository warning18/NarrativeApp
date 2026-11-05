// QA guard, the user's report "For the cleric when using Mending Light the
// watchfire countdown doesn't accumulate": the story's fight.
// The play and the checks are in support/qa_cleric_watchfire.dart.
import 'package:flutter_test/flutter_test.dart';

import 'support/qa_cleric_watchfire.dart';

void main() {
  testWidgets('story fight: each Mending Light builds the Watchfire',
      (tester) => playClericCasts(tester, detached: false));
}
