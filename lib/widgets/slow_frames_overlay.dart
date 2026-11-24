// The slow-frames counter (v1.765): a small chip over the app while the
// setting is on, showing the slow frames of the screen being played. Off,
// there is no chip, no timer and no timing callback.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/slow_frames_provider.dart';
import '../theme/palette.dart';

class SlowFramesOverlay extends ConsumerStatefulWidget {
  const SlowFramesOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SlowFramesOverlay> createState() => _SlowFramesOverlayState();
}

class _SlowFramesOverlayState extends ConsumerState<SlowFramesOverlay> {
  @override
  void initState() {
    super.initState();
    // The meter follows the setting: started when it turns on (or is saved as
    // on), stopped when it turns off.
    ref.listenManual<bool>(slowFramesProvider, (_, on) {
      final meter = ref.read(slowFrameMeterProvider);
      on ? meter.start() : meter.stop();
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final on = ref.watch(slowFramesProvider);
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (on)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 2,
            right: 8,
            child: const IgnorePointer(child: _SlowFramesChip()),
          ),
      ],
    );
  }
}

class _SlowFramesChip extends ConsumerWidget {
  const _SlowFramesChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meter = ref.watch(slowFrameMeterProvider);
    return ValueListenableBuilder<int>(
      valueListenable: meter.changes,
      builder: (context, _, __) {
        final stat = meter.stats[meter.screen()];
        final slow = stat?.slow ?? 0;
        final text = tr(ref, 'slow_frames_chip')
            .replaceAll('{n}', '$slow')
            .replaceAll('{total}', '${stat?.frames ?? 0}')
            .replaceAll('{ms}', (stat?.worstMs ?? 0).toStringAsFixed(0));
        return ExcludeSemantics(
          child: Container(
            key: const Key('slow_frames_chip'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              border: Border.all(
                  color: slow > 0 ? Palette.orange52 : Colors.white38),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        );
      },
    );
  }
}
