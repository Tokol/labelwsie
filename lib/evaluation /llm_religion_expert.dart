import 'dart:convert';
import '../ai/services.dart';

class LLMReligionExpert {
  static Future<Map<String, dynamic>> analyze({
    required List<String> ingredients,
    required String religionId,
    required String strictness,
    required Map<String, dynamic> ruleResult,
  }) async {
    // Build a prompt describing the context
    final prompt = """
You are an expert in ${_prettyReligionName(religionId)} dietary laws.

Strictness level: $strictness

Here is the product ingredient list:
${jsonEncode(ingredients)}

Here is the rule-engine output:
${jsonEncode(ruleResult)}

Task:
1. Re-check the ingredients in case something is missing.
2. Identify ANY extra ingredients that may violate or conflict with the religion rules.
3. Provide a JSON ONLY response with:
{
  "status": "safe" | "warning" | "not_safe",
  "explanation": "Short human-readable explanation",
  "extra_flags": ["list of additional concerns, if any"]
}

Rules:
- If rule-engine found “not_safe”, your status MUST NOT be “safe”.
- If ingredients contain pork, beef (for Hindu), alcohol, or unspecified meat → "not_safe".
- If origin is unclear (e.g. E471, enzymes, aromas) → add to "extra_flags" and mark "warning".
- Keep explanation short.
""";

    final raw = await OpenAIService.instance.callModel(prompt);

    if (raw.isEmpty) {
      return {
        "status": "warning",
        "explanation":
        "AI explanation unavailable. Showing rule-based result only.",
        "extra_flags": []
      };
    }

    try {
      final json = OpenAIService.extractJSON(raw);
      return {
        "status": json["status"] ?? "warning",
        "explanation": json["explanation"] ?? "",
        "extra_flags": json["extra_flags"] ?? [],
      };
    } catch (e) {
      print("LLM parsing failed: $e");
      return {
        "status": "warning",
        "explanation": "AI reasoning unavailable due to format issue.",
        "extra_flags": []
      };
    }
  }

  static String _prettyReligionName(String id) {
    switch (id) {
      case "muslim":
        return "Muslim Halal";
      case "hindu":
        return "Hindu Vegetarian";
      case "jain":
        return "Jain Vegetarian";
      case "sikh":
        return "Sikh Dietary Practice";
      case "jewish":
      case "kosher":
        return "Jewish Kosher";
      default:
        return "Religious";
    }
  }
}
