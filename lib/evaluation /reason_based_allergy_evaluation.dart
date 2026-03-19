import 'dart:convert';
import '../ai/services.dart';
import '../diet_pref/restriction_definitions.dart';

class ReasonBasedAllergyEval {
  final Map<String, dynamic> allergyPrefs;
  final List<String> ingredients;
  final List<String> additives;

  ReasonBasedAllergyEval({
    required this.allergyPrefs,
    required this.ingredients,
    required this.additives,
  });

  /// ------------------------------------------------------------
  /// MAIN ENTRY
  /// ------------------------------------------------------------
  Future<Map<String, dynamic>> evaluate() async {
    // --------------------------------------------------
    // USER-DEFINED ALLERGIES & SENSITIVITIES ONLY
    // --------------------------------------------------
    final List<Map<String, dynamic>> userAllergens =
    ((allergyPrefs["allergens"] ?? []) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final List<String> sensitivities =
    ((allergyPrefs["sensitivities"] ?? []) as List).cast<String>();
    final List<String> custom =
    ((allergyPrefs["custom"] ?? []) as List).cast<String>();

    if (userAllergens.isEmpty && sensitivities.isEmpty && custom.isEmpty) {
      return _safeFallback();
    }

    // --------------------------------------------------
    // INPUT FOR LLM (STRICTLY NO PRODUCT ALLERGENS)
    // --------------------------------------------------
    final input = {
      "user_allergies": userAllergens
          .map((a) => {
                "id": a["id"],
                "title": a["title"],
                "restriction": a["restriction"],
                "examples": (restrictionDefinitions[a["restriction"]]?.examples ?? const <String>[]),
              })
          .toList(),
      "user_sensitivities": sensitivities
          .map((s) => {
                "id": s,
                "title": s,
                "examples": _sensitivityExamples(s),
              })
          .toList(),
      "user_custom_keywords": custom
          .map((c) => {
                "id": c,
                "title": c,
              })
          .toList(),
      "ingredients": ingredients,
      "additives": additives,
    };

    // --------------------------------------------------
    // PROMPT (STRICT + LABELED OUTPUT)
    // --------------------------------------------------
    final prompt = """
You are an allergy reasoning assistant.

STRICT SAFETY RULES (NON-NEGOTIABLE):

1. You MUST NEVER invent allergens.
2. You MUST ONLY analyze the provided ingredients and additives.
3. You MUST ONLY consider user-declared allergies, sensitivities, and custom keywords.
4. A violation is allowed ONLY when the relationship is
   medically well-known and unambiguous.
5. You MUST inspect every ingredient and every additive individually.
6. If a custom keyword directly appears inside an ingredient or additive name,
   you MUST flag it.
7. If a sensitivity label directly appears inside an ingredient or additive name,
   you MUST return at least an "uncertain" finding.

ALLOWED semantic examples:
- whey → milk
- casein → milk
- lactose → milk
- malt → gluten
- barley extract → gluten
- shellfish extract → crustaceans
- onion powder → onion
- artificial color → food colorings
- food colour → food colorings
- yellow 5 / E102 / E110 / colorant → food colorings

DISALLOWED behavior:
- Guessing allergen origin
- Treating generic processing terms as allergens
- Confirming allergies without evidence
- Escalating uncertainty to violation

OUTPUT RULES:
- Clear relationship → violation
- Plausible but unclear → uncertain
- No relationship → do nothing
- For each finding, specify whether it relates to a user
  allergy ("allergy"), a sensitivity ("sensitivity"), or a custom keyword ("custom").
- If a user allergy object has a title, copy that same title into the output.
- For sensitivities and custom keywords, set title to the exact matched user label.
- Use the provided examples to connect user labels to ingredients/additives.
- If an ingredient clearly matches a custom keyword (for example onion -> onion powder),
  return that as either a "violation" or "uncertain" finding instead of ignoring it.
- If an additive clearly matches a custom keyword or sensitivity label, do the same.
- For every ingredient and additive, decide whether it matches any user allergy,
  sensitivity, or custom keyword before returning the result.

Return ONLY valid JSON.

Schema:
{
  "result": {
    "ingredients": {
      "<item>": {
        "violations": [
          { "id": "<allergen_id_or_keyword>", "title": "<display_title>", "type": "allergy|sensitivity|custom" }
        ],
        "uncertain": [
          { "id": "<allergen_id_or_keyword>", "title": "<display_title>", "type": "allergy|sensitivity|custom" }
        ]
      }
    },
    "additives": {
      "<item>": {
        "violations": [
          { "id": "<allergen_id_or_keyword>", "title": "<display_title>", "type": "allergy|sensitivity|custom" }
        ],
        "uncertain": [
          { "id": "<allergen_id_or_keyword>", "title": "<display_title>", "type": "allergy|sensitivity|custom" }
        ]
      }
    },
    "message": "<short explanation>"
  }
}

Input:
${jsonEncode(input)}
""";

    final raw = await OpenAIService.instance.callModel(prompt);

    if (raw.trim().isEmpty) {
      return _safeFallback();
    }

    final parsed = OpenAIService.extractJSON(raw);
    if (parsed.isEmpty || parsed["result"] == null) {
      return _safeFallback();
    }

    // --------------------------------------------------
    // NORMALIZE OUTPUT
    // --------------------------------------------------
    final Map<String, dynamic> result =
    Map<String, dynamic>.from(parsed["result"]);

    final Map<String, dynamic> ingredientsOut =
    (result["ingredients"] is Map)
        ? Map<String, dynamic>.from(result["ingredients"])
        : {};

    final Map<String, dynamic> additivesOut =
    (result["additives"] is Map)
        ? Map<String, dynamic>.from(result["additives"])
        : {};

    bool hasViolation = false;
    bool hasUncertain = false;

    void scan(Map<String, dynamic> m) {
      for (final v in m.values) {
        if (v is Map) {
          final List violations = (v["violations"] as List?) ?? [];
          final List uncertain = (v["uncertain"] as List?) ?? [];

          if (violations.isNotEmpty) hasViolation = true;
          if (uncertain.isNotEmpty) hasUncertain = true;
        }
      }
    }

    scan(ingredientsOut);
    scan(additivesOut);

    // --------------------------------------------------
    // FINAL STATUS
    // --------------------------------------------------
    final String status = hasViolation
        ? "unsafe"
        : hasUncertain
        ? "warning"
        : "safe";

    final bool isSafe = !hasViolation;

    return {
      "result": {
        "domain": "allergy",
        "engine": {
          "type": "llm",
          "source": "Reasoning Based Engine",
        },
        "ingredients": ingredientsOut,
        "additives": additivesOut,
        "status": status,
        "isSafe": isSafe,
        "confidence": hasViolation
            ? "medium"
            : hasUncertain
            ? "medium"
            : "high",
        "message": (result["message"] ?? "").toString().trim().isNotEmpty
            ? result["message"]
            : hasViolation
            ? "Potential allergy risks detected based on ingredient analysis."
            : hasUncertain
            ? "Some ingredients may be uncertain for your allergies."
            : "No semantic allergy risks detected.",
      }
    };
  }

  // ------------------------------------------------------------
  // SAFE FALLBACK
  // ------------------------------------------------------------
  Map<String, dynamic> _safeFallback() {
    return {
      "result": {
        "domain": "allergy",
        "engine": {
          "type": "llm",
          "source": "Reasoning Based Engine",
        },
        "ingredients": {},
        "additives": {},
        "status": "safe",
        "isSafe": true,
        "confidence": "low",
        "message":
        "Unable to fully evaluate semantic allergy risks. No issues detected.",
      }
    };
  }

  List<String> _sensitivityExamples(String value) {
    final normalized = value.toLowerCase().trim();

    if (normalized.contains("food color")) {
      return const [
        "food color",
        "food coloring",
        "food colour",
        "color",
        "colour",
        "coloring",
        "colouring",
        "artificial color",
        "artificial colours",
        "yellow 5",
        "yellow 6",
        "e102",
        "e110",
        "e120",
      ];
    }

    return [value];
  }
}
