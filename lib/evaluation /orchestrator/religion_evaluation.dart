import '../reason_based_religion_evaluation.dart';
import '../rule_based_religion_evaluation.dart';

class ReligionEvaluation {
  final Map<String, dynamic> religionRule;
  final List<String> ingredients;
  final List<String> additives;

  ReligionEvaluation({
    required this.religionRule,
    required this.ingredients,
    required this.additives,
  });

  Future<Map<String, dynamic>> evaluate() async {
    final religionId = (religionRule["id"] ?? "unknown").toString();
    final strictness = (religionRule["strictness"] ?? "standard").toString();

    // --------------------------------------------------
    // 1️⃣ RULE BASED ENGINE (FIRST & FINAL IF HIT)
    // --------------------------------------------------
    final ruleEval = RuleBasedReligionEval(
      religionRule: religionRule,
      ingredients: ingredients,
      additives: additives,
    );

    final ruleOut = ruleEval.result();
    final ruleResult = Map<String, dynamic>.from(ruleOut["result"] ?? {});
    final ruleStatus = ruleResult["status"];

    if (ruleStatus == "unsafe") {
      return {
        "result": {
          "domain": "religion",
          "engine": {
            "type": "rule",
            "sources": ["Rule Based Engine"]
          },
          "religion": {
            "id": religionId,
            "strictness": strictness
          },
          "status": "unsafe",
          "isSafe": false,
          "score": 100,
          "confidence": "high",
          "findings": ruleResult["ingredients"] ?? {},
          "message": ruleResult["message"],
          "explanation":
          "Violation detected using deterministic rule matching."
        }
      };
    }

    // --------------------------------------------------
    // 2️⃣ REASONING ENGINE (LLM)
    // --------------------------------------------------
    final llmEval = ReasonBasedReligionEval(
      religionRule: religionRule,
      ingredients: ingredients,
      additives: additives,
    );

    final llmOut = await llmEval.result();
    final llmResult = Map<String, dynamic>.from(llmOut["result"] ?? {});

    // 🔑 IMPORTANT: collect BOTH ingredients + additives
    final Map<String, dynamic> llmFindings = {
      ...(llmResult["ingredients"] is Map
          ? llmResult["ingredients"]
          : {}),
      ...(llmResult["additives"] is Map
          ? llmResult["additives"]
          : {}),
    };

    if (llmFindings.isNotEmpty) {
      return {
        "result": {
          "domain": "religion",
          "engine": {
            "type": "llm",
            "sources": ["Reasoning Based Engine"]
          },
          "religion": {
            "id": religionId,
            "strictness": strictness
          },
          "status": "unsafe",
          "isSafe": false,
          "score": 100,
          "confidence": "medium",
          "findings": llmFindings,
          "message": llmResult["message"],
          "explanation":
          "Violation detected using semantic reasoning."
        }
      };
    }

    // --------------------------------------------------
    // 3️⃣ BOTH ENGINES FOUND NOTHING
    // --------------------------------------------------
    return {
      "result": {
        "domain": "religion",
        "engine": {
          "type": "hybrid",
          "sources": ["Rule Based Engine", "Reasoning Based Engine"]
        },
        "religion": {
          "id": religionId,
          "strictness": strictness
        },
        "status": "safe",
        "isSafe": true,
        "score": 100,
        "confidence": "high",
        "findings": {},
        "message":
        "Safe for $religionId ($strictness rule). No violations detected.",
        "explanation":
        "No violations found by rule-based or reasoning-based evaluation."
      }
    };
  }
}
