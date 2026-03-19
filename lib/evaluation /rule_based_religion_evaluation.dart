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
    final String religionId =
    (religionRule["id"] ?? "unknown").toString();
    final String strictness =
    (religionRule["strictness"] ?? "standard").toString();

    final List<String> ruleIds =
    ((religionRule["rules"] as List?) ?? []).cast<String>();

    final Map<String, dynamic> ingredientFindings = {};
    final Map<String, dynamic> additiveFindings = {};

    bool hasViolation = false;

    // --------------------------------------------------
    // INGREDIENT CHECK (DATA-DRIVEN)
    // --------------------------------------------------
    for (final ingredient in ingredients) {
      final String text = ingredient.toLowerCase();
      final List<String> violated = [];

      for (final ruleId in ruleIds) {
        final def = restrictionDefinitions[ruleId];
        if (def == null) continue;

        for (final example in def.examples) {

          if (matchesExample(text, example)) {
            violated.add(ruleId);
            break;
          }

        }
      }

      if (violated.isNotEmpty) {
        hasViolation = true;
        ingredientFindings[ingredient] = {
          "source": "ingredient",
          "detected_by": "keyword",
          "violates": violated,
          "uncertain": []
        };
      }
    }

    // --------------------------------------------------
    // ADDITIVE CHECK (SAME LOGIC)
    // --------------------------------------------------
    for (final additive in additives) {
      final String text = additive.toLowerCase();
      final List<String> violated = [];

      for (final ruleId in ruleIds) {
        final def = restrictionDefinitions[ruleId];
        if (def == null) continue;

        for (final example in def.examples) {

          if (matchesExample(text, example)) {
            violated.add(ruleId);
            break;
          }

        }
      }

      if (violated.isNotEmpty) {
        hasViolation = true;
        additiveFindings[additive] = {
          "source": "additive",
          "detected_by": "keyword",
          "violates": violated,
          "uncertain": []
        };
      }
    }

    final bool isSafe = !hasViolation;

    return {
      "result": {
        "domain": "religion",
        "engine": {
          "type": "rule",
          "source": "Rule Based Engine"
        },
        "religion": {
          "id": religionId,
          "strictness": strictness
        },
        "ingredients": ingredientFindings,
        "additives": additiveFindings,
        "status": isSafe ? "safe" : "unsafe",
        "isSafe": isSafe,
        "confidence": "high",
        "message": isSafe
            ? "Safe for $religionId ($strictness rule). No violations detected."
            : "Contains items not permissible for $religionId ($strictness rule)."
      }
    };
  }


  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }


  Set<String> tokenize(String text) {
    return _normalize(text).split(' ').toSet();
  }

  bool matchesExample(String text, String example) {
    final normalizedText = _normalize(text);
    final normalizedExample = _normalize(example);

    // Exact word-boundary match (no substrings)
    final pattern = RegExp(
      r'\b' + RegExp.escape(normalizedExample) + r'\b',
    );

    return pattern.hasMatch(normalizedText);
  }




}
