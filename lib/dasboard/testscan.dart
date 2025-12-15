import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../evaluation /reason_based_religion_evaluation.dart';
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
      await OpenFoodFactsService.fetchProduct("4056489108122");

      if (!mounted) return;

      if (product == null) {
        setState(() {
          _log = "❌ OpenFoodFacts returned NULL product";
          _running = false;
        });
        return;
      }

      final ingredients = await extractIngredients(product);
      final additives =  extractAdditives(product);


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



      setState(() {
        _log = """
✅ TEST SUCCESS

Ingredients:
${ingredients.join(", ")}

Religion preference (raw JSON):
${jsonEncode(religionPref)}
""";
        _running = false;
      });

  dynamic  res =    RuleBasedReligionEval(
        religionRule: religionPref,
        ingredients: ingredients,
        additives: additives,
      );

     print(res.result());

      final evaluator = ReasonBasedReligionEval(
        religionRule: religionPref,
        ingredients: ingredients,
        additives: additives,
      );

      final Map<String, dynamic> result = await evaluator.result(); // ✅ await

      final pretty = const JsonEncoder.withIndent("  ").convert(result);

      setState(() {
        _log = const JsonEncoder.withIndent("  ").convert(res.result());

        //_log = pretty; // ✅ string
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


    final eng = product["ingredients_text_en"]?.toString().trim();



    if (eng != null && eng.isNotEmpty) {
      return eng.split(",").map((e) => e.trim()).toList();
    }

    String? raw = product["ingredients_text"]?.toString().trim();

    if ((raw == null || raw.isEmpty) && product["ingredients"] != null) {
      final list = product["ingredients"] as List;
      raw = list.map((e) => e["text"]).whereType<String>().join(", ");
    }

    if (raw == null || raw.isEmpty) return null;

    raw = normalizeIngredients(raw);
    return await translateToEnglish(raw);
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
