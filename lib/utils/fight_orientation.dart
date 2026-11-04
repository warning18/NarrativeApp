// The fight stays upright on a phone (v1.764): the dice board needs the height
// of a portrait screen, and on a phone turned sideways (640 x 360) it was
// left 1 px tall. Only the fight is held: the rest of the app turns as before,
// and a tablet (shortest side of 600 dp or more) is never held.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The shortest side, in dp, from which a screen is a tablet.
const double tabletShortestSide = 600;

/// How many fights hold the screen upright right now (two can overlap for a
/// moment while one route replaces another).
int _holders = 0;

/// Whether the fight on a screen of [size] is held upright: a phone is.
bool holdsFightUpright(Size size) => size.shortestSide < tabletShortestSide;

/// Holds the screen upright for a fight on a phone; returns whether it did, so
/// the caller can [releaseFightUpright] on the way out. Call it once.
bool holdFightUpright(BuildContext context) {
  if (!holdsFightUpright(MediaQuery.sizeOf(context))) return false;
  if (_holders++ == 0) {
    SystemChrome.setPreferredOrientations(
        const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }
  return true;
}

/// Lets the screen turn again once the last fight that held it has left (an
/// empty list is the platform's own default, as before the fight).
void releaseFightUpright() {
  if (_holders == 0) return;
  if (--_holders == 0) {
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[]);
  }
}
