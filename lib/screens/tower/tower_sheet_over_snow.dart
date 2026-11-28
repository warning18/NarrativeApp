import 'package:flutter/material.dart';

/// A sheet over the floor in the route's overlay, above the snow (which is
/// drawn over everything under the weather scope): the drifts never lie on
/// it. The floor sits dimmed under it; the sheet follows the floor's area.
class TowerSheetOverSnow extends StatefulWidget {
  const TowerSheetOverSnow(
      {super.key, required this.under, required this.sheet});

  final Widget under;
  final Widget sheet;

  @override
  State<TowerSheetOverSnow> createState() => _TowerSheetOverSnowState();
}

class _TowerSheetOverSnowState extends State<TowerSheetOverSnow> {
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_portal.isShowing) _portal.show();
    });
  }

  @override
  void dispose() {
    if (_portal.isShowing) _portal.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = InheritedTheme.capture(from: context, to: null);
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (overlayContext) => Positioned(
        left: 0,
        top: 0,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          child: SizedBox(
            width: _size.width,
            height: _size.height,
            child: Material(
              type: MaterialType.transparency,
              child: theme.wrap(widget.sheet),
            ),
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: LayoutBuilder(builder: (_, c) {
          _size = c.biggest;
          return widget.under;
        }),
      ),
    );
  }
}
