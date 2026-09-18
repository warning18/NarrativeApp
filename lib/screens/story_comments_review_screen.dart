import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_grid_layout.dart';
import '../data/story_repository.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/story_providers.dart';
import '../utils/export_utils.dart';
import 'story_node_editor_screen.dart';

final RegExp _leadingDigits = RegExp(r'^\d+');

int _nodeSortKey(StoryNode node) =>
    int.tryParse(_leadingDigits.firstMatch(node.id)?.group(0) ?? '') ?? 0;

List<StoryNode> _commentedNodes(StoryData story) {
  return story.nodes.values.where((n) => n.hasComment).toList()
    ..sort((a, b) => _nodeSortKey(a).compareTo(_nodeSortKey(b)));
}

String _asExportText(List<StoryNode> nodes) {
  final b = StringBuffer();
  for (final node in nodes) {
    b.writeln('[${node.id}] (Chapter ${chapterOfNode(node.id)})');
    b.writeln(node.authoringComment);
    b.writeln();
  }
  return b.toString().trim();
}

/// Lists every story node with an [StoryNode.authoringComment] left in Edit
/// Mode, so a note jotted down while reading/testing ("pacing feels off
/// here", "needs a 3rd choice") doesn't just sit on that one node waiting to
/// be stumbled back onto — this is the one place they're all visible at
/// once, and exportable as a single list.
class StoryCommentsReviewScreen extends ConsumerWidget {
  const StoryCommentsReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyAsync = ref.watch(storyDataProvider);
    final commented = storyAsync.maybeWhen(
      data: _commentedNodes,
      orElse: () => const <StoryNode>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'review_comments_title')),
        actions: [
          if (commented.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: tr(ref, 'copy_button'),
              onPressed: () =>
                  copyTextToClipboard(context, ref, _asExportText(commented)),
            ),
            IconButton(
              icon: const Icon(Icons.ios_share_outlined),
              tooltip: tr(ref, 'export_button'),
              onPressed: () => exportTextToFile(context, ref,
                  _asExportText(commented), 'story_review_comments.txt'),
            ),
          ],
        ],
      ),
      body: storyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('${tr(ref, 'failed_to_load_story')}: $error')),
        data: (story) {
          if (commented.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  tr(ref, 'no_review_comments_message'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: commented.length,
            itemBuilder: (context, index) {
              final node = commented[index];
              final comment = node.authoringComment!;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.comment_outlined),
                  title: Text(
                    '${tr(ref, 'node')} ${node.id}'
                    ' · ${tr(ref, 'chapter_label')} ${chapterOfNode(node.id)}',
                  ),
                  subtitle: Text(
                    comment,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: comment.length > 40,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StoryNodeEditorScreen(node: node),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
