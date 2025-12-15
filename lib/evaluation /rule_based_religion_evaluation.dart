import '../diet_pref/restriction_definitions.dart';

class RuleBasedReligionEval {
  final Map<String, dynamic> religionRule;
  final List<String> ingredients;
  final List<String> additives;

  RuleBasedReligionEval({
    required this.religionRule,
    required this.ingredients,
    required this.additives,
  });

  Map<String, dynamic> result() {
    final Map<String, Map<String, dynamic>> ingredientResults = {};
    final Set<String> violatedRuleIds = {};

    final String religionId = religionRule["id"];
    final String strictness = religionRule["strictness"];
    final List<dynamic> rules =
        (religionRule["rules"] as List?) ?? [];

    void evaluateItem(String value, String source) {
      final valueLower = value.toLowerCase();
      final List<String> triggeredRules = [];

      for (final ruleId in rules) {
        final restriction = restrictionDefinitions[ruleId];
        if (restriction == null) continue;

        for (final keyword in restriction.examples) {
          if (valueLower.contains(keyword.toLowerCase())) {
            triggeredRules.add(ruleId);
            violatedRuleIds.add(ruleId);
            break;
          }
        }
      }

      if (triggeredRules.isNotEmpty) {
        ingredientResults[value] = {
          "source": source, // 👈 ingredient | additive
          "violates": triggeredRules,
        };
      }
    }

    // 1️⃣ Ingredients
    for (final ingredient in ingredients) {
      evaluateItem(ingredient, "ingredient");
    }

    // 2️⃣ Additives
    for (final additive in additives) {
      evaluateItem(additive, "additive");
    }

    final bool isSafe = ingredientResults.isEmpty;

    final String message = isSafe
        ? "Safe for $religionId ($strictness rule). No rules violated."
        : "Violates $religionId ($strictness rule). Detected: "
        "${violatedRuleIds.map((id) {
      return restrictionDefinitions[id]?.title ?? id;
    }).join(", ")}";

    return {
      "result": {
        "religion": {
          "id": religionId,
          "strictness": strictness,
        },
        "ingredients": ingredientResults,
        "status": isSafe ? "safe" : "unsafe",
        "isSafe": isSafe,
        "message": message,
        "source": "Rule Based Engine",
      }
    };
  }
}
