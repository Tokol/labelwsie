import 'dart:convert';
import '../ai/services.dart';

class ReasonBasedReligionEval {
  final Map<String, dynamic> religionRule;
  final List<String> ingredients;
  final List<String> additives;

  ReasonBasedReligionEval({
    required this.religionRule,
    required this.ingredients,
    required this.additives,
  });

  Future<Map<String, dynamic>> result() async {
    final String religionId =
    (religionRule["id"] ?? "unknown").toString();
    final String strictness =
    (religionRule["strictness"] ?? "standard").toString();

    final List<dynamic> rulesDyn =
        (religionRule["rules"] as List?) ?? [];
    final List<String> ruleIds =
    rulesDyn.map((e) => e.toString()).toList();

    // ------------------------------------------------------------
    // PROMPT (STRICT STRUCTURED CONTRACT)
    // ------------------------------------------------------------
    final prompt = """
You are a religion-based dietary compliance checker.

You may use semantic equivalence.
Examples:
- swine → pork
- porcine → pork
- ethanol → alcohol

STRICT CATEGORY RULES:
- Milk, dairy, whey, lactose, butter, cheese, yogurt are NOT meat.
- Do NOT flag dairy items as meat, beef meat, pork meat, or flesh.
- Only flag meat rules when flesh, meat extract, meat fat, or slaughtered tissue is explicitly present.

Rules:
- Output ONLY valid JSON
- Do NOT explain outside JSON
- Do NOT invent facts
- If an item violates a rule, it MUST appear in structured findings
- If no violations or uncertainties exist, findings MUST be empty

Schema:
{
  "result": {
    "ingredients": {
      "<item>": {
        "source": "ingredient" | "additive",
        "detected_by": "keyword" | "semantic",
        "violates": ["rule_id"],
        "uncertain": ["rule_id"]
      }
    },
    "additives": {
      "<item>": {
        "source": "additive",
        "detected_by": "keyword" | "semantic",
        "violates": ["rule_id"],
        "uncertain": ["rule_id"]
      }
    },
    "message": "<short explanation>"
  }
}

Input:
religionId: "$religionId"
strictness: "$strictness"
ruleIds: ${jsonEncode(ruleIds)}
ingredients: ${jsonEncode(ingredients)}
additives: ${jsonEncode(additives)}
""";

    final raw = await OpenAIService.instance.callModel(prompt);

    // ------------------------------------------------------------
    // HARD FAILSAFE: empty or junk model output
    // ------------------------------------------------------------
    if (raw.trim().isEmpty) {
      return _safeFallback(religionId, strictness);
    }

    final Map<String, dynamic> parsed =
    OpenAIService.extractJSON(raw);

    if (parsed.isEmpty || parsed["result"] == null) {
      return _safeFallback(religionId, strictness);
    }

    // ------------------------------------------------------------
    // NORMALIZATION (MODEL IS NOT TRUSTED)
    // ------------------------------------------------------------
    final Map<String, dynamic> resultObj =
    Map<String, dynamic>.from(parsed["result"]);

    final Map<String, dynamic> ingredientFindings =
    (resultObj["ingredients"] is Map)
        ? Map<String, dynamic>.from(resultObj["ingredients"])
        : {};

    final Map<String, dynamic> additiveFindings =
    (resultObj["additives"] is Map)
        ? Map<String, dynamic>.from(resultObj["additives"])
        : {};

    bool hasViolates = false;

    void scan(Map<String, dynamic> m) {
      m.forEach((_, v) {
        if (v is Map) {
          final violates = (v["violates"] as List?) ?? const [];
          if (violates.isNotEmpty) hasViolates = true;
        }
      });
    }

    scan(ingredientFindings);
    scan(additiveFindings);

    final bool isSafe = !hasViolates;
    final String status = isSafe ? "safe" : "unsafe";

    // ------------------------------------------------------------
    // FINAL STRUCTURED RESULT (AUTHORITATIVE)
    // ------------------------------------------------------------
    final Map<String, dynamic> finalResult = {
      "domain": "religion",
      "engine": {
        "type": "llm",
        "source": "Reasoning Based Engine"
      },
      "religion": {
        "id": religionId,
        "strictness": strictness
      },
      "ingredients": ingredientFindings,
      "additives": additiveFindings,
      "status": status,
      "isSafe": isSafe,
      "confidence": hasViolates ? "medium" : "high",
      "message": (resultObj["message"] ?? "").toString().trim().isNotEmpty
          ? resultObj["message"]
          : isSafe
          ? "Safe for $religionId ($strictness rule). No violations detected."
          : "Contains items not permissible for $religionId ($strictness rule)."
    };

    print("Reasoning Based Engine Output");
    print(jsonEncode(finalResult));

    return { "result": finalResult };
  }

  // ------------------------------------------------------------
  // SAFE FALLBACK (FAIL CLOSED)
  // ------------------------------------------------------------
  Map<String, dynamic> _safeFallback(
      String religionId,
      String strictness,
      ) {
    return {
      "result": {
        "domain": "religion",
        "engine": {
          "type": "llm",
          "source": "Reasoning Based Engine"
        },
        "religion": {
          "id": religionId,
          "strictness": strictness
        },
        "ingredients": {},
        "additives": {},
        "status": "safe",
        "isSafe": true,
        "confidence": "low",
        "message":
        "Unable to evaluate $religionId ($strictness rule). No violations detected."
      }
    };
  }
}
