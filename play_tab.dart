import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'game_provider.dart';
import 'models.dart';
import 'theme.dart';

class PlayTab extends ConsumerStatefulWidget {
  const PlayTab({super.key});

  @override
  ConsumerState<PlayTab> createState() => _PlayTabState();
}

class _PlayTabState extends ConsumerState<PlayTab> {
  bool _isAiThinking = false;

  // WARNING: In production, do not hardcode API keys. Use flutter_dotenv or secure storage.
  static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY'; 

  Future<void> _simulateAiChoice(NarrativeNode node) async {
    setState(() => _isAiThinking = true);

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
      );

      // Build the prompt using the current node's data
      String choicesText = node.choices
          .map((c) => "ID: ${c.nextId}, Action: ${c.text}")
          .join('\n');

      final prompt = '''
        You are playing a dark fantasy text adventure as a reckless and aggressive rogue.
        Current situation: "${node.description}"
        
        Available choices:
        $choicesText
        
        Based on your aggressive persona, pick the best choice. 
        Respond ONLY with the exact ID of your chosen next step. Do not add any other text.
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      final String? chosenId = response.text?.trim();

      if (chosenId != null && chosenId.isNotEmpty) {
        // Trigger the state update
        ref.read(gameStateProvider.notifier).makeChoice(chosenId);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Simulation failed: $e')),
      );
    } finally {
      setState(() => _isAiThinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the current narrative node
    final currentNode = ref.watch(gameStateProvider);

    if (currentNode == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryAction));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Node ID Header
            Text(
              'Node ${currentNode.id}',
              style: const TextStyle(
                color: AppColors.surfaceLight,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Narrative Description
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  currentNode.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            
            const Divider(color: AppColors.surfaceDark, height: 40),

            // AI Simulation Button
            if (currentNode.choices.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.aiAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isAiThinking ? null : () => _simulateAiChoice(currentNode),
                  icon: _isAiThinking 
                      ? const SizedBox(
                          width: 20, height: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isAiThinking ? 'AI is deciding...' : 'Simulate Choice with AI'),
                ),
              ),

            // Manual Choice Buttons
            ...currentNode.choices.map((choice) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryAction,
                    side: const BorderSide(color: AppColors.primaryAction, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    ref.read(gameStateProvider.notifier).makeChoice(choice.nextId);
                  },
                  child: Text(
                    choice.text,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),

            // Game Over State
            if (currentNode.choices.isEmpty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  // Restart the game by pointing back to Node 100
                  ref.read(gameStateProvider.notifier).makeChoice('100');
                },
                child: const Text('Restart Playthrough'),
              ),
          ],
        ),
      ),
    );
  }
}