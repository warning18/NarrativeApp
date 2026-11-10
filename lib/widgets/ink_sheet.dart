// The app's bottom sheet (v1.871): the grip on top, a scroll-controlled body
// when it holds a list or a form, and an optional width limit on a wide screen.
// It was written out by hand at about fifty places with the same flags.
import 'package:flutter/material.dart';

/// Shows [builder] in a bottom sheet with the grip. [scrollControlled] lets
/// it grow past the half screen (the default; false keeps the platform's
/// 9:16 cap, for a short sheet); [maxWidth] limits it on a wide screen.
Future<T?> showInkSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool scrollControlled = true,
  double? maxWidth,
}) =>
    showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: scrollControlled,
      constraints: maxWidth == null ? null : BoxConstraints(maxWidth: maxWidth),
      builder: builder,
    );
