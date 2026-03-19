import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ai/services.dart';
import '../state/pref_store.dart';
import 'product_photo_page.dart';
import 'result_page.dart';
import 'services/food_analysis_processor.dart';
import 'services/market_country_service.dart';

class ProcessPage extends StatefulWidget {
  final String barcode;
  final Map<String, dynamic> product;

  const ProcessPage({
    super.key,
    required this.barcode,
    required this.product,
  });

  @override
  State<ProcessPage> createState() => _ProcessPageState();
}

class _ProcessPageState extends State<ProcessPage> {
  late final PreferenceStore _store;

  bool _prefsReady = false;
  bool _running = false;
  bool _started = false;

  String _status = "Preparing analysis…";

  @override
  void initState() {
    super.initState();
    _store = context.read<PreferenceStore>();
    _store.addListener(_onPrefsChanged);

    if (!_store.isLoading) {
      _prefsReady = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startIfReady();
      });
    }
  }

  void _onPrefsChanged() {
    if (!_store.isLoading && !_prefsReady) {
      setState(() {
        _prefsReady = true;
      });
      _startIfReady();
    }
  }

  void _startIfReady() {
    if (!_prefsReady || _started || !mounted) return;
    _started = true;
    _runProcessing();
  }

  @override
  void dispose() {
    _store.removeListener(_onPrefsChanged);
    super.dispose();
  }

  Future<void> _runProcessing() async {
    if (_running || !_prefsReady) return;

    setState(() {
      _running = true;
      _status = "Preparing product details…";
    });

    try {
      final product = Map<String, dynamic>.from(widget.product);

      setState(() {
        _status = "Extracting ingredients and nutrition…";
      });

      final ingredients = await extractIngredients(product);
      final additives = extractAdditives(product);
      final productAllergens = extractAllergens(product);
      final nutriments = extractNutriments(product);
      final nutrientLevels = extractNutrientLevels(product);
      final nutriScore = extractNutriScoreGrade(product);
      final novaGroup = extractNovaGroup(product);

      if (ingredients == null || ingredients.isEmpty) {
        setState(() {
          _running = false;
        });
        await _showProcessingFallbackSheet(
          title: "Ingredients not available",
          message:
              "This product was found, but ingredient details are missing. You can continue by taking a photo of the label.",
        );
        return;
      }

      setState(() {
        _status = "Running preference evaluations…";
      });

      final analysis = await FoodAnalysisProcessor.process(
        input: FoodAnalysisInput(
          product: product,
          ingredients: ingredients,
          additives: additives,
          productAllergens: productAllergens,
          nutriments: nutriments,
          nutrientLevels: nutrientLevels,
          nutriScore: nutriScore,
          novaGroup: novaGroup,
        ),
        prefs: _store.prefs,
      );

      setState(() {
        _status = "Preparing result…";
      });

      final marketCountry = await MarketCountryService.resolve(product: product);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            product: product,
            ingredients: ingredients,
            additives: additives,
            allergens: productAllergens,
            nutriments: nutriments,
            nutrientLevels: nutrientLevels,
            nutriScore: nutriScore,
            novaGroup: novaGroup,
            ranEvaluations: analysis.ranEvaluations,
            evaluationResults: analysis.evaluationResults,
            userMarketCountry: marketCountry.country,
            userMarketCountrySource: marketCountry.source,
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint(stack.toString());
      if (!mounted) return;
      setState(() {
        _running = false;
      });
      await _showProcessingFallbackSheet(
        title: "We couldn't process this product",
        message:
            "Something went wrong while preparing the analysis. You can try again with a product photo instead.\n\n$e",
      );
    }
  }

  Future<void> _showProcessingFallbackSheet({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    final goToPhoto = await showModalBottomSheet<bool>(
          context: context,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (sheetContext) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF224D35),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Color(0xFF6A7C6F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F7A4B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text("Take Photo"),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: const Text("Back to Scan"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;

    if (!mounted) return;

    if (goToPhoto) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProductPhotoPage(barcode: widget.barcode),
        ),
      );
      return;
    }

    Navigator.pop(context);
  }

  Future<List<String>?> extractIngredients(Map product) async {
    final items = product["ingredients"] as List?;
    if (items != null && items.isNotEmpty) {
      return items
          .map((e) => e["id"])
          .whereType<String>()
          .map((id) => id.replaceFirst(RegExp(r"^[a-z]{2}:"), ""))
          .toSet()
          .toList();
    }

    final eng = product["ingredients_text_en"]?.toString().trim();
    if (eng != null && eng.isNotEmpty) {
      return eng.split(",").map((e) => e.trim()).toList();
    }

    final raw = product["ingredients_text"]?.toString().trim();
    if (raw == null || raw.isEmpty) return null;

    return translateToEnglish(normalizeIngredients(raw));
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
      final additivesCount = product["additives_n"] ?? 0;
      if (additivesCount == 0) return [];

      final tags = product["additives_tags"] as List?;
      if (tags == null || tags.isEmpty) return [];

      final additives = <String>[];
      for (final tag in tags.whereType<String>()) {
        final parts = tag.split(":");
        additives.add(parts.isNotEmpty ? parts.last.toUpperCase() : tag);
      }

      return additives.toSet().toList();
    } catch (_) {
      return [];
    }
  }

  List<String> extractAllergens(Map<String, dynamic> product) {
    try {
      final hierarchy = product["allergens_hierarchy"] as List?;
      if (hierarchy != null && hierarchy.isNotEmpty) {
        return hierarchy
            .whereType<String>()
            .map((e) => e.replaceFirst(RegExp(r"^[a-z]{2}:"), ""))
            .toSet()
            .toList();
      }

      final tags = product["allergens_tags"] as List?;
      if (tags != null && tags.isNotEmpty) {
        return tags
            .whereType<String>()
            .map((e) => e.replaceFirst(RegExp(r"^[a-z]{2}:"), ""))
            .toSet()
            .toList();
      }

      final raw = product["allergens"]?.toString();
      if (raw != null && raw.isNotEmpty) {
        return raw
            .split(",")
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  Map<String, double> extractNutriments(Map<String, dynamic> product) {
    final nutriments = product["nutriments"];
    if (nutriments == null || nutriments is! Map) return {};

    double? numVal(String key) {
      final value = nutriments[key];
      if (value is num) return value.toDouble();
      return null;
    }

    final result = <String, double>{};

    void put(String key, double? value) {
      if (value != null) result[key] = value;
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
    final value = product["nutriscore_grade"];
    if (value is String && value.isNotEmpty) {
      return value.toUpperCase();
    }
    return null;
  }

  int? extractNovaGroup(Map<String, dynamic> product) {
    final value = product["nova_group"];
    if (value is num) return value.toInt();
    return null;
  }

  int _currentStepIndex() {
    if (_status.contains("Preparing result")) return 3;
    if (_status.contains("Running preference evaluations")) return 2;
    if (_status.contains("Extracting ingredients and nutrition")) return 1;
    return 0;
  }

  String _productLabel() {
    final name = widget.product["product_name"]?.toString().trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final brand = widget.product["brands"]?.toString().trim();
    if (brand != null && brand.isNotEmpty) {
      return brand;
    }

    return "your scanned product";
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _currentStepIndex();
    final productLabel = _productLabel();
    const steps = [
      "Product data loaded",
      "Ingredients and nutrition extracted",
      "Preferences evaluated",
      "Result summary prepared",
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F3),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FCF7),
              Color(0xFFF0F6F1),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.92, end: 1.08),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  onEnd: () {
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 168,
                        height: 168,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF8DE0A8).withOpacity(0.28),
                              const Color(0xFF8DE0A8).withOpacity(0.04),
                            ],
                          ),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 6.28),
                        duration: const Duration(milliseconds: 2600),
                        curve: Curves.linear,
                        builder: (context, angle, child) {
                          return Transform.rotate(angle: angle, child: child);
                        },
                        onEnd: () {
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        child: Container(
                          width: 126,
                          height: 126,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF9BC8AB),
                              width: 2.5,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2F7A4B),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2F7A4B).withOpacity(0.10),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Image.asset(
                            "assets/icons/logo_transparent.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  "Analyzing Product",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF224D35),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Checking $productLabel against your saved preferences",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF6A7C6F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _status,
                    key: ValueKey(_status),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Color(0xFF2F7A4B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.82),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFDCE7DD)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: List.generate(steps.length, (index) {
                      final isComplete = index < currentStep;
                      final isActive = index == currentStep;
                      final tone = isComplete || isActive
                          ? const Color(0xFF2F7A4B)
                          : const Color(0xFF9AAEA1);

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == steps.length - 1 ? 0 : 14,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isComplete
                                    ? const Color(0xFF2F7A4B)
                                    : isActive
                                        ? const Color(0xFFE7F3EB)
                                        : const Color(0xFFF0F4F1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: tone,
                                  width: isActive ? 2 : 1.4,
                                ),
                              ),
                              child: isComplete
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : isActive
                                      ? const Center(
                                          child: SizedBox(
                                            width: 8,
                                            height: 8,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Color(0xFF2F7A4B),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        )
                                      : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                steps[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      isActive ? FontWeight.w800 : FontWeight.w600,
                                  color: isComplete || isActive
                                      ? const Color(0xFF31523F)
                                      : const Color(0xFF819388),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
