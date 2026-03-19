import 'dart:convert';
import 'package:http/http.dart' as http;

import '../ai/keys.dart';

class OpenAIService {
  OpenAIService._private(); // singleton
  static final OpenAIService instance = OpenAIService._private();

  static const String _baseUrl = "https://api.openai.com/v1/chat/completions";
  static const String _model = "gpt-4o-mini";

  String get _apiKey {
    if (openAiApiKey.isEmpty) {
      throw StateError(
        "Missing OPEN_AI_KEY. Launch the app with --dart-define=OPEN_AI_KEY=your_key.",
      );
    }
    return openAiApiKey;
  }

  /// -----------------------------------------------------------
  /// MAIN CALL
  /// -----------------------------------------------------------
  Future<String> callModel(String prompt) async {
    try {
      final res = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode({
          "model": _model,
          "response_format": {"type": "text"},
          "messages": [
            {"role": "user", "content": prompt}
          ],
        }),
      );

      if (res.statusCode != 200) {
        print("OpenAI error ${res.statusCode}: ${res.body}");
        return "";
      }

      final decoded = jsonDecode(res.body);
      final content = decoded["choices"][0]["message"]["content"] ?? "";
      return content.trim();
    } catch (e) {
      print("OpenAIService error: $e");
      return "";
    }
  }

  Future<String> callImageModel({
    required String prompt,
    required String imageDataUrl,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode({
          "model": _model,
          "response_format": {"type": "text"},
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text": prompt,
                },
                {
                  "type": "image_url",
                  "image_url": {
                    "url": imageDataUrl,
                  },
                },
              ],
            },
          ],
        }),
      );

      if (res.statusCode != 200) {
        print("OpenAI image error ${res.statusCode}: ${res.body}");
        return "";
      }

      final decoded = jsonDecode(res.body);
      final content = decoded["choices"][0]["message"]["content"] ?? "";
      return content.toString().trim();
    } catch (e) {
      print("OpenAIService image error: $e");
      return "";
    }
  }

  /// -----------------------------------------------------------
  /// Extract JSON even when model adds text before/after
  /// Example:
  /// "Here is the result:\n```json\n{ ... }\n```"
  /// -----------------------------------------------------------
  static Map<String, dynamic> extractJSON(String raw) {
    try {
      // find first "{"
      final start = raw.indexOf("{");
      final end = raw.lastIndexOf("}");

      if (start == -1 || end == -1 || end <= start) {
        throw Exception("JSON braces not found");
      }

      final jsonString = raw.substring(start, end + 1);

      return jsonDecode(jsonString);
    } catch (e) {
      print("extractJSON failed → $e");
      print("raw = $raw");
      return {};
    }
  }
}
