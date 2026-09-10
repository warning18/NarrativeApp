import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/story_providers.dart';

class StoryNodeEditorScreen extends ConsumerStatefulWidget {
  const StoryNodeEditorScreen({super.key, required this.node});

  final StoryNode node;

  @override
  ConsumerState<StoryNodeEditorScreen> createState() => _StoryNodeEditorScreenState();
}

class _StoryNodeEditorScreenState extends ConsumerState<StoryNodeEditorScreen> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _descriptionFrController;
  late final TextEditingController _reqGoldController;
  late final TextEditingController _reqAlignmentController;
  late final TextEditingController _reqAlignmentMaxController;
  late final TextEditingController _reqFlagsController;
  late List<_ChoiceEditState> _choices;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.node.description);
    _descriptionFrController = TextEditingController(text: widget.node.descriptionFr ?? '');
    _reqGoldController = TextEditingController(text: widget.node.reqGold.toString());
    _reqAlignmentController =
        TextEditingController(text: widget.node.reqAlignmentScore?.toString() ?? '');
    _reqAlignmentMaxController =
        TextEditingController(text: widget.node.reqAlignmentMax?.toString() ?? '');
    _reqFlagsController = TextEditingController(text: widget.node.reqFlags.join(', '));
    _choices = widget.node.choices.map((c) => _ChoiceEditState(c)).toList();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _descriptionFrController.dispose();
    _reqGoldController.dispose();
    _reqAlignmentController.dispose();
    _reqAlignmentMaxController.dispose();
    _reqFlagsController.dispose();
    for (final choice in _choices) {
      choice.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = StoryNode(
      id: widget.node.id,
      description: _descriptionController.text,
      descriptionFr:
          _descriptionFrController.text.trim().isEmpty ? null : _descriptionFrController.text.trim(),
      choices: _choices.map((c) => c.toChoice()).toList(),
      reqGold: int.tryParse(_reqGoldController.text.trim()) ?? 0,
      reqAlignmentScore: _reqAlignmentController.text.trim().isEmpty
          ? null
          : int.tryParse(_reqAlignmentController.text.trim()),
      reqAlignmentMax: _reqAlignmentMaxController.text.trim().isEmpty
          ? null
          : int.tryParse(_reqAlignmentMaxController.text.trim()),
      reqFlags: _reqFlagsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
    );
    await saveStoryNode(ref, updated);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(trFor(ref.read(appLanguageProvider), 'node_saved'))),
    );
    Navigator.of(context).pop();
  }

  void _addChoice() {
    setState(() => _choices.add(_ChoiceEditState.blank()));
  }

  void _removeChoice(int index) {
    setState(() {
      _choices[index].dispose();
      _choices.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    String t(String key) => trFor(language, key);
    final storyAsync = ref.watch(storyDataProvider);
    final knownIds = storyAsync.maybeWhen(
      data: (story) => story.nodes.keys.toList()..sort(),
      orElse: () => const <String>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${t('edit_node')} ${widget.node.id}'),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            tooltip: t('save'),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: t('description_en'),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionFrController,
            minLines: 3,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: t('description_fr_label'),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(t('requirements')),
            children: [
              TextField(
                controller: _reqGoldController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t('required_gold'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reqAlignmentController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: InputDecoration(
                  labelText: t('required_alignment'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reqAlignmentMaxController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: InputDecoration(
                  labelText: t('required_alignment_max'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reqFlagsController,
                decoration: InputDecoration(
                  labelText: t('required_flags'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
          const SizedBox(height: 12),
          Text(t('choices_label'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < _choices.length; i++)
            _ChoiceCard(
              index: i,
              state: _choices[i],
              knownIds: knownIds,
              t: t,
              onRemove: () => _removeChoice(i),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addChoice,
            icon: const Icon(Icons.add),
            label: Text(t('add_choice')),
          ),
        ],
      ),
    );
  }
}

class _ChoiceEditState {
  _ChoiceEditState(StoryChoice choice)
      : textController = TextEditingController(text: choice.text),
        textFrController = TextEditingController(text: choice.textFr ?? ''),
        nextId = choice.nextId,
        goldModController = TextEditingController(text: choice.goldMod.toString()),
        alignmentModController = TextEditingController(text: choice.alignmentMod.toString()),
        healAmountController = TextEditingController(text: choice.healAmount.toString()),
        flagsToAddController = TextEditingController(text: choice.flagsToAdd.join(', ')),
        questIDToProgressController = TextEditingController(text: choice.questIDToProgress ?? ''),
        lockedTextController = TextEditingController(text: choice.lockedText ?? ''),
        lockedTextFrController = TextEditingController(text: choice.lockedTextFr ?? ''),
        triggerEnemyIdController = TextEditingController(text: choice.triggerEnemyId ?? ''),
        unlockShopIdController = TextEditingController(text: choice.unlockShopId ?? ''),
        unlockQuestIdController = TextEditingController(text: choice.unlockQuestId ?? ''),
        opensCharacterCreation = choice.opensCharacterCreation;

  _ChoiceEditState.blank() : this(const StoryChoice(text: '', nextId: 'EXIT'));

  final TextEditingController textController;
  final TextEditingController textFrController;
  String nextId;
  final TextEditingController goldModController;
  final TextEditingController alignmentModController;
  final TextEditingController healAmountController;
  final TextEditingController flagsToAddController;
  final TextEditingController questIDToProgressController;
  final TextEditingController lockedTextController;
  final TextEditingController lockedTextFrController;
  final TextEditingController triggerEnemyIdController;
  final TextEditingController unlockShopIdController;
  final TextEditingController unlockQuestIdController;
  bool opensCharacterCreation;

  void dispose() {
    textController.dispose();
    textFrController.dispose();
    goldModController.dispose();
    alignmentModController.dispose();
    healAmountController.dispose();
    flagsToAddController.dispose();
    questIDToProgressController.dispose();
    lockedTextController.dispose();
    lockedTextFrController.dispose();
    triggerEnemyIdController.dispose();
    unlockShopIdController.dispose();
    unlockQuestIdController.dispose();
  }

  StoryChoice toChoice() => StoryChoice(
        text: textController.text,
        textFr: textFrController.text.trim().isEmpty ? null : textFrController.text.trim(),
        nextId: nextId,
        goldMod: int.tryParse(goldModController.text.trim()) ?? 0,
        alignmentMod: int.tryParse(alignmentModController.text.trim()) ?? 0,
        healAmount: int.tryParse(healAmountController.text.trim()) ?? 0,
        flagsToAdd: flagsToAddController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        questIDToProgress:
            questIDToProgressController.text.trim().isEmpty ? null : questIDToProgressController.text.trim(),
        lockedText: lockedTextController.text.trim().isEmpty ? null : lockedTextController.text.trim(),
        lockedTextFr:
            lockedTextFrController.text.trim().isEmpty ? null : lockedTextFrController.text.trim(),
        triggerEnemyId:
            triggerEnemyIdController.text.trim().isEmpty ? null : triggerEnemyIdController.text.trim(),
        unlockShopId:
            unlockShopIdController.text.trim().isEmpty ? null : unlockShopIdController.text.trim(),
        unlockQuestId:
            unlockQuestIdController.text.trim().isEmpty ? null : unlockQuestIdController.text.trim(),
        opensCharacterCreation: opensCharacterCreation,
      );
}

class _ChoiceCard extends StatefulWidget {
  const _ChoiceCard({
    required this.index,
    required this.state,
    required this.knownIds,
    required this.t,
    required this.onRemove,
  });

  final int index;
  final _ChoiceEditState state;
  final List<String> knownIds;
  final String Function(String) t;
  final VoidCallback onRemove;

  @override
  State<_ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final t = widget.t;
    final options = {'EXIT', ...widget.knownIds, state.nextId}.toList()..sort();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${t('choice_n')} ${widget.index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: t('remove_choice'),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            TextField(
              controller: state.textController,
              decoration: InputDecoration(
                labelText: t('choice_text_en'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: state.textFrController,
              decoration: InputDecoration(
                labelText: t('choice_text_fr'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: options.contains(state.nextId) ? state.nextId : options.first,
              decoration: InputDecoration(
                labelText: t('destination_node'),
                border: const OutlineInputBorder(),
              ),
              items: options
                  .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                  .toList(),
              onChanged: (value) => setState(() => state.nextId = value ?? state.nextId),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(t('advanced_options'), style: Theme.of(context).textTheme.bodySmall),
              children: [
                TextField(
                  controller: state.goldModController,
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  decoration: InputDecoration(labelText: t('gold_mod'), border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: state.alignmentModController,
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  decoration:
                      InputDecoration(labelText: t('alignment_mod'), border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: state.healAmountController,
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  decoration:
                      InputDecoration(labelText: t('heal_amount'), border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: state.flagsToAddController,
                  decoration: InputDecoration(
                    labelText: t('flags_to_add'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: state.questIDToProgressController,
                  decoration:
                      InputDecoration(labelText: t('quest_id_to_progress'), border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: state.triggerEnemyIdController,
                  decoration:
                      InputDecoration(labelText: t('trigger_enemy_id'), border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: state.unlockShopIdController,
                  decoration:
                      InputDecoration(labelText: t('unlock_shop_id'), border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: state.unlockQuestIdController,
                  decoration:
                      InputDecoration(labelText: t('unlock_quest_id'), border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: state.lockedTextController,
                  decoration: InputDecoration(
                    labelText: t('locked_text'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: state.lockedTextFrController,
                  decoration: InputDecoration(
                    labelText: t('locked_text_fr'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t('opens_character_creation')),
                  value: state.opensCharacterCreation,
                  onChanged: (value) => setState(() => state.opensCharacterCreation = value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
