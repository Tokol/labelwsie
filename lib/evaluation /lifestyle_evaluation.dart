import 'dart:convert';

import '../ai/services.dart';
import '../diet_pref/restriction_definitions.dart';

class LifestyleEvaluation {
  final List<Map<String, dynamic>> lifestyleGoals;
  final List<String> ingredients;
  final List<String> additives;
  final Map<String, double> nutriments;
  final Map<String, String> nutrientLevels;
  final int? novaGroup;
  final String? nutriScore;

  LifestyleEvaluation({
    required this.lifestyleGoals,
    required this.ingredients,
    required this.additives,
    required this.nutriments,
    required this.nutrientLevels,
    required this.novaGroup,
    required this.nutriScore,
  });

  // ============================================================
  // MAIN ENTRY
  // ============================================================

  Future<Map<String, dynamic>> evaluate() async {
    final goals = _normalizeGoals(lifestyleGoals);
    if (goals.isEmpty) return _safeFallback();

    final input = {
      "lifestyle_goals": goals,
      "ingredients": ingredients,
      "additives": additives,
      "nutriments": nutriments,
      "nutrient_levels": nutrientLevels,
      "nova_group": novaGroup,
      "nutriscore": nutriScore,
    };

    final raw = await OpenAIService.instance.callModel(_buildPrompt(input));

    if (raw.trim().isEmpty) return _safeFallback();

    final parsed = OpenAIService.extractJSON(raw);
    if (parsed.isEmpty || parsed["result"] == null) {
      return _safeFallback();
    }

    return _normalizeOutput(parsed["result"]);
  }

  // ============================================================
  // NORMALIZE GOALS
  // ============================================================

  List<Map<String, dynamic>> _normalizeGoals(List<Map<String, dynamic>> goals) {
    final List<Map<String, dynamic>> out = [];

    for (final g in goals) {
      final String id = (g["id"] ?? "").toString().trim();
      final String title = (g["title"] ?? id).toString().trim();
      final String subtitle = (g["subtitle"] ?? "").toString().trim();
      final String type = (g["type"] ?? "").toString().trim();

      if (id.isEmpty || type.isEmpty) continue;
      if (type != "restriction" && type != "awareness") continue;

      final List<String> restrictionIds = ((g["restrictions"] ?? []) as List)
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();

      final List<Map<String, dynamic>> enrichedRestrictions = [];

      if (type == "restriction") {
        for (final rid in restrictionIds) {
          final def = restrictionDefinitions[rid];
          if (def != null) {
            enrichedRestrictions.add({
              "id": def.id,
              "title": def.title,
              "description": def.description,
              "examples": def.examples,
            });
          } else {
            enrichedRestrictions.add({
              "id": rid,
              "title": rid,
              "description": "",
              "examples": <String>[],
            });
          }
        }
      }

      out.add({
        "id": id,
        "title": title,
        "subtitle": subtitle,
        "type": type,
        "restrictions": enrichedRestrictions,
      });
    }

    return out;
  }

  // ============================================================
  // PROMPT
  // ============================================================

  String _buildPrompt(Map<String, dynamic> input) {
    return """
You are a dietary lifestyle reasoning assistant.

Your task is to evaluate how well a packaged food product aligns with the user's selected lifestyle goals.

CRITICAL RULES:
- You MUST reason ONLY from the provided data.
- You MUST NOT invent ingredients, nutrients, or hidden processing details.
- You MUST NOT diagnose health conditions.
- You MUST distinguish strictly between TWO goal types:
  1. restriction
  2. awareness

SEMANTIC RULES:
- restriction goals represent things the user wants to avoid.
- awareness goals represent things the user wants more of or wants to optimize.
- awareness goals MUST NEVER produce "warning", "violation", "unsafe", or "restricted".
- awareness goals ONLY produce alignment:
  - strong
  - moderate
  - weak

FOR RESTRICTION GOALS:
- You may return only:
  - aligned
  - warning
  - violation
- Use "violation" when the ingredient/additive/nutritional evidence clearly conflicts with the goal.
- Use "warning" when there is plausible or moderate conflict, but not fully explicit.
- Use "aligned" when there is no meaningful conflict from the provided data.

FOR AWARENESS GOALS:
- You may return only:
  - strong
  - moderate
  - weak
- Base awareness reasoning mainly on nutriments, nutrient_levels, ingredients, additives, nova_group, and nutriscore.
- Do NOT use warnings or violations for awareness goals.

IMPORTANT:
- Restriction goals use the provided restriction definitions and examples as semantic hints.
- You may reason semantically from ingredient names, additive codes, nutrient profile, nutrient levels, nova group, and nutriscore.
- If evidence is weak, choose the less aggressive label.
- Lifestyle evaluation is about alignment, not medical safety.

Return ONLY valid JSON.

Schema:
{
  "result": {
    "restriction_results": {
      "<goal_id>": {
        "goal_title": "<title>",
        "status": "aligned | warning | violation",
        "triggered_restrictions": [
          {
            "restriction_id": "<restriction_id>",
            "restriction_title": "<restriction_title>",
            "reason": "<short reason>"
          }
        ]
      }
    },
    "awareness_results": {
      "<goal_id>": {
        "goal_title": "<title>",
        "alignment": "strong | moderate | weak",
        "reason": "<short reason>"
      }
    },
    "message": "<short explanation>"
  }
}

Input:
${jsonEncode(input)}
""";
  }

  // ============================================================
  // NORMALIZE OUTPUT
  // ============================================================

  Map<String, dynamic> _normalizeOutput(Map<String, dynamic> result) {
    final Map<String, dynamic> restrictionResults =
    result["restriction_results"] is Map
        ? Map<String, dynamic>.from(result["restriction_results"])
        : {};

    final Map<String, dynamic> awarenessResults =
    result["awareness_results"] is Map
        ? Map<String, dynamic>.from(result["awareness_results"])
        : {};

    final normalizedRestrictionResults =
    _normalizeRestrictionResults(restrictionResults);

    final normalizedAwarenessResults =
    _normalizeAwarenessResults(awarenessResults);

    final summary = _buildSummary(
      normalizedRestrictionResults,
      normalizedAwarenessResults,
    );

    return {
      "result": {
        "domain": "lifestyle",
        "engine": {
          "type": "llm",
          "source": "Lifestyle Reasoning Engine",
        },
        "restriction_results": normalizedRestrictionResults,
        "awareness_results": normalizedAwarenessResults,
        "summary": summary,
        "message": result["message"] ??
            "Lifestyle evaluation completed based on selected goals.",
      }
    };
  }

  // ============================================================
  // NORMALIZE RESTRICTION RESULTS
  // ============================================================

  Map<String, dynamic> _normalizeRestrictionResults(
      Map<String, dynamic> input) {
    final Map<String, dynamic> out = {};

    for (final entry in input.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is! Map) continue;

      final rawStatus = (value["status"] ?? "aligned").toString().trim();
      final status = _normalizeRestrictionStatus(rawStatus);

      final rawTriggered = (value["triggered_restrictions"] as List?) ?? [];

      final List<Map<String, dynamic>> triggered = [];

      for (final item in rawTriggered) {
        if (item is! Map) continue;

        final restrictionId =
        (item["restriction_id"] ?? "").toString().trim();
        final restrictionTitle =
        (item["restriction_title"] ?? restrictionId).toString().trim();
        final reason = (item["reason"] ?? "").toString().trim();

        if (restrictionId.isEmpty) continue;

        triggered.add({
          "restriction_id": restrictionId,
          "restriction_title": restrictionTitle,
          "reason": reason,
        });
      }

      out[key] = {
        "goal_title": (value["goal_title"] ?? key).toString(),
        "status": status,
        "triggered_restrictions": triggered,
      };
    }

    return out;
  }

  String _normalizeRestrictionStatus(String raw) {
    switch (raw.toLowerCase()) {
      case "violation":
        return "violation";
      case "warning":
        return "warning";
      case "aligned":
        return "aligned";
      default:
        return "aligned";
    }
  }

  // ============================================================
  // NORMALIZE AWARENESS RESULTS
  // ============================================================

  Map<String, dynamic> _normalizeAwarenessResults(Map<String, dynamic> input) {
    final Map<String, dynamic> out = {};

    for (final entry in input.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is! Map) continue;

      final rawAlignment = (value["alignment"] ?? "weak").toString().trim();
      final alignment = _normalizeAwarenessAlignment(rawAlignment);

      out[key] = {
        "goal_title": (value["goal_title"] ?? key).toString(),
        "alignment": alignment,
        "reason": (value["reason"] ?? "").toString(),
      };
    }

    return out;
  }

  String _normalizeAwarenessAlignment(String raw) {
    switch (raw.toLowerCase()) {
      case "strong":
        return "strong";
      case "moderate":
        return "moderate";
      case "weak":
        return "weak";
      default:
        return "weak";
    }
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Map<String, dynamic> _buildSummary(
      Map<String, dynamic> restrictionResults,
      Map<String, dynamic> awarenessResults,
      ) {
    int restrictionViolations = 0;
    int restrictionWarnings = 0;
    int restrictionAligned = 0;

    int awarenessStrong = 0;
    int awarenessModerate = 0;
    int awarenessWeak = 0;

    for (final v in restrictionResults.values) {
      if (v is! Map) continue;
      final status = (v["status"] ?? "").toString();

      if (status == "violation") {
        restrictionViolations++;
      } else if (status == "warning") {
        restrictionWarnings++;
      } else if (status == "aligned") {
        restrictionAligned++;
      }
    }

    for (final v in awarenessResults.values) {
      if (v is! Map) continue;
      final alignment = (v["alignment"] ?? "").toString();

      if (alignment == "strong") {
        awarenessStrong++;
      } else if (alignment == "moderate") {
        awarenessModerate++;
      } else if (alignment == "weak") {
        awarenessWeak++;
      }
    }

    final String overallRestrictionStatus = restrictionViolations > 0
        ? "violation"
        : restrictionWarnings > 0
        ? "warning"
        : restrictionResults.isEmpty
        ? "none"
        : "aligned";

    return {
      "restriction_overall_status": overallRestrictionStatus,
      "restriction_goal_counts": {
        "violation": restrictionViolations,
        "warning": restrictionWarnings,
        "aligned": restrictionAligned,
      },
      "awareness_goal_counts": {
        "strong": awarenessStrong,
        "moderate": awarenessModerate,
        "weak": awarenessWeak,
      },
    };
  }

  // ============================================================
  // SAFE FALLBACK
  // ============================================================

  Map<String, dynamic> _safeFallback() {
    return {
      "result": {
        "domain": "lifestyle",
        "engine": {
          "type": "llm",
          "source": "Lifestyle Reasoning Engine",
        },
        "restriction_results": {},
        "awareness_results": {},
        "summary": {
          "restriction_overall_status": "none",
          "restriction_goal_counts": {
            "violation": 0,
            "warning": 0,
            "aligned": 0,
          },
          "awareness_goal_counts": {
            "strong": 0,
            "moderate": 0,
            "weak": 0,
          },
        },
        "message":
        "Insufficient information to evaluate lifestyle goals.",
      }
    };
  }
}