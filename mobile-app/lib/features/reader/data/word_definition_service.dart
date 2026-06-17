import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:akuko/core/config/env.dart';

final wordDefinitionServiceProvider = Provider<WordDefinitionService>((ref) {
  return WordDefinitionService();
});

/// Calls Gemini with a word and surrounding sentence context.
class WordDefinitionService {
  GenerativeModel? _model;

  GenerativeModel get _gemini {
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: Env.geminiApiKey,
    );
    return _model!;
  }

  bool get isConfigured => Env.isGeminiConfigured;

  Future<String> defineWord({
    required String word,
    required String contextSentence,
  }) async {
    if (!isConfigured) {
      return 'Dictionary is not configured. Add GEMINI_API_KEY to your .env file.';
    }

    final prompt = '''
You are a contextual dictionary for African literature readers.
Define the word "$word" as used in this sentence:
"$contextSentence"

Provide a concise definition (2-4 sentences) explaining the word's meaning in this specific context.
If the word has cultural or regional significance, briefly note it.
Keep the tone warm and accessible.
''';

    final response = await _gemini.generateContent([Content.text(prompt)]);
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw StateError('No definition returned');
    }
    return text;
  }
}
