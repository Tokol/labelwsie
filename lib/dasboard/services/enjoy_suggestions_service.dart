import 'dart:convert';

import '../../ai/services.dart';

class EnjoySuggestionsResult {
  final List<String> tips;
  final int confidencePercent;

  const EnjoySuggestionsResult({
    required this.tips,
    required this.confidencePercent,
  });
}

class EnjoySuggestionsService {
  EnjoySuggestionsService._();

  static Future<EnjoySuggestionsResult> fetchSuggestions({
    required Map<String, dynamic> product,
    required List<String> ingredients,
    required String? origin,
    required List<String> ranEvaluations,
    required Map<String, dynamic> evaluationResults,
  }) async {
    final prompt = _buildPrompt(
      product: product,
      ingredients: ingredients,
      origin: origin,
      ranEvaluations: ranEvaluations,
      evaluationResults: evaluationResults,
    );

    final raw = await OpenAIService.instance.callModel(prompt);
    if (raw.trim().isEmpty) {
      final tips = _fallbackTips(product: product, ingredients: ingredients);
      return EnjoySuggestionsResult(
        tips: tips,
        confidencePercent: _estimateConfidencePercent(
          product: product,
          ingredients: ingredients,
          origin: origin,
          ranEvaluations: ranEvaluations,
          usedModelOutput: false,
        ),
      );
    }

    final parsed = OpenAIService.extractJSON(raw);
    final tips = parsed["tips"];
    if (tips is List) {
      final cleaned = tips
          .map((item) => item?.toString().trim() ?? "")
          .where((item) => item.isNotEmpty)
          .take(4)
          .toList();
      if (cleaned.isNotEmpty) {
        return EnjoySuggestionsResult(
          tips: cleaned,
          confidencePercent: _estimateConfidencePercent(
            product: product,
            ingredients: ingredients,
            origin: origin,
            ranEvaluations: ranEvaluations,
            usedModelOutput: true,
          ),
        );
      }
    }

    final fallback = _fallbackTips(product: product, ingredients: ingredients);
    return EnjoySuggestionsResult(
      tips: fallback,
      confidencePercent: _estimateConfidencePercent(
        product: product,
        ingredients: ingredients,
        origin: origin,
        ranEvaluations: ranEvaluations,
        usedModelOutput: false,
      ),
    );
  }

  static String _buildPrompt({
    required Map<String, dynamic> product,
    required List<String> ingredients,
    required String? origin,
    required List<String> ranEvaluations,
    required Map<String, dynamic> evaluationResults,
  }) {
    final category = product["categories"]?.toString().split(",").last.trim();
    final productName = product["product_name"]?.toString().trim();
    final evaluationNotes = <String>[];

    for (final domain in ranEvaluations) {
      final raw = evaluationResults[domain];
      if (raw is! Map) continue;
      final result = raw["result"];
      if (result is! Map) continue;

      if (domain == "allergy") {
        final ruleBased = result["rule_based"];
        if (ruleBased is Map && ruleBased["message"] != null) {
          evaluationNotes.add("$domain: ${ruleBased["message"]}");
        }
        continue;
      }

      if (result["message"] != null) {
        evaluationNotes.add("$domain: ${result["message"]}");
      }
    }

    final input = {
      "product_name": productName,
      "category": category,
      "origin": origin,
      "ingredients": ingredients.take(12).toList(),
      "has_personalization": ranEvaluations.isNotEmpty,
      "evaluation_notes": evaluationNotes,
    };

    return """
You are helping a user understand how to eat or enjoy a food product.

Return ONLY valid JSON in this format:
{
  "tips": [
    "short tip",
    "short tip",
    "short tip"
  ]
}

Rules:
- Return 2 to 4 tips.
- Each tip must be short, practical, and user-friendly.
- If the food may be unfamiliar to an international traveler or student, explain how it is commonly eaten.
- If personalization notes exist, respect them.
- Do not mention JSON, models, preferences, evaluations, or medical disclaimers.
- Do not repeat the product name in every tip.
- No markdown bullets in output. Only JSON.

Input:
${jsonEncode(input)}
""";
  }

  static List<String> _fallbackTips({
    required Map<String, dynamic> product,
    required List<String> ingredients,
  }) {
    final category = product["categories"]?.toString().toLowerCase() ?? "";
    final isBread = category.contains("bread") || category.contains("rye");

    if (isBread) {
      return const [
        "Often eaten toasted or with savory spreads.",
        "Try it with soup, cheese, hummus, or sliced vegetables.",
        "For a lighter option, pair it with fresh toppings instead of sweet spreads.",
      ];
    }

    if (ingredients.isNotEmpty) {
      return const [
        "Try a small portion first if this food is unfamiliar to you.",
        "Pair it with simple sides so the main flavor stays easy to understand.",
        "Check whether it is usually eaten warm, chilled, or straight from the pack.",
      ];
    }

    return const [
      "Try a small portion first if this food is unfamiliar to you.",
      "Pair it with simple sides for a balanced eating experience.",
    ];
  }

  static int _estimateConfidencePercent({
    required Map<String, dynamic> product,
    required List<String> ingredients,
    required String? origin,
    required List<String> ranEvaluations,
    required bool usedModelOutput,
  }) {
    var score = usedModelOutput ? 76 : 58;

    if ((product["product_name"]?.toString().trim().isNotEmpty ?? false)) {
      score += 5;
    }
    if ((product["categories"]?.toString().trim().isNotEmpty ?? false)) {
      score += 6;
    }
    if (origin != null && origin.trim().isNotEmpty) {
      score += 4;
    }
    if (ingredients.isNotEmpty) {
      score += 9;
    }
    if (ingredients.length >= 4) {
      score += 4;
    }
    if (ranEvaluations.isNotEmpty) {
      score += 6;
    }
    if (ranEvaluations.length >= 2) {
      score += 3;
    }

    return score.clamp(45, 95);
  }
}
