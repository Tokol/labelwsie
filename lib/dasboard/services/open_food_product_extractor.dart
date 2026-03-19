import 'dart:convert';

import '../../ai/services.dart';

class OpenFoodProductExtraction {
  final List<String>? ingredients;
  final List<String> additives;
  final List<String> productAllergens;
  final Map<String, double> nutriments;
  final Map<String, String> nutrientLevels;
  final String? nutriScore;
  final int? novaGroup;

  const OpenFoodProductExtraction({
    required this.ingredients,
    required this.additives,
    required this.productAllergens,
    required this.nutriments,
    required this.nutrientLevels,
    required this.nutriScore,
    required this.novaGroup,
  });
}

class OpenFoodProductExtractor {
  const OpenFoodProductExtractor._();

  static Future<OpenFoodProductExtraction> extract(
    Map<String, dynamic> product,
  ) async {
    return OpenFoodProductExtraction(
      ingredients: await extractIngredients(product),
      additives: extractAdditives(product),
      productAllergens: extractAllergens(product),
      nutriments: extractNutriments(product),
      nutrientLevels: extractNutrientLevels(product),
      nutriScore: extractNutriScoreGrade(product),
      novaGroup: extractNovaGroup(product),
    );
  }

  static Future<List<String>?> extractIngredients(Map product) async {
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

    return _translateToEnglish(_normalizeIngredients(raw));
  }

  static String _normalizeIngredients(String raw) {
    var text = raw.toLowerCase();
    text = text.replaceAll(RegExp(r"[\/;]"), ", ");
    text = text.replaceAll(RegExp(r",\s*,+"), ", ");
    text = text.replaceAll(RegExp(r"\s+"), " ");
    return text.trim();
  }

  static Future<List<String>> _translateToEnglish(String text) async {
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

  static List<String> extractAdditives(Map<String, dynamic> product) {
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

  static List<String> extractAllergens(Map<String, dynamic> product) {
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

  static Map<String, double> extractNutriments(Map<String, dynamic> product) {
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

  static Map<String, String> extractNutrientLevels(
    Map<String, dynamic> product,
  ) {
    final levels = product["nutrient_levels"];
    if (levels == null || levels is! Map) return {};

    return levels.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }

  static String? extractNutriScoreGrade(Map<String, dynamic> product) {
    final value = product["nutriscore_grade"];
    if (value is String && value.isNotEmpty) {
      return value.toUpperCase();
    }
    return null;
  }

  static int? extractNovaGroup(Map<String, dynamic> product) {
    final value = product["nova_group"];
    if (value is num) return value.toInt();
    return null;
  }
}
