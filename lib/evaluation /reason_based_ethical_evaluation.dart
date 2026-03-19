import 'dart:convert';
import '../ai/services.dart';

class ReasonBasedEthicalEval {
  final List<Map<String, dynamic>> ethicalPrefs;
  final List<String> ingredients;
  final List<String> additives;

  ReasonBasedEthicalEval({
    required this.ethicalPrefs,
    required this.ingredients,
    required this.additives,
  });

  Future<Map<String, dynamic>> result() async {
    // ------------------------------------------------------------
    // COLLECT PREF IDS + RULES
    // ------------------------------------------------------------
    final List<Map<String, dynamic>> prefInputs = ethicalPrefs.map((p) {
      return {
        "id": p["id"],
        "title": p["title"],
        "rules": (p["rules"] as List?)?.cast<String>() ?? [],
      };
    }).toList();

    // ------------------------------------------------------------
    // PROMPT (ETHICAL / MULTI-PREFERENCE)
    // ------------------------------------------------------------
    final prompt = """
You are an ethical and lifestyle dietary preference checker.

This is NOT a religious ruling.
This is preference-based (e.g. vegan, dairy-free, whole-food).

You may use semantic equivalence.
Examples:
- whey → dairy
- casein → dairy
- gelatin → animal-derived
- carmine → insect-derived

PREFERENCE-SPECIFIC ALLOWED FOODS:

- pollo vegetarian:
  - ALLOWED: chicken, poultry, eggs
  - NOT ALLOWED: beef, pork, lamb, fish, seafood

- pescatarian:
  - ALLOWED: fish, seafood, shellfish, crustaceans, molluscs
  - NOT ALLOWED: beef, pork, lamb, chicken, poultry
  
  - raw vegan:
   - ALLOWED: raw fruits, raw vegetables, raw nuts, raw seeds, raw sprouted grains, cold-pressed oils
   - NOT ALLOWED: any animal products, cooked foods, baked foods, roasted foods, fried foods, pasteurized foods, refined sugar, processed foods

INTERPRETATION RULE:
For pescatarian preference:
- Only aquatic animals (fish and seafood) are allowed
- All land animals and poultry are not allowed

For raw vegan preference:
- Any ingredient that is cooked, baked, roasted, fried, or pasteurized
  MUST be treated as a violation.
- If processing method is unknown or ambiguous, mark as "uncertain",
  NOT as a violation.


STRICT RULES (NON-NEGOTIABLE):

1. This evaluation is preference-based, NOT religious.

2. A conflict MUST be flagged ONLY when there is a direct, well-known,
   and unambiguous incompatibility with a preference.

3. Animal species names (e.g. swine, pig, cow, chicken, fish) ALWAYS
   indicate animal-derived origin.

4. Plant-based milks MUST NEVER be treated as dairy.
   This includes coconut milk, almond milk, soy milk, oat milk, rice milk.

5. The presence of the word "milk" alone does NOT imply dairy.
   Dairy applies ONLY when milk is from an animal source.

6. Dairy ingredients (milk, whey, casein, cheese, butter) ARE animal-derived
   but are NOT meat.

7. Meat rules apply ONLY to flesh, meat extracts, meat fats,
   or slaughtered tissue — NOT dairy.

8. Do NOT infer animal origin unless it is widely and explicitly established.
   If origin is unclear, industrial, or unspecified (e.g. enzymes,
   emulsifiers, flavorings), mark it as "uncertain", NOT "violates".

9. Do NOT invent violations.
   Do NOT escalate uncertain cases into violations.

10. If no clear conflicts exist, findings MUST be empty.


Output ONLY valid JSON.

Schema:
{
  "result": {
    "ingredients": {
      "<item>": {
        "source": "ingredient",
        "detected_by": "semantic",
        "violations": [
          { "preference": "<pref_id>", "rule": "<rule_id>" }
        ],
        "uncertain": [
          { "preference": "<pref_id>", "rule": "<rule_id>" }
        ]
      }
    },
    "additives": {
      "<item>": {
        "source": "additive",
        "detected_by": "semantic",
        "violations": [
          { "preference": "<pref_id>", "rule": "<rule_id>" }
        ],
        "uncertain": []
      }
    },
    "message": "<short explanation>"
  }
}

Input:
preferences: ${jsonEncode(prefInputs)}
ingredients: ${jsonEncode(ingredients)}
additives: ${jsonEncode(additives)}
""";

    final raw = await OpenAIService.instance.callModel(prompt);

    // ------------------------------------------------------------
    // FAIL CLOSED
    // ------------------------------------------------------------
    if (raw.trim().isEmpty) {
      return _safeFallback();
    }

    final Map<String, dynamic> parsed =
    OpenAIService.extractJSON(raw);

    if (parsed.isEmpty || parsed["result"] == null) {
      return _safeFallback();
    }

    // ------------------------------------------------------------
    // NORMALIZE OUTPUT
    // ------------------------------------------------------------
    final Map<String, dynamic> resultObj =
    Map<String, dynamic>.from(parsed["result"]);

    final Map<String, dynamic> ingredientFindings =
    (resultObj["ingredients"] is Map)
        ? Map<String, dynamic>.from(resultObj["ingredients"])
        : {};

    final Map<String, dynamic> additiveFindings =
    (resultObj["additives"] is Map)
        ? Map<String, dynamic>.from(resultObj["additives"])
        : {};

    bool hasViolations = false;

    void scan(Map<String, dynamic> m) {
      for (final v in m.values) {
        if (v is Map) {
          final List violations = (v["violations"] as List?) ?? [];
          if (violations.isNotEmpty) {
            hasViolations = true;
          }
        }
      }
    }

    scan(ingredientFindings);
    scan(additiveFindings);

    final bool isSafe = !hasViolations;

    // ------------------------------------------------------------
    // FINAL RESULT
    // ------------------------------------------------------------
    return {
      "result": {
        "domain": "ethical",
        "engine": {
          "type": "llm",
          "source": "Reasoning Based Engine"
        },
        "preferences": ethicalPrefs.map((e) => e["id"]).toList(),
        "ingredients": ingredientFindings,
        "additives": additiveFindings,
        "status": isSafe ? "safe" : "unsafe",
        "isSafe": isSafe,
        "confidence": hasViolations ? "medium" : "high",
        "message": (resultObj["message"] ?? "").toString().trim().isNotEmpty
            ? resultObj["message"]
            : isSafe
            ? "Compatible with selected ethical preferences."
            : "Conflicts with one or more ethical preferences."
      }
    };
  }

  // ------------------------------------------------------------
  // SAFE FALLBACK
  // ------------------------------------------------------------
  Map<String, dynamic> _safeFallback() {
    return {
      "result": {
        "domain": "ethical",
        "engine": {
          "type": "llm",
          "source": "Reasoning Based Engine"
        },
        "preferences": ethicalPrefs.map((e) => e["id"]).toList(),
        "ingredients": {},
        "additives": {},
        "status": "safe",
        "isSafe": true,
        "confidence": "low",
        "message":
        "Unable to fully evaluate ethical preferences. No conflicts detected."
      }
    };
  }
}
