import 'dart:convert';
import '../ai/services.dart';

class ReasonBasedReligionEval {
  final Map<String, dynamic> religionRule; // {id, strictness, rules:[...]}
  final List<String> ingredients; // translated ingredients
  final List<String> additives;   // extracted additives (E-numbers)

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
    // PROMPT
    // ------------------------------------------------------------
    final prompt = """
You are a dietary compliance checker for religion-based rules.

Task:
You will receive:
1) Religion id and strictness
2) A list of rule IDs (e.g. contains_pork, contains_alcohol)
3) Ingredients (food components)
4) Additives (E-numbers like E120, E471)

Evaluate BOTH ingredients and additives against the rule IDs.

For each detected item:
- Use "source": "ingredient" or "additive"
- "violates": strong evidence from name or common meaning
- "uncertain": ambiguous origin (e.g. gelatin source unknown)

If an item is not relevant to any rule, OMIT it entirely.

Return ONLY valid JSON in the schema below.

Schema:
{
  "result": {
    "religion": {"id": "...", "strictness": "..."},
    "ingredients": {
      "<item>": {
        "source": "ingredient" | "additive",
        "violates": ["rule_id"],
        "uncertain": ["rule_id"]
      }
    },
    "status": "safe" | "unsafe" | "maybe",
    "isSafe": true | false,
    "message": "<short user-facing explanation>",
    "source": "Reasoning Based Engine"
  }
}

Rules:
- status = "unsafe" if any item has non-empty violates
- status = "maybe" if no violates but at least one uncertain
- status = "safe" if ingredients object is empty
- isSafe = true only when status is "safe"
- Message must mention religion id and strictness
- Use ONLY provided rule IDs
- Do NOT invent facts or certifications

Input:
religionId: "$religionId"
strictness: "$strictness"
ruleIds: ${jsonEncode(ruleIds)}
ingredients: ${jsonEncode(ingredients)}
additives: ${jsonEncode(additives)}
""";

    final raw = await OpenAIService.instance.callModel(prompt);

    // ------------------------------------------------------------
    // FALLBACK: empty model response
    // ------------------------------------------------------------
    if (raw.trim().isEmpty) {
      return {
        "result": {
          "religion": {"id": religionId, "strictness": strictness},
          "ingredients": <String, dynamic>{},
          "status": "maybe",
          "isSafe": false,
          "message":
          "Unable to evaluate $religionId ($strictness rule).",
          "source": "Reasoning Based Engine",
        }
      };
    }

    // ------------------------------------------------------------
    // JSON EXTRACTION
    // ------------------------------------------------------------
    final Map<String, dynamic> parsed =
    OpenAIService.extractJSON(raw);

    if (parsed.isEmpty || parsed["result"] == null) {
      return {
        "result": {
          "religion": {"id": religionId, "strictness": strictness},
          "ingredients": <String, dynamic>{},
          "status": "maybe",
          "isSafe": false,
          "message":
          "Unable to parse evaluation for $religionId ($strictness rule).",
          "source": "Reasoning Based Engine",
        }
      };
    }

    // ------------------------------------------------------------
    // ENFORCE STATUS DETERMINISTICALLY
    // ------------------------------------------------------------
    final Map<String, dynamic> resultObj =
    Map<String, dynamic>.from(parsed["result"]);

    final Map<String, dynamic> items =
    (resultObj["ingredients"] is Map)
        ? Map<String, dynamic>.from(resultObj["ingredients"])
        : <String, dynamic>{};

    bool hasViolates = false;
    bool hasUncertain = false;

    items.forEach((_, v) {
      if (v is Map) {
        final violates = (v["violates"] as List?) ?? const [];
        final uncertain = (v["uncertain"] as List?) ?? const [];
        if (violates.isNotEmpty) hasViolates = true;
        if (uncertain.isNotEmpty) hasUncertain = true;
      }
    });

    String status;
    bool isSafe;

    if (items.isEmpty) {
      status = "safe";
      isSafe = true;
    } else if (hasViolates) {
      status = "unsafe";
      isSafe = false;
    } else {
      status = "maybe";
      isSafe = false;
    }

    // ------------------------------------------------------------
    // FINAL NORMALIZATION
    // ------------------------------------------------------------
    resultObj["religion"] = {
      "id": religionId,
      "strictness": strictness,
    };
    resultObj["ingredients"] = items;
    resultObj["status"] = status;
    resultObj["isSafe"] = isSafe;
    resultObj["source"] = "Reasoning Based Engine";

    if ((resultObj["message"] ?? "").toString().trim().isEmpty) {
      resultObj["message"] = isSafe
          ? "Safe for $religionId ($strictness rule). No concerns detected."
          : "For $religionId ($strictness rule), some ingredients or additives may violate or be uncertain.";
    }

    return {"result": resultObj};
  }
}
