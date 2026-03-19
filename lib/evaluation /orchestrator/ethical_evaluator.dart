import '../reason_based_ethical_evaluation.dart';
import '../rule_based_ethical_evaluation.dart';
import 'llm_ethical_schema_guard.dart';

class EthicalEvaluation {
  final List<Map<String, dynamic>> ethicalPrefs;
  final List<String> ingredients;
  final List<String> additives;

  EthicalEvaluation({
    required this.ethicalPrefs,
    required this.ingredients,
    required this.additives,
  });

  Future<Map<String, dynamic>> evaluate() async {
    // ==================================================
    // 1️⃣ RULE-BASED ENGINE (DETERMINISTIC)
    // ==================================================
    final ruleEval = RuleBasedEthicalEval(
      ethicalPrefs: ethicalPrefs,
      ingredients: ingredients,
      additives: additives,
    );

    final Map<String, dynamic> ruleOut = ruleEval.result();
    final Map<String, dynamic> ruleResult =
    Map<String, dynamic>.from(ruleOut["result"]);

    final Map<String, dynamic> ruleIngredients =
        (ruleResult["ingredients"] as Map?)?.cast<String, dynamic>() ?? {};

    final Map<String, dynamic> ruleAdditives =
        (ruleResult["additives"] as Map?)?.cast<String, dynamic>() ?? {};

    final bool ruleHasFindings =
        ruleIngredients.isNotEmpty || ruleAdditives.isNotEmpty;

    // ==================================================
    // 2️⃣ REASON-BASED ENGINE (SEMANTIC)
    // ==================================================
    Map<String, dynamic> llmIngredients = {};
    Map<String, dynamic> llmAdditives = {};
    bool llmHasFindings = false;

    try {
      final llmEval = ReasonBasedEthicalEval(
        ethicalPrefs: ethicalPrefs,
        ingredients: ingredients,
        additives: additives,
      );

      final llmOut = validateReasoningResult(
        await llmEval.result(),
      );

      final llmResult =
      Map<String, dynamic>.from(llmOut["result"]);

      llmIngredients =
          (llmResult["ingredients"] as Map?)?.cast<String, dynamic>() ?? {};

      llmAdditives =
          (llmResult["additives"] as Map?)?.cast<String, dynamic>() ?? {};

      llmHasFindings =
          llmIngredients.isNotEmpty || llmAdditives.isNotEmpty;
    } catch (_) {
      // LLM failed → ignore semantic layer safely
    }

    // ==================================================
    // 3️⃣ MERGE FINDINGS
    // ==================================================
    final Map<String, dynamic> mergedIngredients = {
      ...ruleIngredients,
      ...llmIngredients,
    };

    final Map<String, dynamic> mergedAdditives = {
      ...ruleAdditives,
      ...llmAdditives,
    };

    final bool isSafe =
        mergedIngredients.isEmpty && mergedAdditives.isEmpty;

    // ==================================================
    // 4️⃣ FINAL RESULT
    // ==================================================
    return {
      "result": {
        "domain": "ethical",
        "engine": {
          "type": isSafe
              ? "hybrid"
              : (ruleHasFindings && llmHasFindings)
              ? "hybrid"
              : ruleHasFindings
              ? "rule"
              : "llm",
          "source": [
            if (ruleHasFindings) "Rule Based Engine",
            if (llmHasFindings) "Reasoning Based Engine",
          ],
        },
        "preferences": ethicalPrefs.map((e) => e["id"]).toList(),
        "ingredients": mergedIngredients,
        "additives": mergedAdditives,
        "status": isSafe ? "safe" : "unsafe",
        "isSafe": isSafe,
        "confidence": isSafe
            ? "high"
            : ruleHasFindings
            ? "high"
            : "medium",
        "message": isSafe
            ? "Compatible with selected ethical preferences."
            : ruleHasFindings && llmHasFindings
            ? "Conflicts detected by both rule-based and semantic analysis."
            : ruleHasFindings
            ? "Conflicts detected by rule-based analysis."
            : "Conflicts detected by semantic analysis.",
      }
    };
  }
}
