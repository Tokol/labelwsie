import '../diet_pref/restriction_definitions.dart';

class RuleBasedEthicalEval {
  final List<Map<String, dynamic>> ethicalPrefs;
  final List<String> ingredients;
  final List<String> additives;

  RuleBasedEthicalEval({
    required this.ethicalPrefs,
    required this.ingredients,
    required this.additives,
  });

  Map<String, dynamic> result() {
    final Map<String, dynamic> ingredientFindings = {};
    final Map<String, dynamic> additiveFindings = {};

    bool hasViolation = false;

    // --------------------------------------------------
    // INGREDIENT CHECK
    // --------------------------------------------------
    for (final ingredient in ingredients) {
      final String text = ingredient.toLowerCase();
      final List<Map<String, String>> violations = [];

      for (final pref in ethicalPrefs) {
        final String prefId = pref["title"].toString();
        final List<String> ruleIds =
        ((pref["rules"] as List?) ?? []).cast<String>();

        for (final ruleId in ruleIds) {
          final def = restrictionDefinitions[ruleId];
          if (def == null) continue;

          for (final example in def.examples) {
            if (_matchesExample(text, example)) {
              violations.add({
                "preference": prefId,
                "rule": ruleId,
              });
              break;
            }
          }
        }
      }

      if (violations.isNotEmpty) {
        hasViolation = true;
        ingredientFindings[ingredient] = {
          "source": "ingredient",
          "detected_by": "keyword",
          "violations": violations,
          "uncertain": []
        };
      }
    }

    // --------------------------------------------------
    // ADDITIVE CHECK
    // --------------------------------------------------
    for (final additive in additives) {
      final String text = additive.toLowerCase();
      final List<Map<String, String>> violations = [];

      for (final pref in ethicalPrefs) {
        final String prefId = pref["id"].toString();
        final List<String> ruleIds =
        ((pref["rules"] as List?) ?? []).cast<String>();

        for (final ruleId in ruleIds) {
          final def = restrictionDefinitions[ruleId];
          if (def == null) continue;

          for (final example in def.examples) {
            if (_matchesExample(text, example)) {
              violations.add({
                "preference": prefId,
                "rule": ruleId,
              });
              break;
            }
          }
        }
      }

      if (violations.isNotEmpty) {
        hasViolation = true;
        additiveFindings[additive] = {
          "source": "additive",
          "detected_by": "keyword",
          "violations": violations,
          "uncertain": []
        };
      }
    }

    final bool isSafe = !hasViolation;

    return {
      "result": {
        "domain": "ethical",
        "engine": {
          "type": "rule",
          "source": "Rule Based Engine"
        },
        "preferences": ethicalPrefs.map((e) => e["id"]).toList(),
        "ingredients": ingredientFindings,
        "additives": additiveFindings,
        "status": isSafe ? "safe" : "unsafe",
        "isSafe": isSafe,
        "confidence": "high",
        "message": isSafe
            ? "No ethical restrictions violated."
            : "One or more ethical preferences are violated."
      }
    };
  }

  // --------------------------------------------------
  // TEXT MATCHING (STRICT)
  // --------------------------------------------------
  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _matchesExample(String text, String example) {
    return _normalize(text) == _normalize(example);
  }
}
