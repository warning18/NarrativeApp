// The Journey state's moves between the map's views: the town and the
// district, the world, in and out of a building, the way and pin sheets.
// Cut out of journey_screen.dart with no change (setState is called as
// _update).
part of '../journey_screen.dart';

/// The moves between the map's views. Cut out of journey_screen.dart
/// with no change (setState is called as _update).
extension _JourneyViews on _JourneyViewState {
  CityChartText _cityText() => CityChartText(
        wholeCity: tr(ref, 'city_whole'),
        unexplored: tr(ref, 'city_unexplored'),
        go: tr(ref, 'city_go'),
        walk: tr(ref, 'city_walk'),
        here: tr(ref, 'city_here'),
        zoomIn: tr(ref, 'city_zoom_in'),
        zoomOut: tr(ref, 'city_zoom_out'),
        waysOne: tr(ref, 'city_ways_one'),
        waysMany: tr(ref, 'city_ways_many'),
        kinds: {
          CityWayKind.quest: tr(ref, 'city_kind_quest'),
          CityWayKind.fight: tr(ref, 'city_kind_fight'),
          CityWayKind.check: tr(ref, 'city_kind_check'),
          CityWayKind.shop: tr(ref, 'city_kind_shop'),
          CityWayKind.road: tr(ref, 'city_kind_road'),
        },
      );

  /// The town in view or the district (the chart frames it again).
  void _setTown(bool town, {bool resetFocus = false}) {
    _update(() {
      _townView = town;
      _cityFocusToken++;
      if (resetFocus) _cityFocus = null;
    });
  }

  /// A way's sheet (board 15): what it is and Go; the pin and the row open
  /// the same.
  void _openWay(int i, List<_Step> steps, bool french) {
    _update(() => _selected = i);
    showInkSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepDetail(
                step: steps[i],
                busy: _busy,
                french: french,
                isExcursion: false,
                onGo: steps[i].locked
                    ? null
                    : () {
                        Navigator.of(sheet).pop();
                        _take(i, steps[i]);
                      },
              ),
              TextButton(
                key: const ValueKey('journey_city_not_now'),
                onPressed: () => Navigator.of(sheet).pop(),
                child: Text(tr(ref, 'journey_city_not_now')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A pin with several ways (v1.607): its sheet is named by the place and
  /// lists the ways; a tap on one opens it like a pin with that way alone.
  void _openPin(List<int> ways, String name, List<_Step> steps, bool french) {
    showInkSheet<void>(
      context: context,
      builder: (sheet) {
        final theme = Theme.of(sheet);
        final ink = InkColors.of(sheet);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(name,
                    key: const ValueKey('journey_pin_sheet_title'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontFamily: InkFonts.display)),
                const SizedBox(height: 6),
                for (final i in ways)
                  InkWell(
                    key: ValueKey('journey_pin_way_$i'),
                    onTap: () {
                      Navigator.of(sheet).pop();
                      _openWay(i, steps, french);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: ink.seam))),
                      child: Row(children: [
                        Expanded(
                          child: Text(steps[i].label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: steps[i].locked ? ink.ash : null,
                                  height: 1.2)),
                        ),
                        Icon(Icons.chevron_right,
                            size: IconSize.s16, color: ink.ash),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _dropTownShot() {
    _townShot?.dispose();
    _townShot = null;
  }

  /// Leaves the streets for the world: [apply] puts the ball up at once (it
  /// opens close on the place and pulls back out), and a picture of the
  /// town's map shrinks and fades over it (not with reduced motion, nor
  /// where the place has no town map).
  void _leaveForWorld(VoidCallback apply) {
    ui.Image? shot;
    if (_cityMapUp &&
        _level == JourneyMapLevel.place &&
        !MediaQuery.of(context).disableAnimations) {
      final box = _placeShotKey.currentContext?.findRenderObject();
      if (box is RenderRepaintBoundary && !box.debugNeedsPaint) {
        // Only the plan shrinks, not the list under it.
        RenderBox? plan;
        void find(Element e) {
          if (plan != null) return;
          if (e.widget.key == const ValueKey('city_chart_plan')) {
            final r = e.renderObject;
            if (r is RenderBox && r.hasSize) plan = r;
            return;
          }
          e.visitChildElements(find);
        }

        _placeShotKey.currentContext!.visitChildElements(find);
        final found = plan;
        if (found != null) {
          _townShotAt =
              found.localToGlobal(Offset.zero, ancestor: box) & found.size;
          shot = box.toImageSync(
              pixelRatio: MediaQuery.devicePixelRatioOf(context));
        }
      }
    }
    _dropTownShot();
    _update(() {
      apply();
      _townShot = shot;
    });
    if (shot == null) return;
    _arrive.reverse(from: 1).whenComplete(() {
      // Unless the streets were come back to meanwhile (they own the
      // clock again and have let the picture go).
      if (!mounted || !identical(_townShot, shot)) return;
      _update(_dropTownShot);
      _arrive.value = 1;
    });
  }

  /// Out of the building, onto its streets (they grow in).
  void _stepOut({bool town = false}) {
    _update(() {
      _outside = true;
      _wantTown = town;
      _townView = false;
      _pinch = 1;
      _pinching = false;
    });
    _arrive.forward(from: 0);
  }

  /// The doorway between a room and the streets: the map clears from a
  /// veil and [text] is told over it (after this build, as it is asked
  /// for while the map is built).
  void _passDoor({required bool entering, required String text}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // A road the party is carried along keeps its words.
      if (_transit?.flight ?? false) return;
      _update(() {
        _doorIcon = entering ? Icons.login : Icons.logout;
        _transitSerial++;
        _transit = _Transit.words(text, icon: _doorIcon);
      });
      _door.forward(from: 0);
    });
  }

  /// The other places known, each with its "Go".
  void _showTravelOn(String fromNodeId) {
    showInkSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr(ref, 'travel_on_title'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              TravelOnList(fromNodeId: fromNodeId),
            ],
          ),
        ),
      ),
    );
  }

  Set<String> _shopsFor(StoryData story) {
    if (_shopPlaces != null && identical(_shopPlacesOf, story)) {
      return _shopPlaces!;
    }
    _shopPlacesOf = story;
    return _shopPlaces = shopPlacesOf(story);
  }

  Map<String, String> _kindsFor(StoryData story) {
    if (_placeKinds != null && identical(_placeKindsOf, story)) {
      return _placeKinds!;
    }
    _placeKindsOf = story;
    return _placeKinds = placeKindsOf(story);
  }
}
