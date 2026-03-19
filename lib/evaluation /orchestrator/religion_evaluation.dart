import '../rule_based_religion_evaluation.dart';
import '../reason_based_religion_evaluation.dart';
import 'llm_reasoning_schema_guard.dart';

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
    // ==================================================
    // 1️⃣ RULE-BASED ENGINE (AUTHORITATIVE GATE)
    // ==================================================
    final ruleEval = RuleBasedReligionEval(
      religionRule: religionRule,
      ingredients: ingredients,
      additives: additives,
    );

    final Map<String, dynamic> ruleOut = ruleEval.result();
    final Map<String, dynamic> ruleResult =
    Map<String, dynamic>.from(ruleOut["result"]);

    // 🔒 HARD STOP: deterministic violation
    if (ruleResult["status"] == "unsafe") {
      return ruleOut;
    }

    // ==================================================
    // 2️⃣ REASON-BASED ENGINE (SEMANTIC FALLBACK)
    // ==================================================
    final llmEval = ReasonBasedReligionEval(
      religionRule: religionRule,
      ingredients: ingredients,
      additives: additives,
    );

    Map<String, dynamic> llmOut;

    try {
      llmOut = validateReasoningResult(
        await llmEval.result(),
      );
    } catch (_) {
      // ❌ LLM invalid / contradictory
      // Fail closed → trust rule-based safe result
      return ruleOut;
    }

    final Map<String, dynamic> llmResult =
    Map<String, dynamic>.from(llmOut["result"]);

    final Map<String, dynamic> llmIngredients =
        (llmResult["ingredients"] as Map?)?.cast<String, dynamic>() ?? {};

    final Map<String, dynamic> llmAdditives =
        (llmResult["additives"] as Map?)?.cast<String, dynamic>() ?? {};

    final bool llmHasFindings =
        llmIngredients.isNotEmpty || llmAdditives.isNotEmpty;

    // 🔎 Semantic violation found → return LLM result
    if (llmHasFindings) {
      return {
        "result": {
          "domain": "religion",
          "engine": {
            "type": "llm",
            "source": "Reasoning Based Engine",
          },
          "religion": ruleResult["religion"],
          "ingredients": llmIngredients,
          "additives": llmAdditives,
          "status": "unsafe",
          "isSafe": false,
          "confidence": "medium",
          "message": llmResult["message"] ??
              "Contains items not permissible for "
                  "${ruleResult["religion"]["id"]} "
                  "(${ruleResult["religion"]["strictness"]} rule).",
        }
      };
    }

    // ==================================================
    // 3️⃣ BOTH ENGINES PASSED (TRUE HYBRID SAFE)
    // ==================================================
    return {
      "result": {
        "domain": "religion",
        "engine": {
          "type": "hybrid",
          "source": [
            "Rule Based Engine",
            "Reasoning Based Engine",
          ],
        },
        "religion": ruleResult["religion"],
        "ingredients": {},
        "additives": {},
        "status": "safe",
        "isSafe": true,
        "confidence": "high",
        "message":
        "Safe for ${ruleResult["religion"]["id"]} "
            "(${ruleResult["religion"]["strictness"]} rule). "
            "No violations detected.",
      }
    };
  }
}
