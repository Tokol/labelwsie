import '../rule_based_allergy_evaluation.dart';
import '../reason_based_allergy_evaluation.dart';

class AllergyEvaluation {
  final Map<String, dynamic> allergyPrefs;
  final List<String> ingredients;
  final List<String> additives;
  final List<String> productAllergens;

  AllergyEvaluation({
    required this.allergyPrefs,
    required this.ingredients,
    required this.additives,
    required this.productAllergens,
  });

  Future<Map<String, dynamic>> evaluate() async {
    // ==================================================
    // 1️⃣ RULE-BASED ENGINE (AUTHORITATIVE)
    // ==================================================
    final ruleEval = RuleBasedAllergyEvaluation(
      allergyPrefs: allergyPrefs,
      ingredients: ingredients,
      additives: additives,
      productAllergens: productAllergens,
    );

    final Map<String, dynamic> ruleOut = ruleEval.evaluate();
    final Map<String, dynamic> ruleResult =
    Map<String, dynamic>.from(ruleOut["result"]);

    final String ruleStatus = ruleResult["status"];
    final bool ruleIsSafe = ruleResult["isSafe"] == true;

    // ==================================================
    // 2️⃣ REASON-BASED ENGINE (SEMANTIC, NON-AUTHORITATIVE)
    // ==================================================
    Map<String, dynamic>? reasonResult;

    try {
      final reasonEval = ReasonBasedAllergyEval(
        allergyPrefs: allergyPrefs,
        ingredients: ingredients,
        additives: additives,
      );

      final Map<String, dynamic> reasonOut = await reasonEval.evaluate();
      reasonResult = Map<String, dynamic>.from(reasonOut["result"]);
    } catch (_) {
      // LLM failure → ignore safely
      reasonResult = null;
    }

    // ==================================================
    // 3️⃣ FINAL SUMMARY (RULE-BASED DOMINATES)
    // ==================================================
    final bool isSafe = ruleIsSafe;
    final String finalStatus = ruleIsSafe
        ? (reasonResult != null && reasonResult["status"] == "warning"
        ? "warning"
        : "safe")
        : "unsafe";

    final String confidence = ruleIsSafe
        ? (finalStatus == "safe" ? "high" : "medium")
        : "high";

    // ==================================================
    // 4️⃣ FINAL MERGED RESULT
    // ==================================================
    return {
      "result": {
        "domain": "allergy",

        // ---------------------------
        // SUMMARY (ONE-GLANCE)
        // ---------------------------
        "summary": {
          "status": finalStatus,
          "isSafe": isSafe,
          "confidence": confidence,
        },

        // ---------------------------
        // RULE-BASED (NEVER OMITTED)
        // ---------------------------
        "rule_based": {
          "engine": {
            "type": "rule",
            "source": "Rule Based Engine",
          },
          "status": ruleResult["status"],
          "isSafe": ruleResult["isSafe"],
          "confidence": ruleResult["confidence"],
          "message": ruleResult["message"],
          "matched": ruleResult["matched"],
          "summary": ruleResult["summary"],
        },

        // ---------------------------
        // REASON-BASED (OPTIONAL)
        // ---------------------------
        if (reasonResult != null)
          "reason_based": {
            "engine": {
              "type": "llm",
              "source": "Reasoning Based Engine",
            },
            "status": reasonResult["status"],
            "isSafe": reasonResult["isSafe"],
            "confidence": reasonResult["confidence"],
            "message": reasonResult["message"],
            "ingredients": reasonResult["ingredients"],
            "additives": reasonResult["additives"],
          },
      }
    };
  }
}
