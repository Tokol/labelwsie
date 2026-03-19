import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../evaluation /lifestyle_evaluation.dart';
import '../evaluation /medical_based_evaluation.dart';
import '../evaluation /orchestrator/allergy_evaluator.dart';
import '../evaluation /orchestrator/ethical_evaluator.dart';
import '../evaluation /orchestrator/religion_evaluation.dart';
import '../evaluation /reason_based_allergy_evaluation.dart';
import '../evaluation /reason_based_religion_evaluation.dart';
import '../evaluation /rule_based_allergy_evaluation.dart';
import '../evaluation /rule_based_religion_evaluation.dart';
import '../state/pref_store.dart';
import '../utlis/open_food_service.dart';
import '../ai/services.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late final PreferenceStore _store;

  bool _prefsReady = false;
  bool _running = false;

  String _log = "Idle";

  @override
  void initState() {
    super.initState();

    _store = context.read<PreferenceStore>();
    _store.addListener(_onPrefsChanged);

    // Hot-restart safe
    if (!_store.isLoading) {
      _prefsReady = true;
      _log = "Preferences already loaded ✅";
    }
  }

  void _onPrefsChanged() {
    if (!_store.isLoading && !_prefsReady) {
      setState(() {
        _prefsReady = true;
        _log = "Preferences loaded ✅";
      });
    }
  }

  @override
  void dispose() {
    _store.removeListener(_onPrefsChanged);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // STATIC TEST — FULLY SAFE
  // ---------------------------------------------------------------------------

  Future<void> _runStaticTest() async {
    if (_running || !_prefsReady) return;

    setState(() {
      _running = true;
      _log = "▶️ Button pressed\nFetching product from OpenFoodFacts…";
    });

    try {
      final product =
      await OpenFoodFactsService.fetchProduct("6413467442407");

      if (!mounted) return;

      if (product == null) {
        setState(() {
          _log = "❌ OpenFoodFacts returned NULL product";
          _running = false;
        });
        return;
      }

      final ingredients = await extractIngredients(product);
      // final ingredients = ["raw milk", "octopus",];

      final additives =  extractAdditives(product);
      //  final additives = ["lacto", "milk"];


      final productAllergens = extractAllergens(product);
      // final productAllergens = ["octupus"];
      final nutriments = extractNutriments(product);
      final nutrientLevels = extractNutrientLevels(product);
      final nutriScore = extractNutriScoreGrade(product);
      final novaGroup = extractNovaGroup(product);

      if (ingredients == null || ingredients.isEmpty) {
        setState(() {
          _log = "❌ No ingredients found in product";
          _running = false;
        });
        return;
      }


      final religionPrefRaw = _store.prefs["religion"];

      final Map<String, dynamic> religionPref =
      Map<String, dynamic>.from(religionPrefRaw);


      final ethicalPersonalPrefRaw = _store.prefs["ethical"];

      final MedicalPrefRaw = _store.prefs["medical"];

      final LifeStylePrefRaw = _store.prefs["lifestyle"];


      print("lifestyle values");
      print(LifeStylePrefRaw);





// ✅ correct cast
      final List<Map<String, dynamic>> ethicalPrefs =
      (ethicalPersonalPrefRaw as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();


      final List<Map<String, dynamic>> medicalPrefs =
      (MedicalPrefRaw as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final List<Map<String, dynamic>> lifestylePrefs = [];

      if (LifeStylePrefRaw is Map) {

        final restrictGoals = LifeStylePrefRaw["restrict_goals"];
        final awarenessGoals = LifeStylePrefRaw["awareness_goals"];

        if (restrictGoals is List) {
          for (final g in restrictGoals) {
            lifestylePrefs.add({
              ...Map<String, dynamic>.from(g),
              "type": "restriction",
            });
          }
        }

        if (awarenessGoals is List) {
          for (final g in awarenessGoals) {
            lifestylePrefs.add({
              ...Map<String, dynamic>.from(g),
              "type": "awareness",
            });
          }
        }
      }

      print("Lifestyle Data");
      print(lifestylePrefs);


      print("Medical Data");
      print(medicalPrefs);


      setState(() {
        _log = """
✅ TEST SUCCESS

Ingredients:
${ingredients.join(", ")}

Additives:
${additives.join(", ")}

Allergens:
${productAllergens.join(", ")}

Medical Pref:
${jsonEncode(medicalPrefs)}

Ethical Pref:
${jsonEncode(ethicalPrefs)}

Lifestyle Pref:
${jsonEncode(lifestylePrefs)}



Nutrition (per 100g):
${jsonEncode(nutriments)}

Nutrient Levels:
${jsonEncode(nutrientLevels)}

Nutri-Score:
$nutriScore

NOVA Group:
$novaGroup


""";
      });

      final evaluation = ReligionEvaluation(
        religionRule: religionPref,
        ingredients: ingredients,
        additives: additives,
      );

      final ReligionEvaluationResult = await evaluation.evaluate();

      final ethicalEval = EthicalEvaluation(
        ethicalPrefs: ethicalPrefs, // ✅ already a list
        ingredients: ingredients,
        additives: additives,
      );


      final EthicalEvaluationResult = await ethicalEval.evaluate();


      final Map<String, dynamic> allergyPrefs =
      Map<String, dynamic>.from(_store.prefs["allergy"]);

      final allergyEval = AllergyEvaluation(
        allergyPrefs: allergyPrefs,
        ingredients: ingredients,
        additives: additives,
        productAllergens: productAllergens,

      );

// 3️⃣ Run evaluation (AWAIT!)
      final allergyResult = await allergyEval.evaluate();

      final medicalEval = ReasonBasedMedicalEvaluation(
        medicalPrefs: medicalPrefs,
        ingredients: ingredients,
        additives: additives,
        nutriments: nutriments,
        nutrientLevels: nutrientLevels,
        novaGroup: novaGroup,
        nutriScore: nutriScore,
      );

// ▶️ Run evaluation
      final medicalResult = await medicalEval.evaluate();

      final lifestyleEval = LifestyleEvaluation(
        lifestyleGoals: lifestylePrefs,
        ingredients: ingredients,
        additives: additives,
        nutriments: nutriments,
        nutrientLevels: nutrientLevels,
        novaGroup: novaGroup,
        nutriScore: nutriScore,
      );

      final lifestyleResult = await lifestyleEval.evaluate();

      // setState(() {
      //   _log =
      //   "Medical Preferences:\n${jsonEncode(medicalPrefs)}\n\n"
      //       "Nutrition:\n${jsonEncode(nutriments)}\n\n"
      //       "Reason-Based Medical Result:\n${jsonEncode(medicalResult)}";
      // });

      setState(() {
        _log =
        "LifeStyle Preferences:\n${jsonEncode(lifestylePrefs)}\n\n"
            "Nutrition:\n${jsonEncode(nutriments)}\n\n"
            "Reason-Based LifeStyle Result:\n${jsonEncode(lifestyleResult)}";
      });



    } catch (e, stack) {
      // 🔴 THIS IS WHAT YOU WERE MISSING
      setState(() {
        _log = """
❌ ERROR during test

Error:
$e

Stack:
$stack
""";
        _running = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // INGREDIENT EXTRACTION (SAME AS ScanPage)
  // ---------------------------------------------------------------------------

  Future<List<String>?> extractIngredients(Map product) async {
    // 1️⃣ BEST: structured ingredients with IDs
    final List<dynamic>? items = product["ingredients"] as List?;
    if (items != null && items.isNotEmpty) {
      return items
          .map((e) => e["id"])
          .whereType<String>()
          .map((id) => id.replaceFirst(RegExp(r"^[a-z]{2}:"), ""))
          .toSet()
          .toList();
    }

    // 2️⃣ ingredients_text_en
    final eng = product["ingredients_text_en"]?.toString().trim();
    if (eng != null && eng.isNotEmpty) {
      return eng.split(",").map((e) => e.trim()).toList();
    }

    // 3️⃣ LAST RESORT: translate raw text
    final raw = product["ingredients_text"]?.toString().trim();
    if (raw == null || raw.isEmpty) return null;

    return await translateToEnglish(normalizeIngredients(raw));
  }


  String normalizeIngredients(String raw) {
    var text = raw.toLowerCase();
    text = text.replaceAll(RegExp(r"[\/;]"), ", ");
    text = text.replaceAll(RegExp(r",\s*,+"), ", ");
    text = text.replaceAll(RegExp(r"\s+"), " ");
    return text.trim();
  }

  Future<List<String>> translateToEnglish(String text) async {
    final prompt = """
Translate the following ingredient list into English.
Return ONLY a JSON array of ingredients.

$text
""";

    final result = await OpenAIService.instance.callModel(prompt);

    try {
      final decoded = jsonDecode(result);
      return (decoded as List).map((e) => e.toString().trim()).toList();
    } catch (_) {
      return text.split(",").map((e) => e.trim()).toList();
    }
  }


  List<String> extractAdditives(Map<String, dynamic> product) {
    try {
      // Fast exit if OFF explicitly says no additives
      final int additivesCount = product["additives_n"] ?? 0;
      if (additivesCount == 0) return [];

      final List<dynamic>? tags = product["additives_tags"] as List?;
      if (tags == null || tags.isEmpty) return [];

      final List<String> additives = [];

      for (final tag in tags) {
        if (tag is String) {
          // Examples:
          // "en:e330" → "E330"
          // "fr:e202" → "E202"
          final parts = tag.split(":");
          final code = parts.isNotEmpty ? parts.last.toUpperCase() : tag;
          additives.add(code);
        }
      }

      return additives.toSet().toList(); // remove duplicates
    } catch (e) {
      print("Additives extraction failed: $e");
      return [];
    }
  }


  List<String> extractAllergens(Map<String, dynamic> product) {
    try {
      // 1️⃣ Prefer allergens_hierarchy
      final List<dynamic>? hierarchy =
      product["allergens_hierarchy"] as List?;

      if (hierarchy != null && hierarchy.isNotEmpty) {
        return hierarchy
            .whereType<String>()
            .map((e) => e.replaceFirst(RegExp(r"^[a-z]{2}:"), "")) // remove en:
            .toSet()
            .toList();
      }

      // 2️⃣ Fallback to allergens_tags
      final List<dynamic>? tags =
      product["allergens_tags"] as List?;

      if (tags != null && tags.isNotEmpty) {
        return tags
            .whereType<String>()
            .map((e) => e.replaceFirst(RegExp(r"^[a-z]{2}:"), ""))
            .toSet()
            .toList();
      }

      // 3️⃣ Fallback to raw allergens string
      final String? raw = product["allergens"]?.toString();
      if (raw != null && raw.isNotEmpty) {
        return raw
            .split(",")
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();
      }

      return [];
    } catch (e) {
      print("Allergen extraction failed: $e");
      return [];
    }
  }


  Map<String, double> extractNutriments(Map<String, dynamic> product) {
    final nutriments = product["nutriments"];
    if (nutriments == null || nutriments is! Map) return {};

    double? numVal(String key) {
      final v = nutriments[key];
      if (v is num) return v.toDouble();
      return null;
    }

    final Map<String, double> result = {};

    void put(String k, double? v) {
      if (v != null) result[k] = v;
    }

    put("energy_kcal", numVal("energy-kcal_100g"));
    put("fat", numVal("fat_100g"));
    put("saturated_fat", numVal("saturated-fat_100g"));
    put("carbohydrates", numVal("carbohydrates_100g"));
    put("sugars", numVal("sugars_100g"));
    put("fiber", numVal("fiber_100g"));
    put("protein", numVal("proteins_100g"));
    put("salt", numVal("salt_100g"));
    put("sodium", numVal("sodium_100g"));

    return result;
  }

  Map<String, String> extractNutrientLevels(Map<String, dynamic> product) {
    final levels = product["nutrient_levels"];
    if (levels == null || levels is! Map) return {};

    return levels.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }

  String? extractNutriScoreGrade(Map<String, dynamic> product) {
    final v = product["nutriscore_grade"];
    if (v is String && v.isNotEmpty) {
      return v.toUpperCase(); // A–E
    }
    return null;
  }

  int? extractNovaGroup(Map<String, dynamic> product) {
    final v = product["nova_group"];
    if (v is num) return v.toInt();
    return null;
  }






  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Screen")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _prefsReady ? "Prefs ready ✅" : "Loading prefs…",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _prefsReady ? Colors.green : Colors.orange,
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _prefsReady && !_running ? _runStaticTest : null,
              child: Text(_running ? "Running…" : "Run Static Test"),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
