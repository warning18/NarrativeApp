// "You came back to <place>": the small notice after a one-tap return to a
// town hub (see choice_flow.dart, FlowReturnToHub), so the return does not
// feel like a teleport. It looks like the unlock card (gold edge, a round
// icon), slides in from the top of the Journey, never blocks it, and goes by
// itself after a few seconds or on a tap.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/choice_flow_provider.dart';
import '../providers/geography_provider.dart';
import '../theme/stitched_ink.dart';

/// How long the notice stays when left alone.
const Duration returnNoticeStay = Duration(seconds: 4);

/// Wraps the Journey: shows the notice over it while [lastReturnProvider]
/// holds a return, then clears the provider.
class ReturnNoticeHost extends ConsumerStatefulWidget {
  const ReturnNoticeHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReturnNoticeHost> createState() => _ReturnNoticeHostState();
}

class _ReturnNoticeHostState extends ConsumerState<ReturnNoticeHost> {
  String? _place;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _clear() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() => _place = null);
    ref.read(lastReturnProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(lastReturnProvider, (_, next) {
      if (next == null) return;
      final french = ref.read(appLanguageProvider) == AppLanguage.fr;
      final name =
          ref.read(geographyProvider).place(next.hubStop)?.nameFor(french) ??
              '';
      _timer?.cancel();
      setState(() => _place = name);
      _timer = Timer(returnNoticeStay, _clear);
    });
    final place = _place;
    return Stack(
      children: [
        widget.child,
        if (place != null)
          Positioned(
            left: 16,
            right: 16,
            top: 8,
            child: SafeArea(
              child: ReturnNotice(
                key: const Key('return_notice'),
                place: place,
                onTap: _clear,
              ),
            ),
          ),
      ],
    );
  }
}

class ReturnNotice extends ConsumerStatefulWidget {
  const ReturnNotice({super.key, required this.place, required this.onTap});

  /// The hub's name; empty says "You came back" alone.
  final String place;
  final VoidCallback onTap;

  @override
  ConsumerState<ReturnNotice> createState() => _ReturnNoticeState();
}

class _ReturnNoticeState extends ConsumerState<ReturnNotice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _in.duration = Duration(milliseconds: still ? 150 : 260);
    if (!_in.isAnimating && _in.value == 0) _in.forward();
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final curve = CurvedAnimation(parent: _in, curve: Curves.easeOutCubic);
    final text = widget.place.isEmpty
        ? tr(ref, 'journey_returned_bare')
        : tr(ref, 'journey_returned').replaceAll('{place}', widget.place);
    final card = Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: ink.gold, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surface,
                  border: Border.all(color: ink.gold, width: 2),
                ),
                child: Icon(Icons.undo, color: ink.gold, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    key: const Key('return_notice_text'),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontFamily: InkFonts.prose)),
              ),
            ],
          ),
        ),
      ),
    );
    return still
        ? FadeTransition(opacity: curve, child: card)
        : SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero)
                    .animate(curve),
            child: FadeTransition(opacity: curve, child: card),
          );
  }
}
