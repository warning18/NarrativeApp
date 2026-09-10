import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index into [HomeShell]'s bottom navigation tabs (Story, Play, Map,
/// Generate, Data). Lets other screens — like a quest/shop call-to-action
/// banner in the story reader — programmatically switch tabs.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);
