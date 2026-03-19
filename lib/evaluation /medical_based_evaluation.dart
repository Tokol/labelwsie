import 'dart:convert';
import '../ai/services.dart';

class ReasonBasedMedicalEvaluation {
  final List<Map<String, dynamic>> medicalPrefs;
  final List<String> ingredients;
  final List<String> additives;
  final Map<String, double> nutriments;
  final Map<String, String> nutrientLevels;
  final int? novaGroup;
  final String? nutriScore;

  ReasonBasedMedicalEvaluation({
    required this.medicalPrefs,
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
    final conditions = _flattenMedicalConditions(medicalPrefs);
    if (conditions.isEmpty) return _safeFallback();

    final input = {
      "medical_conditions": conditions,
      "ingredients": ingredients,
      "additives": additives,
      "nutriments": nutriments,
      "nutrient_levels": nutrientLevels,
      "nova_group": novaGroup,
      "nutriscore": nutriScore,
    };

    final raw =
    await OpenAIService.instance.callModel(_buildPrompt(input));

    if (raw.trim().isEmpty) return _safeFallback();

    final parsed = OpenAIService.extractJSON(raw);
    if (parsed.isEmpty || parsed["result"] == null) {
      return _safeFallback();
    }

    return _normalizeOutput(parsed["result"]);
  }

  // ============================================================
  // FLATTEN MEDICAL STRUCTURE
  // ============================================================
  List<Map<String, dynamic>> _flattenMedicalConditions(
      List<Map<String, dynamic>> prefs) {
    final List<Map<String, dynamic>> out = [];

    for (final cat in prefs) {
      final String categoryId = cat["category"]?["id"] ?? "";
      final String categoryLabel = cat["category"]?["label"] ?? categoryId;

      final List diseases = (cat["diseases"] ?? []) as List;
      for (final d in diseases) {
        String conditionLabel = d["label"] ?? d["id"];

        // Pregnancy / prenatal / parental collapse
        if (categoryId == "pregnancy" ||
            categoryId == "prenatal" ||
            categoryId == "parental") {
          conditionLabel = categoryLabel;
        }

        out.add({
          "category": categoryLabel,
          "condition": conditionLabel,
          "restrictions": (d["restrictions"] ?? []) as List,
        });
      }
    }
    return out;
  }

  // ============================================================
  // PROMPT (SEMANTIC ANCHORED — THIS IS THE KEY FIX)
  // ============================================================
  String _buildPrompt(Map<String, dynamic> input) {
    return """
You are a medical dietary reasoning assistant.

CRITICAL RULES:
- You MUST NOT diagnose disease.
- You MUST NOT use numeric thresholds.
- You MUST reason ONLY from provided data.
- Restrictions represent dietary cautions, not diagnoses.
- Use condition LABELS only.

MANDATORY SEMANTIC ANCHORING RULE:
If a restriction explicitly references a compound or nutrient
(e.g. oxalate, sodium, sugar, mercury),
and an ingredient, additive, or nutrient in the data is
commonly associated with that concept,
you MUST emit an UNCERTAIN finding.
You MUST NOT mark it as a violation unless evidence is explicit.

ANALYZE ALL OF:
- ingredients
- additives
- nutriments
- nutrient_levels
- nutriscore
- nova_group

OUTPUT RULES:
- Clear evidence → violation
- Plausible semantic relevance → UNCERTAIN
- No plausible relevance → omit
- If ANY plausible relevance exists, DO NOT return cannot_assess

Return ONLY valid JSON.

Schema:
{
  "result": {
    "ingredients": {
      "<item>": {
        "violations": [],
        "uncertain": [
          {
            "restriction": "<restriction>",
            "conditions": ["<condition_label>"]
          }
        ]
      }
    },
    "nutriments": {},
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
    final Map<String, dynamic> ingredientsOut =
    result["ingredients"] is Map
        ? Map<String, dynamic>.from(result["ingredients"])
        : {};

    final Map<String, dynamic> nutrimentsOut =
    result["nutriments"] is Map
        ? Map<String, dynamic>.from(result["nutriments"])
        : {};

    final affectedConditions =
    _buildAffectedConditions(ingredientsOut, nutrimentsOut);

    final bool hasViolation =
    affectedConditions.values.any((v) => v["status"] == "violation");
    final bool hasWarning =
    affectedConditions.values.any((v) => v["status"] == "warning");

    final bool nothingAssessed = affectedConditions.isEmpty;

    final String status = nothingAssessed
        ? "cannot_assess"
        : hasViolation
        ? "unsafe"
        : hasWarning
        ? "warning"
        : "safe";

    return {
      "result": {
        "domain": "medical",
        "engine": {
          "type": "llm",
          "source": "Reasoning Based Engine",
        },
        "ingredients": ingredientsOut,
        "nutriments": nutrimentsOut,
        "affected_conditions": affectedConditions,
        "status": status,
        "isSafe": !hasViolation,
        "confidence":
        hasViolation || hasWarning ? "medium" : "high",
        "message": result["message"] ??
            (status == "warning"
                ? "Possible dietary cautions detected based on medical preferences."
                : status == "unsafe"
                ? "Dietary concerns detected for selected medical conditions."
                : "No medical dietary concerns detected."),
      }
    };
  }

  // ============================================================
  // BUILD AFFECTED CONDITIONS
  // ============================================================
  Map<String, Map<String, dynamic>> _buildAffectedConditions(
      Map<String, dynamic> ingredients,
      Map<String, dynamic> nutriments) {
    final Map<String, Map<String, dynamic>> out = {};

    void collect(Map<String, dynamic> section) {
      for (final v in section.values) {
        if (v is! Map) continue;

        for (final key in ["violations", "uncertain"]) {
          final List entries = (v[key] as List?) ?? [];
          for (final e in entries) {
            final List conditions = (e["conditions"] as List?) ?? [];
            final String restriction = e["restriction"];

            for (final c in conditions) {
              out.putIfAbsent(c, () => {
                "status":
                key == "violations" ? "violation" : "warning",
                "restrictions": <String>{},
              });

              out[c]!["restrictions"].add(restriction);
            }
          }
        }
      }
    }

    collect(ingredients);
    collect(nutriments);

    for (final v in out.values) {
      v["restrictions"] =
          (v["restrictions"] as Set).toList();
    }

    return out;
  }

  // ============================================================
  // SAFE FALLBACK
  // ============================================================
  Map<String, dynamic> _safeFallback() {
    return {
      "result": {
        "domain": "medical",
        "engine": {
          "type": "llm",
          "source": "Reasoning Based Engine",
        },
        "ingredients": {},
        "nutriments": {},
        "affected_conditions": {},
        "status": "cannot_assess",
        "isSafe": true,
        "confidence": "low",
        "message":
        "Insufficient information to assess medical dietary restrictions.",
      }
    };
  }
}
