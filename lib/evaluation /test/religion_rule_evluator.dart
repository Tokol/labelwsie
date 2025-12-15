

import '../../diet_pref/restriction_definitions.dart';

class ReligionRuleEvaluatorResult {
  final bool hasViolation;
  final List<Map<String, dynamic>> violations;

  ReligionRuleEvaluatorResult({
    required this.hasViolation,
    required this.violations,
  });
}

class ReligionRuleEvaluator {
  /// Main entry: check ingredients against selected religious rules
  static ReligionRuleEvaluatorResult evaluate({
    required List<String> ingredients,
    required List<String> activeRuleIds, // from hive strictness
  }) {
    final List<Map<String, dynamic>> foundViolations = [];

    // Convert ingredients to lowercase for safe matching
    final lowerIngredients =
    ingredients.map((i) => i.toLowerCase()).toList();

    for (final ruleId in activeRuleIds) {
      final def = restrictionDefinitions[ruleId];
      if (def == null) continue;

      // Compare each ingredient with examples of this rule
      for (final ing in lowerIngredients) {
        for (final ex in def.examples) {
          if (ing.contains(ex.toLowerCase())) {
            // Found deterministic match
            foundViolations.add({
              "rule_id": ruleId,
              "matched": ing,
              "example_trigger": ex,
              "title": def.title,
              "description": def.description,
            });
          }
        }
      }
    }

    return ReligionRuleEvaluatorResult(
      hasViolation: foundViolations.isNotEmpty,
      violations: foundViolations,
    );
  }
}
