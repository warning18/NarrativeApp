import 'package:flutter/material.dart';

import 'port_screen.dart';

/// The small harbor town the player arrives at in Chapter 2 -- the
/// Smugglers' Wharf, ports.json's `port_smugglers_wharf`: a couple of
/// already-stocked basic shops (nothing to build) and the chapter's
/// expedition zones. Deliberately separate from `CampScreen` (the one
/// persistent base the player builds and keeps); from chapter 3 on it is
/// also one more port the Rusty Eel can sail to, which is why it is now
/// just a [PortScreen] under its familiar name.
class TownHubScreen extends StatelessWidget {
  const TownHubScreen({super.key});

  static const String portId = 'port_smugglers_wharf';

  @override
  Widget build(BuildContext context) =>
      const PortScreen(portId: portId, titleKey: 'town_hub_title');
}
