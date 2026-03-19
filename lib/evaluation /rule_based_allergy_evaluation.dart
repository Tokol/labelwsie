import '../diet_pref/restriction_definitions.dart';

class RuleBasedAllergyEvaluation {
  final Map<String, dynamic> allergyPrefs;
  final List<String> ingredients;
  final List<String> additives;
  final List<String> productAllergens;

  RuleBasedAllergyEvaluation({
    required this.allergyPrefs,
    required this.ingredients,
    required this.additives,
    required this.productAllergens,
  });

  Map<String, dynamic> evaluate() {
    final List<Map<String, dynamic>> strictMatches = [];
    final List<Map<String, dynamic>> sensitivityMatches = [];
    final List<Map<String, dynamic>> customMatches = [];

    bool hasStrictViolation = false;

    final List userAllergens = (allergyPrefs["allergens"] ?? []) as List;
    final List<String> sensitivities =
    ((allergyPrefs["sensitivities"] ?? []) as List).cast<String>();
    final List<String> custom =
    ((allergyPrefs["custom"] ?? []) as List).cast<String>();

    // --------------------------------------------------
    // 1️⃣ DECLARED PRODUCT ALLERGENS (HIGHEST CONFIDENCE)
    // --------------------------------------------------
    for (final user in userAllergens) {
      final id = user["id"].toString().toLowerCase();

      for (final prod in productAllergens) {
        if (_matches(prod, id)) {
          hasStrictViolation = true;
          strictMatches.add({
            "id": id,
            "title": user["title"],
            "source": "product_allergen",
            "detected_by": "declared",
            "restriction": user["restriction"],
          });
        }
      }
    }

    // --------------------------------------------------
    // 2️⃣ INGREDIENT + ADDITIVE RULE CHECK
    // --------------------------------------------------
    void checkAgainstRules(String value, String source) {
      for (final user in userAllergens) {
        final ruleId = user["restriction"];
        final def = restrictionDefinitions[ruleId];
        if (def == null) continue;

        for (final example in def.examples) {
          if (_matches(value, example)) {
            hasStrictViolation = true;
            strictMatches.add({
              "id": user["id"],
              "title": user["title"],
              "source": source,
              "detected_by": "rule",
              "restriction": ruleId,
            });
            break;
          }
        }
      }
    }

    for (final i in ingredients) {
      checkAgainstRules(i, "ingredient");
    }

    for (final a in additives) {
      checkAgainstRules(a, "additive");
    }

    // --------------------------------------------------
    // 3️⃣ CUSTOM ALLERGY KEYWORDS (STRICT)
    // --------------------------------------------------
    for (final word in custom) {
      final key = word.toLowerCase();

      for (final i in ingredients) {
        if (_matches(i, key)) {
          hasStrictViolation = true;
          customMatches.add({
            "keyword": word,
            "source": "ingredient",
            "detected_by": "custom",
          });
        }
      }

      for (final a in additives) {
        if (_matches(a, key)) {
          hasStrictViolation = true;
          customMatches.add({
            "keyword": word,
            "source": "additive",
            "detected_by": "custom",
          });
        }
      }

      for (final p in productAllergens) {
        if (_matches(p, key)) {
          hasStrictViolation = true;
          customMatches.add({
            "keyword": word,
            "source": "product_allergen",
            "detected_by": "custom",
          });
        }
      }
    }

    // --------------------------------------------------
    // 4️⃣ SENSITIVITIES (SOFT WARNINGS)
    // --------------------------------------------------
    for (final s in sensitivities) {
      for (final i in ingredients) {
        if (_matchesSensitivity(i, s)) {
          sensitivityMatches.add({
            "id": s,
            "source": "ingredient",
            "detected_by": "keyword",
          });
        }
      }

      for (final p in productAllergens) {
        if (_matchesSensitivity(p, s)) {
          sensitivityMatches.add({
            "id": s,
            "source": "product_allergen",
            "detected_by": "declared",
          });
        }
      }
    }

    // --------------------------------------------------
    // FINAL STATUS
    // --------------------------------------------------
    final bool isSafe = !hasStrictViolation;
    final String status = hasStrictViolation
        ? "unsafe"
        : sensitivityMatches.isNotEmpty
        ? "warning"
        : "safe";

    return {
      "result": {
        "domain": "allergy",
        "engine": {
          "type": "rule",
          "source": "Rule Based Engine",
        },
        "matched": {
          "strict": strictMatches,
          "sensitivities": sensitivityMatches,
          "custom": customMatches,
        },
        "summary": {
          "product_allergens": productAllergens,
          "ingredients_checked": ingredients.length,
          "additives_checked": additives.length,
        },
        "status": status,
        "isSafe": isSafe,
        "confidence": "high",
        "message": hasStrictViolation
            ? "Contains allergen(s) that violate your allergy preferences."
            : sensitivityMatches.isNotEmpty
            ? "May cause discomfort due to sensitivities."
            : "No allergy risks detected.",
      }
    };
  }

  // --------------------------------------------------
  // NORMALIZATION
  // --------------------------------------------------
  bool _matches(String a, String b) {
    return _normalize(a) == _normalize(b);
  }

  bool _matchesSensitivity(String candidate, String sensitivity) {
    final normalizedCandidate = _normalize(candidate);
    final normalizedSensitivity = _normalize(sensitivity);

    if (normalizedCandidate == normalizedSensitivity) return true;
    if (normalizedCandidate.contains(normalizedSensitivity)) return true;
    if (normalizedSensitivity.contains(normalizedCandidate)) return true;

    final sensitivityTokens = normalizedSensitivity
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toList();

    if (sensitivityTokens.length > 1 &&
        sensitivityTokens.every(normalizedCandidate.contains)) {
      return true;
    }

    // Friendly alias handling for common sensitivity phrases.
    if (normalizedSensitivity.contains("food color")) {
      return normalizedCandidate.contains("food color") ||
          normalizedCandidate.contains("coloring") ||
          normalizedCandidate.contains("colouring") ||
          normalizedCandidate.contains("artificial color") ||
          normalizedCandidate.contains("artificial colour") ||
          normalizedCandidate.contains("color") ||
          normalizedCandidate.contains("colour");
    }

    return false;
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
