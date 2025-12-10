// lib/eval/religion_evaluator.dart

import '../diet_pref/restriction_definitions.dart';

typedef EvalBlock = Map<String, dynamic>;

class ReligionEvaluator {
  /// Pure rule-based evaluation.
  /// No severity, no LLM.
  static Future<EvalBlock> evaluate({
    required List<String> ingredients,
    required Map<String, dynamic>? religionPref,
  }) async {
    // 0) No religion preference configured
    if (religionPref == null) {
      return _notConfiguredBlock(
        summary: "No religion rules configured",
        details:
        "You have not selected any religious / cultural rules yet. You can add them from Preferences.",
      );
    }

    final rules = (religionPref["rules"] as List?)?.cast<String>() ?? const <String>[];
    if (rules.isEmpty) {
      return _notConfiguredBlock(
        summary: "Religion rules empty",
        details:
        "Your religion preference is saved, but it does not contain any active rules.",
      );
    }

    // 1) Normalize ingredients
    final lowerIngredients = ingredients
        .map((e) => e.toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // ruleId → set of matched ingredients
    final Map<String, Set<String>> ruleMatches = {};

    // 2) Rule-based matching: ingredient ↔ examples
    for (final ruleId in rules) {
      final def = restrictionDefinitions[ruleId];
      if (def == null) continue;

      final examples = def.examples
          .map((e) => e.toLowerCase().trim())
          .where((e) => e.isNotEmpty)
          .toList();

      for (final ing in lowerIngredients) {
        for (final ex in examples) {
          if (ing.contains(ex)) {
            ruleMatches.putIfAbsent(ruleId, () => <String>{}).add(ing);
            break; // stop checking more examples for this ingredient for this rule
          }
        }
      }
    }

    // 3) Build violations list
    final List<Map<String, dynamic>> violations = [];
    final Set<String> violatedIngredients = {};

    ruleMatches.forEach((ruleId, matchedIngs) {
      final def = restrictionDefinitions[ruleId];
      if (def == null) return;

      violatedIngredients.addAll(matchedIngs);

      violations.add({
        "rule_id": ruleId,
        "title": def.title,
        "description": def.description,
        "matched_ingredients": matchedIngs.toList(),
      });
    });

    // 4) Build safe ingredient list
    final safeIngredients = lowerIngredients
        .where((ing) => !violatedIngredients.contains(ing))
        .toList();

    // 5) Decide status (simple)
    final status = violations.isEmpty ? "safe" : "not_safe";

    // 6) Build messages
    final messages = _buildMessages(
      status: status,
      religionPref: religionPref,
      violations: violations,
    );

    // 7) Final block (LLM reserved for later)
    return {
      "status": status,
      "violations": violations,
      "safe_ingredients": safeIngredients,
      "violated_ingredients": violatedIngredients.toList(),
      "messages": messages,
      "llm_opinion": null,
    };
  }

  // ----------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------

  static EvalBlock _notConfiguredBlock({
    required String summary,
    required String details,
  }) {
    return {
      "status": "not_configured",
      "violations": <Map<String, dynamic>>[],
      "safe_ingredients": <String>[],
      "violated_ingredients": <String>[],
      "messages": {
        "summary": summary,
        "details": details,
      },
      "llm_opinion": null,
    };
  }

  static Map<String, String> _buildMessages({
    required String status,
    required Map<String, dynamic> religionPref,
    required List<Map<String, dynamic>> violations,
  }) {
    final id = (religionPref["id"] ?? "religion").toString();
    final strict = (religionPref["strictness"] ?? "").toString();

    String relLabel = id;
    if (id == "muslim") relLabel = "Muslim";
    if (id == "hindu") relLabel = "Hindu";
    if (id == "jain") relLabel = "Jain";
    if (id == "sikh") relLabel = "Sikh";
    if (id == "jewish") relLabel = "Jewish";

    final strictLabel =
    strict.isEmpty ? "" : " (${strict[0].toUpperCase()}${strict.substring(1)})";

    if (status == "not_configured") {
      return {
        "summary": "$relLabel$strictLabel – not configured",
        "details": "No active religious rules are set.",
      };
    }

    if (status == "safe") {
      return {
        "summary": "$relLabel$strictLabel – looks safe",
        "details":
        "No ingredients matched your saved $relLabel dietary rules based on the current label.",
      };
    }

    // not_safe
    final names = violations
        .map((v) => (v["title"] ?? v["rule_id"]).toString())
        .toList();
    final joined = names.join(", ");

    return {
      "summary": "$relLabel$strictLabel – not safe",
      "details":
      "The following rules were violated based on the ingredient list: $joined.",
    };
  }
}
