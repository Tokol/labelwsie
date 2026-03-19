import 'dart:convert';

import '../../ai/services.dart';

class AlternativeSuggestion {
  final String type;
  final String title;
  final String reason;
  final List<String> fitTags;
  final List<String> localExamples;

  const AlternativeSuggestion({
    required this.type,
    required this.title,
    required this.reason,
    required this.fitTags,
    required this.localExamples,
  });
}

class AlternativeSuggestionsResult {
  final List<AlternativeSuggestion> suggestions;
  final int confidencePercent;

  const AlternativeSuggestionsResult({
    required this.suggestions,
    required this.confidencePercent,
  });
}

class AlternativeSuggestionsService {
  AlternativeSuggestionsService._();

  static Future<AlternativeSuggestionsResult> fetchSuggestions({
    required Map<String, dynamic> product,
    required List<String> ingredients,
    required List<String> additives,
    required List<String> allergens,
    required Map<String, double> nutriments,
    required Map<String, String> nutrientLevels,
    required String? nutriScore,
    required int? novaGroup,
    required List<String> ranEvaluations,
    required Map<String, dynamic> evaluationResults,
    String? userMarketCountry,
    String marketCountrySource = "unavailable",
  }) async {
    final prompt = _buildPrompt(
      product: product,
      ingredients: ingredients,
      additives: additives,
      allergens: allergens,
      nutriments: nutriments,
      nutrientLevels: nutrientLevels,
      nutriScore: nutriScore,
      novaGroup: novaGroup,
      ranEvaluations: ranEvaluations,
      evaluationResults: evaluationResults,
      userMarketCountry: userMarketCountry,
      marketCountrySource: marketCountrySource,
    );

    final raw = await OpenAIService.instance.callModel(prompt);
    if (raw.trim().isEmpty) {
      final fallback = _fallbackSuggestions(
        product: product,
        ranEvaluations: ranEvaluations,
      );
      return AlternativeSuggestionsResult(
        suggestions: fallback,
        confidencePercent: _estimateConfidencePercent(
          product: product,
          ingredients: ingredients,
          userMarketCountry: userMarketCountry,
          marketCountrySource: marketCountrySource,
          ranEvaluations: ranEvaluations,
          usedModelOutput: false,
        ),
      );
    }

    final parsed = OpenAIService.extractJSON(raw);
    final result = parsed["result"];
    if (result is! Map) {
      final fallback = _fallbackSuggestions(
        product: product,
        ranEvaluations: ranEvaluations,
      );
      return AlternativeSuggestionsResult(
        suggestions: fallback,
        confidencePercent: _estimateConfidencePercent(
          product: product,
          ingredients: ingredients,
          userMarketCountry: userMarketCountry,
          marketCountrySource: marketCountrySource,
          ranEvaluations: ranEvaluations,
          usedModelOutput: false,
        ),
      );
    }

    final alternatives = result["alternatives"];
    if (alternatives is! List) {
      final fallback = _fallbackSuggestions(
        product: product,
        ranEvaluations: ranEvaluations,
      );
      return AlternativeSuggestionsResult(
        suggestions: fallback,
        confidencePercent: _estimateConfidencePercent(
          product: product,
          ingredients: ingredients,
          userMarketCountry: userMarketCountry,
          marketCountrySource: marketCountrySource,
          ranEvaluations: ranEvaluations,
          usedModelOutput: false,
        ),
      );
    }

    final cleaned = <AlternativeSuggestion>[];
    for (final item in alternatives.take(3)) {
      if (item is! Map) continue;

      final type = item["type"]?.toString().trim() ?? "";
      final title = item["title"]?.toString().trim() ?? "";
      final reason = item["reason"]?.toString().trim() ?? "";
      final fitTags = (item["fit_tags"] as List?)
              ?.map((tag) => tag?.toString().trim() ?? "")
              .where((tag) => tag.isNotEmpty)
              .take(3)
              .toList() ??
          const <String>[];
      final localExamples = (item["local_examples"] as List?)
              ?.map((example) => example?.toString().trim() ?? "")
              .where((example) => example.isNotEmpty)
              .take(2)
              .toList() ??
          const <String>[];

      if (type.isEmpty || title.isEmpty || reason.isEmpty) continue;

      cleaned.add(
        AlternativeSuggestion(
          type: type,
          title: title,
          reason: reason,
          fitTags: fitTags,
          localExamples: localExamples,
        ),
      );
    }

    if (cleaned.isNotEmpty) {
      return AlternativeSuggestionsResult(
        suggestions: cleaned,
        confidencePercent: _estimateConfidencePercent(
          product: product,
          ingredients: ingredients,
          userMarketCountry: userMarketCountry,
          marketCountrySource: marketCountrySource,
          ranEvaluations: ranEvaluations,
          usedModelOutput: true,
        ),
      );
    }

    final fallback = _fallbackSuggestions(
      product: product,
      ranEvaluations: ranEvaluations,
    );
    return AlternativeSuggestionsResult(
      suggestions: fallback,
      confidencePercent: _estimateConfidencePercent(
        product: product,
        ingredients: ingredients,
        userMarketCountry: userMarketCountry,
        marketCountrySource: marketCountrySource,
        ranEvaluations: ranEvaluations,
        usedModelOutput: false,
      ),
    );
  }

  static String _buildPrompt({
    required Map<String, dynamic> product,
    required List<String> ingredients,
    required List<String> additives,
    required List<String> allergens,
    required Map<String, double> nutriments,
    required Map<String, String> nutrientLevels,
    required String? nutriScore,
    required int? novaGroup,
    required List<String> ranEvaluations,
    required Map<String, dynamic> evaluationResults,
    String? userMarketCountry,
    required String marketCountrySource,
  }) {
    final category = product["categories"]?.toString().split(",").last.trim();
    final productName = product["product_name"]?.toString().trim();
    final brand = product["brands"]?.toString().trim();
    final productOrigin = product["countries"]?.toString().trim().isNotEmpty == true
        ? product["countries"]?.toString().trim()
        : product["origin"]?.toString().trim();

    final evaluationNotes = <Map<String, String>>[];
    for (final domain in ranEvaluations) {
      final raw = evaluationResults[domain];
      if (raw is! Map) continue;
      final result = raw["result"];
      if (result is! Map) continue;

      String status = result["status"]?.toString() ?? "unknown";
      String message = result["message"]?.toString() ?? "";

      if (domain == "allergy") {
        final summary = result["summary"];
        if (summary is Map) {
          status = summary["status"]?.toString() ?? status;
        }
        final ruleBased = result["rule_based"];
        if (ruleBased is Map && ruleBased["message"] != null) {
          message = ruleBased["message"].toString();
        }
      }

      evaluationNotes.add({
        "domain": domain,
        "status": status,
        "message": message,
      });
    }

    final input = {
      "product_name": productName,
      "brand": brand,
      "category": category,
      "country_context": userMarketCountry,
      "country_context_source": marketCountrySource,
      "product_origin_country": productOrigin,
      "ingredients": ingredients.take(15).toList(),
      "additives": additives.take(10).toList(),
      "allergens": allergens.take(10).toList(),
      "nutriments": nutriments,
      "nutrient_levels": nutrientLevels,
      "nutri_score": nutriScore,
      "nova_group": novaGroup,
      "has_personalization": ranEvaluations.isNotEmpty,
      "evaluation_notes": evaluationNotes,
    };

    return """
You are a food alternative recommendation assistant.

Your job is to suggest safer or better replacement options for a scanned packaged food product.

Return ONLY valid JSON in this format:
{
  "result": {
    "alternatives": [
      {
        "type": "best_match | budget_friendly | healthier_pick",
        "title": "generic alternative type",
        "reason": "short user-facing reason",
        "fit_tags": ["tag", "tag", "tag"],
        "local_examples": ["optional local example", "optional local example"]
      }
    ]
  }
}

Rules:
- Return exactly 3 alternatives when possible.
- The title must stay generic food/product type only.
- You may add 0 to 2 local_examples if they are common examples likely to be found in the provided country context.
- If you are not reasonably confident about local examples, return an empty list for local_examples.
- Prefer country_context over product_origin_country for local examples.
- If country_context_source is product_origin_fallback, be more conservative with local_examples.
- Respect hard conflicts in the evaluation notes.
- If personalization exists, reflect it in the recommendations.
- Keep each title short.
- Keep each reason to one sentence.
- fit_tags must be short and scan-friendly.
- local_examples are illustrative examples, not guaranteed availability.
- Do not mention JSON, models, prompts, or medical disclaimers.
- No markdown.

The three alternative types should be:
1. best_match: best fit for the user's active preferences
2. budget_friendly: simpler or more affordable substitute that still avoids major conflicts
3. healthier_pick: nutritionally better or less processed substitute that still avoids major conflicts

If there are no personalization notes, use general health and value logic.

Input:
${jsonEncode(input)}
""";
  }

  static List<AlternativeSuggestion> _fallbackSuggestions({
    required Map<String, dynamic> product,
    required List<String> ranEvaluations,
  }) {
    final category = product["categories"]?.toString().toLowerCase() ?? "";
    final isDrink = category.contains("drink") ||
        category.contains("beverage") ||
        category.contains("milk");
    final isBread = category.contains("bread") || category.contains("toast");

    final bestMatchTitle = isDrink
        ? "Unsweetened plant-based drink"
        : isBread
            ? "Plain wholegrain bread"
            : "Simple ingredient version";

    final budgetTitle = isDrink
        ? "Store-brand plain beverage"
        : isBread
            ? "Basic rye or wholegrain loaf"
            : "Budget-friendly basic option";

    final healthierTitle = isDrink
        ? "Low-sugar minimally processed drink"
        : isBread
            ? "Wholegrain loaf with fewer additives"
            : "Less processed healthier option";

    final preferenceAware = ranEvaluations.isNotEmpty;

    return [
      AlternativeSuggestion(
        type: "best_match",
        title: bestMatchTitle,
        reason: preferenceAware
            ? "This is a safer starting point based on your current preference checks."
            : "This is a balanced replacement for the scanned product.",
        fitTags: const ["Preference fit", "Safer choice"],
        localExamples: const [],
      ),
      AlternativeSuggestion(
        type: "budget_friendly",
        title: budgetTitle,
        reason:
            "This keeps the replacement simple and more value-focused while avoiding obvious conflicts.",
        fitTags: const ["Budget-friendly", "Simple swap"],
        localExamples: const [],
      ),
      AlternativeSuggestion(
        type: "healthier_pick",
        title: healthierTitle,
        reason:
            "This aims for a cleaner nutrition profile or lower processing than the scanned product.",
        fitTags: const ["Healthier pick", "Lower processing"],
        localExamples: const [],
      ),
    ];
  }

  static int _estimateConfidencePercent({
    required Map<String, dynamic> product,
    required List<String> ingredients,
    required String? userMarketCountry,
    required String marketCountrySource,
    required List<String> ranEvaluations,
    required bool usedModelOutput,
  }) {
    var score = usedModelOutput ? 74 : 56;

    if ((product["product_name"]?.toString().trim().isNotEmpty ?? false)) {
      score += 5;
    }
    if ((product["categories"]?.toString().trim().isNotEmpty ?? false)) {
      score += 6;
    }
    if (ingredients.isNotEmpty) {
      score += 8;
    }
    if (ingredients.length >= 4) {
      score += 3;
    }
    if (ranEvaluations.isNotEmpty) {
      score += 8;
    }
    if (ranEvaluations.length >= 2) {
      score += 4;
    }
    if (userMarketCountry != null && userMarketCountry.trim().isNotEmpty) {
      score += marketCountrySource == "geoip" ? 8 : 4;
    }

    return score.clamp(48, 94);
  }
}
