// lib/core/services/gemini_service.dart
//
// Multi-provider LLM HTTP service for Rehnumai multi-agent pipeline.
// Priority order: Groq → Google Gemini → OpenRouter

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Exception thrown when the API returns a non-200 status
/// or when response cannot be parsed as valid JSON.
class OpenRouterException implements Exception {
  final int? statusCode;
  final String message;
  final String? rawBody;

  const OpenRouterException({
    required this.message,
    this.statusCode,
    this.rawBody,
  });

  @override
  String toString() =>
      'OpenRouterException(status: $statusCode): $message'
      '${rawBody != null ? "\nBody: $rawBody" : ""}';
}

/// Singleton HTTP service for LLM API calls.
/// Provider priority: GROQ_API_KEY → GEMINI_API_KEY → OPENROUTER_API_KEY
class OpenRouterService {
  OpenRouterService._();
  static final OpenRouterService instance = OpenRouterService._();

  static const String _openRouterBaseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  static const String _groqBaseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // Default Groq model – fast, free, great for JSON
  static const String _defaultGroqModel = 'llama-3.3-70b-versatile';

  // Default model for OpenRouter
  static String get defaultModel =>
      dotenv.env['OPENROUTER_MODEL'] ?? 'openrouter/free';

  // Fallback model if primary model fails
  static String get fallbackModel => 'openrouter/free';

  // HTTP timeout per request
  static const Duration _timeout = Duration(seconds: 60);

  /// Reads Groq API key from dotenv.
  String? get _groqApiKey {
    final key = dotenv.env['GROQ_API_KEY'];
    if (key != null && key.isNotEmpty && key != 'your_groq_api_key_here') {
      return key;
    }
    return null;
  }

  /// Reads OpenRouter API key from dotenv.
  String get _openRouterApiKey {
    return dotenv.env['OPENROUTER_API_KEY'] ?? '';
  }

  /// Reads Google Gemini API key from dotenv.
  String? get _geminiApiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key != null && key.isNotEmpty && key != 'your_gemini_api_key_here') {
      return key;
    }
    return null;
  }

  /// Sends a chat completion request.
  /// Priority: Groq → Gemini Direct → OpenRouter
  Future<Map<String, dynamic>> chat({
    String? model,
    required List<Map<String, dynamic>> messages,
    double temperature = 0.4,
    int maxTokens = 2048,
  }) async {
    // 1. If Groq API key is provided, use Groq (fastest free tier, 30 RPM)
    final groqKey = _groqApiKey;
    if (groqKey != null) {
      return await _chatWithGroq(
        apiKey: groqKey,
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    }

    // 2. If Google Gemini API key is provided, use Google AI Studio
    final gKey = _geminiApiKey;
    if (gKey != null) {
      return await _chatWithGeminiDirect(
        apiKey: gKey,
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    }

    // 3. Otherwise use OpenRouter
    final apiKey = _openRouterApiKey;
    if (apiKey.isEmpty || apiKey == 'your_openrouter_api_key_here') {
      throw const OpenRouterException(
        message: 'No valid API key found. Please set GROQ_API_KEY (from console.groq.com), '
            'GEMINI_API_KEY (from aistudio.google.com), '
            'or OPENROUTER_API_KEY in your .env file.',
      );
    }

    final modelToUse = model ?? defaultModel;

    final requestBody = jsonEncode({
      'model': modelToUse,
      'messages': messages,
      'response_format': {'type': 'json_object'},
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_openRouterBaseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
              'HTTP-Referer': 'https://rehnumai.app',
              'X-Title': 'Rehnumai Student Risk Analyzer',
            },
            body: requestBody,
          )
          .timeout(
            _timeout,
            onTimeout: () => throw OpenRouterException(
              message: 'Request timed out after ${_timeout.inSeconds}s (model: $modelToUse)',
            ),
          );
    } on OpenRouterException {
      rethrow;
    } catch (e) {
      throw OpenRouterException(
        message: 'Network error while calling OpenRouter: $e',
      );
    }

    if (response.statusCode != 200) {
      String? detail;
      try {
        final errBody = jsonDecode(response.body) as Map<String, dynamic>;
        detail = errBody['error']?['message'] as String?;
      } catch (_) {
        detail = null;
      }
      throw OpenRouterException(
        statusCode: response.statusCode,
        message: detail ?? 'HTTP ${response.statusCode} from OpenRouter ($modelToUse)',
        rawBody: response.body.length < 1000 ? response.body : null,
      );
    }

    return _parseOpenAIResponse(response);
  }

  /// Attempts [chat] with primary provider; on 429/error automatically
  /// retries once with OpenRouter free fallback.
  Future<Map<String, dynamic>> chatWithFallback({
    required List<Map<String, dynamic>> messages,
    double temperature = 0.4,
    int maxTokens = 2048,
  }) async {
    try {
      return await chat(
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    } on OpenRouterException catch (e) {
      // On 429 (rate limit) or 5xx, try OpenRouter free as last resort
      if (e.statusCode == 429 || (e.statusCode != null && e.statusCode! >= 500)) {
        final orKey = _openRouterApiKey;
        if (orKey.isNotEmpty && orKey != 'your_openrouter_api_key_here') {
          try {
            return await _chatWithOpenRouterDirect(
              apiKey: orKey,
              model: fallbackModel,
              messages: messages,
              temperature: temperature,
              maxTokens: maxTokens,
            );
          } catch (_) {
            rethrow;
          }
        }
      }
      rethrow;
    }
  }

  // ── Groq Provider ─────────────────────────────────────────────────────────

  /// Groq API – OpenAI-compatible endpoint, extremely fast inference.
  /// Free tier: 30 RPM, 14,400 RPD, 6,000 tokens/min.
  Future<Map<String, dynamic>> _chatWithGroq({
    required String apiKey,
    required List<Map<String, dynamic>> messages,
    required double temperature,
    required int maxTokens,
  }) async {
    final groqModel = dotenv.env['GROQ_MODEL'] ?? _defaultGroqModel;

    final requestBody = jsonEncode({
      'model': groqModel,
      'messages': messages,
      'response_format': {'type': 'json_object'},
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_groqBaseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: requestBody,
          )
          .timeout(
            _timeout,
            onTimeout: () => throw OpenRouterException(
              message: 'Groq API request timed out after ${_timeout.inSeconds}s.',
            ),
          );
    } on OpenRouterException {
      rethrow;
    } catch (e) {
      throw OpenRouterException(
        message: 'Network error while calling Groq: $e',
      );
    }

    if (response.statusCode != 200) {
      String? detail;
      try {
        final errBody = jsonDecode(response.body) as Map<String, dynamic>;
        detail = errBody['error']?['message'] as String?;
      } catch (_) {
        detail = null;
      }
      throw OpenRouterException(
        statusCode: response.statusCode,
        message: detail ?? 'Groq API returned status ${response.statusCode}',
        rawBody: response.body.length < 1000 ? response.body : null,
      );
    }

    return _parseOpenAIResponse(response);
  }

  // ── OpenRouter Direct (for fallback) ──────────────────────────────────────

  Future<Map<String, dynamic>> _chatWithOpenRouterDirect({
    required String apiKey,
    required String model,
    required List<Map<String, dynamic>> messages,
    required double temperature,
    required int maxTokens,
  }) async {
    final requestBody = jsonEncode({
      'model': model,
      'messages': messages,
      'response_format': {'type': 'json_object'},
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    final response = await http
        .post(
          Uri.parse(_openRouterBaseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://rehnumai.app',
            'X-Title': 'Rehnumai Student Risk Analyzer',
          },
          body: requestBody,
        )
        .timeout(
          _timeout,
          onTimeout: () => throw const OpenRouterException(
            message: 'OpenRouter fallback request timed out.',
          ),
        );

    if (response.statusCode != 200) {
      throw OpenRouterException(
        statusCode: response.statusCode,
        message: 'OpenRouter fallback returned status ${response.statusCode}',
        rawBody: response.body.length < 1000 ? response.body : null,
      );
    }

    return _parseOpenAIResponse(response);
  }

  // ── Google Gemini Direct Provider ─────────────────────────────────────────

  /// Direct HTTP execution using Google AI Studio API key (GEMINI_API_KEY).
  Future<Map<String, dynamic>> _chatWithGeminiDirect({
    required String apiKey,
    required List<Map<String, dynamic>> messages,
    required double temperature,
    required int maxTokens,
  }) async {
    final systemMessage = messages.firstWhere(
      (m) => m['role'] == 'system',
      orElse: () => {'content': ''},
    )['content'] as String;

    final userMessages = messages.where((m) => m['role'] != 'system').toList();
    final parts = <Map<String, String>>[];
    for (final msg in userMessages) {
      parts.add({'text': msg['content'] as String});
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final requestBody = jsonEncode({
      if (systemMessage.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemMessage}
          ]
        },
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
        'responseMimeType': 'application/json',
      },
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    ).timeout(
      _timeout,
      onTimeout: () => throw const OpenRouterException(
        message: 'Google Gemini API request timed out after 60s.',
      ),
    );

    if (response.statusCode != 200) {
      throw OpenRouterException(
        statusCode: response.statusCode,
        message: 'Google Gemini API returned status ${response.statusCode}',
        rawBody: response.body,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw const OpenRouterException(
        message: 'Google Gemini API returned no candidates.',
      );
    }

    final text = (candidates.first['content']?['parts'] as List<dynamic>?)
        ?.first?['text'] as String?;

    if (text == null || text.trim().isEmpty) {
      throw const OpenRouterException(
        message: 'Google Gemini API returned empty content.',
      );
    }

    final cleaned = _stripMarkdownFences(text.trim());
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  /// Parses an OpenAI-compatible chat completion response (used by Groq & OpenRouter).
  Map<String, dynamic> _parseOpenAIResponse(http.Response response) {
    Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw OpenRouterException(
        statusCode: response.statusCode,
        message: 'Failed to decode response as JSON: $e',
        rawBody: response.body.length < 500 ? response.body : null,
      );
    }

    final choices = envelope['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw OpenRouterException(
        statusCode: response.statusCode,
        message: 'API response contained no choices.',
        rawBody: response.body.length < 500 ? response.body : null,
      );
    }

    final content =
        (choices.first as Map<String, dynamic>)['message']?['content']
            as String?;

    if (content == null || content.trim().isEmpty) {
      throw OpenRouterException(
        statusCode: response.statusCode,
        message: 'API returned an empty content string.',
      );
    }

    final cleaned = _stripMarkdownFences(content.trim());

    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw OpenRouterException(
        statusCode: response.statusCode,
        message: 'Model returned content that is not valid JSON: $e',
        rawBody: cleaned.length < 500 ? cleaned : cleaned.substring(0, 500),
      );
    }
  }

  /// Strips ```json ... ``` or ``` ... ``` markdown fences from [text].
  static String _stripMarkdownFences(String text) {
    final fencePattern = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$');
    final match = fencePattern.firstMatch(text);
    return match != null ? match.group(1)!.trim() : text;
  }
}
