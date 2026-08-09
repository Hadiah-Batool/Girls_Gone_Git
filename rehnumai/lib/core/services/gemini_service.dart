// lib/core/services/gemini_service.dart
//
// OpenRouter HTTP service for the Rehnumai multi-agent pipeline.
//
// This is a thin, stateless wrapper around the OpenRouter
// OpenAI-compatible chat completions endpoint. It reads the API key
// from the .env file via flutter_dotenv and returns parsed JSON maps.
//
// Usage:
//   final result = await OpenRouterService.instance.chat(
//     model: 'google/gemini-2.5-flash',
//     messages: [ {'role': 'system', 'content': '...'}, ... ],
//   );

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Exception thrown when the OpenRouter API returns a non-200 status
/// or when the response cannot be parsed as valid JSON.
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

/// Singleton HTTP service for OpenRouter API calls.
///
/// Call [OpenRouterService.instance] after [dotenv.load()] has been
/// executed in your app's [main()] function.
class OpenRouterService {
  OpenRouterService._();
  static final OpenRouterService instance = OpenRouterService._();

  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  // Default model – uses OPENROUTER_MODEL from .env if defined, else 'openrouter/free'
  static String get defaultModel =>
      dotenv.env['OPENROUTER_MODEL'] ?? 'openrouter/free';

  // Fallback model if primary model fails or is unavailable/overloaded
  static String get fallbackModel => 'openrouter/free';

  // HTTP timeout per request
  static const Duration _timeout = Duration(seconds: 60);

  /// Reads the API key from dotenv; throws [OpenRouterException] if missing.
  String get _apiKey {
    final key = dotenv.env['OPENROUTER_API_KEY'];
    if (key == null || key.isEmpty || key == 'your_openrouter_api_key_here') {
      throw const OpenRouterException(
        message: 'OPENROUTER_API_KEY is not set in the .env file. '
            'Add your key and restart the app.',
      );
    }
    return key;
  }

  /// Sends a chat completion request to OpenRouter.
  Future<Map<String, dynamic>> chat({
    String? model,
    required List<Map<String, dynamic>> messages,
    double temperature = 0.4,
    int maxTokens = 2048,
  }) async {
    final apiKey = _apiKey;
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
            Uri.parse(_baseUrl),
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
        message: 'OpenRouter response contained no choices.',
        rawBody: response.body.length < 500 ? response.body : null,
      );
    }

    final content =
        (choices.first as Map<String, dynamic>)['message']?['content']
            as String?;

    if (content == null || content.trim().isEmpty) {
      throw OpenRouterException(
        statusCode: response.statusCode,
        message: 'OpenRouter returned an empty content string.',
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

  /// Attempts [chat] with defaultModel (or OPENROUTER_MODEL from .env); on any error
  /// (e.g. 404 model removed, 402 no credits, 429 rate limit, 503 unavailable) automatically
  /// retries once with fallback free model.
  Future<Map<String, dynamic>> chatWithFallback({
    required List<Map<String, dynamic>> messages,
    double temperature = 0.4,
    int maxTokens = 2048,
  }) async {
    final primaryModel = defaultModel;
    try {
      return await chat(
        model: primaryModel,
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    } on OpenRouterException catch (_) {
      if (primaryModel != fallbackModel) {
        try {
          return await chat(
            model: fallbackModel,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
          );
        } catch (_) {
          rethrow;
        }
      }
      rethrow;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Strips ```json ... ``` or ``` ... ``` markdown fences from [text].
  static String _stripMarkdownFences(String text) {
    // Match ```json\n...\n``` or ```\n...\n```
    final fencePattern = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$');
    final match = fencePattern.firstMatch(text);
    return match != null ? match.group(1)!.trim() : text;
  }
}
