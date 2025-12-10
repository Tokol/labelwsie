import 'package:flutter/foundation.dart';
import 'package:label_wise/evaluation%20/religion_evluator.dart';

typedef EvalBlock = Map<String, dynamic>;

class EvaluationEngine {
  /// ---------------------------------------------------------
  /// MAIN ENTRY POINT
  /// ---------------------------------------------------------
  static Future<Map<String, dynamic>> evaluate({
    required Map<String, dynamic> product,
    required Map<String, dynamic> prefs,
  }) async {
    final ingredients =
        (product["ingredients_final"] as List?)?.cast<String>() ?? const <String>[];

    // 1) RELIGION PREFERENCES
    final religionPref = prefs["religion"];
    final religionEval = await ReligionEvaluator.evaluate(
      ingredients: ingredients,
      religionPref: religionPref,
    );

    // 2) OTHER EVALUATORS (COMING SOON)
    final allergyEval = _buildNotConfiguredBlock("allergy");
    final medicalEval = _buildNotConfiguredBlock("medical");
    final lifestyleEval = _buildNotConfiguredBlock("lifestyle");
    final ethicalEval = _buildNotConfiguredBlock("ethical");

    // 3) OVERALL SUMMARY
    final overall = _computeOverallSummary(
      religionEval: religionEval,
      allergyEval: allergyEval,
      medicalEval: medicalEval,
      lifestyleEval: lifestyleEval,
      ethicalEval: ethicalEval,
    );

    // 4) FINAL RETURN STRUCTURE (UI + LLM friendly)
    return {
      "overall": overall,
      "religion": religionEval,
      "allergy": allergyEval,
      "medical": medicalEval,
      "lifestyle": lifestyleEval,
      "ethical": ethicalEval,
    };
  }

  /// ---------------------------------------------------------
  /// HELPERS
  /// ---------------------------------------------------------

  static EvalBlock _buildNotConfiguredBlock(String domain) {
    return {
      "status": "not_configured",
      "violations": <Map<String, dynamic>>[],
      "maybe": const <String>[],
      "safe": const <String>[],
      "messages": {
        "summary": "$domain preferences not set",
        "details": "You have not configured $domain rules yet.",
      },
      "llm_opinion": null,
    };
  }

  /// ---------------------------------------------------------
  /// OVERALL FINAL STATUS
  /// ---------------------------------------------------------
  static Map<String, dynamic> _computeOverallSummary({
    required EvalBlock religionEval,
    required EvalBlock allergyEval,
    required EvalBlock medicalEval,
    required EvalBlock lifestyleEval,
    required EvalBlock ethicalEval,
  }) {
    final blocks = [
      religionEval,
      allergyEval,
      medicalEval,
      lifestyleEval,
      ethicalEval,
    ];

    String status = "safe";

    for (final blk in blocks) {
      final s = blk["status"]?.toString() ?? "not_configured";
      if (s == "not_safe") {
        status = "not_safe";
        break;
      }
      if (s == "warning" && status == "safe") {
        status = "warning";
      }
    }

    return {
      "status": status,
    };
  }
}
