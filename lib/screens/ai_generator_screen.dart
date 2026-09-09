import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../providers/settings_providers.dart';

class AiGeneratorScreen extends ConsumerStatefulWidget {
  const AiGeneratorScreen({super.key});

  @override
  ConsumerState<AiGeneratorScreen> createState() => _AiGeneratorScreenState();
}

class _AiGeneratorScreenState extends ConsumerState<AiGeneratorScreen> {
  final _promptController = TextEditingController();
  bool _isLoading = false;
  String? _result;
  String? _error;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final apiKey = ref.read(apiKeyProvider);
    final prompt = _promptController.text.trim();

    if (apiKey == null || apiKey.isEmpty) {
      setState(() => _error = 'Add your Gemini API key in Settings first.');
      return;
    }
    if (prompt.isEmpty) {
      setState(() => _error = 'Describe what should happen next.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final response = await model.generateContent([
        Content.text(
          'You are a dark fantasy interactive-fiction writer. '
          'Continue the story with a short, vivid scene (3-5 sentences) '
          'followed by 2-3 numbered choices for the reader. '
          'Prompt: $prompt',
        ),
      ]);
      if (!mounted) return;
      setState(() => _result = response.text ?? 'No response generated.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Generation failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = ref.watch(apiKeyProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (apiKey == null || apiKey.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No Gemini API key set. Open Settings to add one.',
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            TextField(
              controller: _promptController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'What happens next?',
                hintText:
                    'e.g. Lysa wakes up and finds the Grey Bundle missing.',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generate,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isLoading ? 'Generating...' : 'Generate'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: TextStyle(color: colorScheme.error)),
            if (_result != null)
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(_result!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
