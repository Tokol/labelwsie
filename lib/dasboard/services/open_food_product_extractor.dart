import 'dart:convert';

import '../../ai/services.dart';

class OpenFoodProductExtraction {
  final List<String>? ingredients;
  final List<String> additives;
  final List<String> productAllergens;
  final String? category;
  final String? originCountry;
  final Map<String, double> nutriments;
  final Map<String, String> nutrientLevels;
  final String? nutriScore;
  final int? novaGroup;

  const OpenFoodProductExtraction({
    required this.ingredients,
    required this.additives,
    required this.productAllergens,
    required this.category,
    required this.originCountry,
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
    final rawIngredients = await extractIngredients(product);
    final rawAdditives = extractAdditives(product);
    final rawAllergens = extractAllergens(product);
    final rawCategory = extractCategory(product);
    final rawOriginCountry = extractOriginCountry(product);
    final englishFields = await _normalizeToEnglish(
      category: rawCategory,
      ingredients: rawIngredients ?? const [],
      additives: rawAdditives,
      productAllergens: rawAllergens,
      originCountry: rawOriginCountry,
    );

    return OpenFoodProductExtraction(
      ingredients: rawIngredients == null ? null : englishFields.ingredients,
      additives: englishFields.additives,
      productAllergens: englishFields.productAllergens,
      category: englishFields.category,
      originCountry: englishFields.originCountry,
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

  static String? extractOriginCountry(Map<String, dynamic> product) {
    final originsTags = product["origins_tags"];
    if (originsTags is List && originsTags.isNotEmpty) {
      final first = originsTags.first.toString();
      return first.replaceFirst(RegExp(r"^[a-z]{2}:"), "");
    }

    final originsHierarchy = product["origins_hierarchy"];
    if (originsHierarchy is List && originsHierarchy.isNotEmpty) {
      final first = originsHierarchy.first.toString();
      return first.replaceFirst(RegExp(r"^[a-z]{2}:"), "");
    }

    final countriesTags = product["countries_tags"];
    if (countriesTags is List && countriesTags.isNotEmpty) {
      final first = countriesTags.first.toString();
      return first.replaceFirst(RegExp(r"^[a-z]{2}:"), "");
    }

    final origins = product["origins"]?.toString().trim();
    if (origins != null && origins.isNotEmpty) {
      return origins;
    }

    final countries = product["countries"]?.toString().trim();
    if (countries != null && countries.isNotEmpty) {
      return countries.replaceFirst(RegExp(r"^[a-z]{2}:"), "");
    }

    return null;
  }

  static String? extractCategory(Map<String, dynamic> product) {
    final categoriesTags = product["categories_tags"];
    if (categoriesTags is List && categoriesTags.isNotEmpty) {
      final first = categoriesTags.first.toString();
      return first.replaceFirst(RegExp(r"^[a-z]{2}:"), "");
    }

    final categoriesHierarchy = product["categories_hierarchy"];
    if (categoriesHierarchy is List && categoriesHierarchy.isNotEmpty) {
      final first = categoriesHierarchy.first.toString();
      return first.replaceFirst(RegExp(r"^[a-z]{2}:"), "");
    }

    final categories = product["categories"]?.toString().trim();
    if (categories != null && categories.isNotEmpty) {
      return categories.split(",").last.trim();
    }

    return null;
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

  static Future<_EnglishFoodFields> _normalizeToEnglish({
    required String? category,
    required List<String> ingredients,
    required List<String> additives,
    required List<String> productAllergens,
    required String? originCountry,
  }) async {
    if (ingredients.isEmpty &&
        (category == null || category.isEmpty) &&
        additives.isEmpty &&
        productAllergens.isEmpty &&
        (originCountry == null || originCountry.isEmpty)) {
      return _EnglishFoodFields(
        category: category,
        ingredients: ingredients,
        additives: additives,
        productAllergens: productAllergens,
        originCountry: originCountry,
      );
    }

    final prompt = '''
Translate the following packaged food extraction fields into English.

Rules:
- Return ONLY valid JSON.
- Keep numeric or coded values unchanged when already universal, such as E330.
- Translate category, ingredient, additive, allergen, and country text to natural English where needed.
- If a field is already English, keep it as is.
- Preserve list lengths and order as much as possible.

Return this exact JSON shape:
{
  "category": "string or null",
  "ingredients": ["item"],
  "additives": ["item"],
  "product_allergens": ["item"],
  "origin_country": "string or null"
}

Input JSON:
{
  "category": ${_jsonString(category)},
  "ingredients": ${_jsonList(ingredients)},
  "additives": ${_jsonList(additives)},
  "product_allergens": ${_jsonList(productAllergens)},
  "origin_country": ${_jsonString(originCountry)}
}
''';

    final raw = await OpenAIService.instance.callModel(prompt);
    final parsed = OpenAIService.extractJSON(raw);
    if (parsed.isEmpty) {
      return _EnglishFoodFields(
        category: category,
        ingredients: ingredients,
        additives: additives,
        productAllergens: productAllergens,
        originCountry: originCountry,
      );
    }

    return _EnglishFoodFields(
      category: parsed["category"]?.toString().trim() ?? category,
      ingredients: (parsed["ingredients"] as List?)
              ?.map((item) => item?.toString().trim() ?? "")
              .where((item) => item.isNotEmpty)
              .toList() ??
          ingredients,
      additives: (parsed["additives"] as List?)
              ?.map((item) => item?.toString().trim() ?? "")
              .where((item) => item.isNotEmpty)
              .toList() ??
          additives,
      productAllergens: (parsed["product_allergens"] as List?)
              ?.map((item) => item?.toString().trim().toLowerCase() ?? "")
              .where((item) => item.isNotEmpty)
              .toList() ??
          productAllergens,
      originCountry: parsed["origin_country"]?.toString().trim() ?? originCountry,
    );
  }

  static String _jsonString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "null";
    }
    return jsonEncode(value);
  }

  static String _jsonList(List<String> values) {
    return "[${values.map(_jsonString).join(", ")}]";
  }
}

class _EnglishFoodFields {
  final String? category;
  final List<String> ingredients;
  final List<String> additives;
  final List<String> productAllergens;
  final String? originCountry;

  const _EnglishFoodFields({
    required this.category,
    required this.ingredients,
    required this.additives,
    required this.productAllergens,
    required this.originCountry,
  });
}
