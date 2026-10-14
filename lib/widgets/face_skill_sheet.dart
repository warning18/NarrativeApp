import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../theme/stitched_ink.dart';
import 'help_hint.dart';

/// How a skill changes a die face (board 9): the face as it is, the face as
/// it would be, and what kind of change that is. The numbers come from the
/// fight's own rule for a face with a skill on it, so the sheet never
/// disagrees with the fight (Core's compare helper builds these).
enum FaceChangeKind { gain, loss, kind, same }

class FaceChange {
  const FaceChange({
    required this.before,
    required this.after,
    required this.kind,
    this.delta,
  });

  /// "Attack 5".
  final String before;

  /// "Attack 7 · Water", "Mana +2 · Light".
  final String after;
  final FaceChangeKind kind;

  /// The change in the face's value, for the pill (+2, -1); null for a
  /// change of kind or none.
  final int? delta;
}

/// One skill of the sheet's list, ready to show.
class FaceSkillOption {
  const FaceSkillOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconColour,
    required this.rarityLabel,
    required this.rarityColour,
    required this.change,
    required this.limitLine,
    required this.allowed,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color iconColour;
  final String rarityLabel;

  /// The colour of the rarity, which the limit line carries.
  final Color rarityColour;
  final FaceChange change;

  /// "on 1/3 faces", or why it cannot go on this face.
  final String limitLine;

  /// False at the skill's limit: dimmed, with its pill saying "full".
  final bool allowed;
}

/// The sheet that opens from a die face: its skills, each with the face now
/// and the face after, the change as a pill; a tap lights a row and a bar at
/// the foot offers "Set on this face", so skills can be compared before
/// anything changes. The 70% rule is behind the title (hold it).
Future<void> showFaceSkillSheet(
  BuildContext context, {
  required String nowLine,
  required String? note,
  required List<FaceSkillOption> options,
  required String? currentId,
  required ValueChanged<String> onSet,
  required VoidCallback? onClear,
  required String clearSubtitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => FaceSkillSheet(
      nowLine: nowLine,
      note: note,
      options: options,
      currentId: currentId,
      clearSubtitle: clearSubtitle,
      onSet: (id) {
        Navigator.of(sheet).pop();
        onSet(id);
      },
      onClear: onClear == null
          ? null
          : () {
              Navigator.of(sheet).pop();
              onClear();
            },
    ),
  );
}

class FaceSkillSheet extends ConsumerStatefulWidget {
  const FaceSkillSheet({
    super.key,
    required this.nowLine,
    required this.note,
    required this.options,
    required this.currentId,
    required this.onSet,
    required this.onClear,
    required this.clearSubtitle,
  });

  final String nowLine;
  final String? note;
  final List<FaceSkillOption> options;
  final String? currentId;
  final ValueChanged<String> onSet;
  final VoidCallback? onClear;
  final String clearSubtitle;

  @override
  ConsumerState<FaceSkillSheet> createState() => _FaceSkillSheetState();
}

class _FaceSkillSheetState extends ConsumerState<FaceSkillSheet> {
  String? _picked;

  FaceSkillOption? get _pickedOption {
    final id = _picked;
    if (id == null || id == widget.currentId) return null;
    for (final o in widget.options) {
      if (o.id == id) return o;
    }
    return null;
  }

  Widget _pill(FaceSkillOption o) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final (String text, Color colour) = !o.allowed
        ? (tr(ref, 'face_full_pill'), ink.ember)
        : switch (o.change.kind) {
            FaceChangeKind.gain => ('+${o.change.delta ?? ''}', ink.heal),
            FaceChangeKind.loss => (
                '−${(o.change.delta ?? 0).abs()}',
                ink.ember
              ),
            FaceChangeKind.kind => (tr(ref, 'face_change_kind'), ink.gold),
            FaceChangeKind.same => (tr(ref, 'face_change_same'), ink.ash),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colour),
      ),
      child: Text(text,
          maxLines: 1,
          style: theme.textTheme.labelSmall?.copyWith(color: colour)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final picked = _pickedOption;
    final note = widget.note;
    return SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  note == null
                      ? Text(tr(ref, 'pick_face_skill_title'),
                          style: theme.textTheme.titleMedium)
                      : HelpTitle(
                          title: tr(ref, 'pick_face_skill_title'), help: note),
                  const SizedBox(height: 6),
                  Container(
                    key: const Key('face_now'),
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: ink.seam),
                    ),
                    child:
                        Text(widget.nowLine, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                children: [
                  if (widget.onClear != null)
                    ListTile(
                      key: const Key('face_reset'),
                      dense: true,
                      leading: const Icon(Icons.undo),
                      title: Text(tr(ref, 'reset_face_button')),
                      subtitle: Text(widget.clearSubtitle),
                      onTap: widget.onClear,
                    ),
                  if (widget.options.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(tr(ref, 'no_skills_unlocked_hint')),
                    ),
                  for (final o in widget.options)
                    ListTile(
                      key: Key('pick_skill_${o.id}'),
                      enabled: o.allowed,
                      selected: o.id == _picked || o.id == widget.currentId,
                      selectedTileColor: ink.gold.withValues(alpha: 0.10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                            color: o.id == _picked
                                ? ink.gold
                                : Colors.transparent),
                      ),
                      leading: Icon(o.icon, color: o.iconColour),
                      title: Text(o.name, overflow: TextOverflow.ellipsis),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${o.change.before} → ${o.change.after}',
                              key: Key('pick_change_${o.id}')),
                          Text(o.limitLine,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: o.allowed ? ink.ash : ink.ember)),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: o.id == widget.currentId
                          ? const Icon(Icons.check)
                          : _pill(o),
                      onTap: o.allowed
                          ? () => setState(() => _picked = o.id)
                          : null,
                    ),
                ],
              ),
            ),
            if (picked != null)
              Container(
                key: const Key('face_set_bar'),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  border: Border(top: BorderSide(color: ink.gold, width: 2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${picked.change.before} → ${picked.change.after}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(picked.name,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash)),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      children: [
                        TextButton(
                          key: const Key('face_set_cancel'),
                          onPressed: () => setState(() => _picked = null),
                          child: Text(tr(ref, 'cancel')),
                        ),
                        FilledButton(
                          key: const Key('face_set_button'),
                          onPressed: () => widget.onSet(picked.id),
                          child: Text(tr(ref, 'face_set_button')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
