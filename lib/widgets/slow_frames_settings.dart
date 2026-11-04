// The Settings tile of the slow-frames counter (v1.765): the switch, and
// while it is on a button that copies the numbers and one that clears them.
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_info.dart';
import '../l10n/app_strings.dart';
import '../providers/slow_frames_provider.dart';

class SlowFramesSettings extends ConsumerWidget {
  const SlowFramesSettings({super.key});

  /// A line about the phone and the build, for the top of the report.
  String _device(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final display = View.maybeOf(context)?.display;
    final hz = display == null ? '' : ' @ ${display.refreshRate.round()} Hz';
    return '${AppInfo.displayName} · ${defaultTargetPlatform.name} · '
        '${size.width.round()} x ${size.height.round()} dp, '
        '${dpr.toStringAsFixed(1)}x$hz';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(slowFramesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const Key('slow_frames_setting'),
          contentPadding: EdgeInsets.zero,
          title: Text(tr(ref, 'slow_frames_setting_title')),
          subtitle: Text(tr(ref, 'slow_frames_setting_desc')),
          value: on,
          onChanged: (value) =>
              ref.read(slowFramesProvider.notifier).setEnabled(value),
        ),
        if (on)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              OutlinedButton(
                key: const Key('slow_frames_copy'),
                onPressed: () async {
                  final text = ref
                      .read(slowFrameMeterProvider)
                      .report(device: _device(context));
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr(ref, 'slow_frames_copied'))));
                },
                child: Text(tr(ref, 'slow_frames_copy')),
              ),
              TextButton(
                key: const Key('slow_frames_reset'),
                onPressed: ref.read(slowFrameMeterProvider).reset,
                child: Text(tr(ref, 'slow_frames_reset')),
              ),
            ],
          ),
      ],
    );
  }
}
