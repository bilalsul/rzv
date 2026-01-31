import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';

/// Minimal AI chat service that calls OpenAI-compatible Chat Completions.
/// Reads API key from secure storage via Prefs.setPluginApiKey / getPluginApiKey.
class AiChatService {
  final Prefs prefs;

  AiChatService(this.prefs);

  /// Send a user message and return assistant text or throw on error.
  Future<String> sendMessage(String message) async {
    final apiKey = await prefs.getPluginApiKey('openai');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('No API key configured for OpenAI');
    }

    final model = prefs.prefs.getString('ai_model') ?? 'gpt-3.5-turbo';
    final maxTokens = prefs.prefs.getInt('ai_max_tokens') ?? 512;

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final body = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': prefs.prefs.getString('ai_system_prompt') ?? ''},
        {'role': 'user', 'content': message}
      ],
      'max_tokens': maxTokens,
      'temperature': prefs.prefs.getDouble('ai_temperature') ?? 0.7,
    };

    final resp = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(body));

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final json = jsonDecode(resp.body);
      try {
        final content = json['choices']?[0]?['message']?['content'];
        if (content is String) return content.trim();
      } catch (_) {}
      throw Exception('Malformed response from AI provider');
    } else {
      String messageBody = resp.body;
      try {
        final j = jsonDecode(resp.body);
        messageBody = j['error']?['message'] ?? resp.body;
      } catch (_) {}
      throw Exception('AI request failed (${resp.statusCode}): $messageBody');
    }
  }

  /// Streaming variant: yields incremental chunks of assistant text.
  /// For now we simulate streaming when the input is exactly 'gen'.
  /// Otherwise, if an API key is present, we yield the full reply once.
  Stream<String> streamMessage(String message) async* {
    // Fake streaming generator when user types 'gen'
    if (message.trim() == 'gen') {
      const parts = [
        'Generating',
        ' a',
        ' beautiful',
        ' response',
        ' —',
        ' this',
        ' is',
        ' streamed',
        ' chunk',
        ' by',
        ' chunk.'
      ];
      for (final p in parts) {
        await Future.delayed(const Duration(milliseconds: 220));
        yield p;
      }
      return;
    }

    // For real messages, ensure API key exists
    final apiKey = await prefs.getPluginApiKey('openai');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('No API key configured for OpenAI');
    }

    // Fallback: call non-streaming endpoint and yield once
    final reply = await sendMessage(message);
    yield reply;
  }
}
