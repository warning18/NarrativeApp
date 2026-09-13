import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
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

    final lang = ref.read(appLanguageProvider);
    if (apiKey == null || apiKey.isEmpty) {
      setState(() => _error = trFor(lang, 'add_api_key_first'));
      return;
    }
    if (prompt.isEmpty) {
      setState(() => _error = trFor(lang, 'describe_next'));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final response = await model.generateContent([
        Content.text(
          'You are a dark fantasy interactive-fiction writer. '
          'Continue the story with a short, vivid scene (3-5 sentences) '
          'followed by 2-3 numbered choices for the reader. '
          'Prompt: $prompt',
        ),
      ]);
      if (!mounted) return;
      setState(() => _result = response.text ?? trFor(lang, 'no_response_generated'));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '${trFor(lang, 'generation_failed_prefix')}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = ref.watch(apiKeyProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final lang = ref.watch(appLanguageProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
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
                    trFor(lang, 'no_api_key_banner'),
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
              TextField(
                controller: _promptController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: trFor(lang, 'what_happens_next_label'),
                  hintText: trFor(lang, 'ai_prompt_hint'),
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
                label: Text(_isLoading ? trFor(lang, 'generating_label') : trFor(lang, 'generate_button')),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: TextStyle(color: colorScheme.error)),
              if (_result != null) SelectableText(_result!),
            ],
          ),
        ),
      ),
    );
  }
}
