import 'dart:convert';

import '../../ai/services.dart';

class PhotoExtractionResult {
  final Map<String, dynamic> product;
  final List<String> ingredients;
  final List<String> additives;
  final List<String> productAllergens;
  final String? category;
  final Map<String, double> nutriments;
  final Map<String, String> nutrientLevels;
  final String? nutriScore;
  final int? novaGroup;
  final int confidence;

  const PhotoExtractionResult({
    required this.product,
    required this.ingredients,
    required this.additives,
    required this.productAllergens,
    required this.category,
    required this.nutriments,
    required this.nutrientLevels,
    required this.nutriScore,
    required this.novaGroup,
    required this.confidence,
  });
}

class PhotoExtractionService {
  PhotoExtractionService._();

  static Future<PhotoExtractionResult?> extract({
    required String imageDataUrl,
    required String barcode,
    required String? localImagePath,
  }) async {
    final prompt = '''
You are extracting packaged food information from a validated food package image.

Rules:
- Return ONLY valid JSON.
- Extract only what is visible or safely inferable from the package text.
- Do not invent nutrition facts, origin country, Nutri-Score, or NOVA group.
- If a value is not visible, return null or an empty list.
- Ingredients are required if visible.
- Keep product name and brand in their original market form.
- Return descriptive textual fields in English.
- Translate non-English ingredient, additive, allergen, and origin labels into English.

Return this exact JSON shape:
{
  "product_name": "string or null",
  "brand": "string or null",
  "category": "string or null",
  "ingredients": ["ingredient 1", "ingredient 2"],
  "additives": ["E330"],
  "product_allergens": ["milk", "gluten"],
  "nutriments": {
    "energy_kcal": null,
    "fat": null,
    "saturated_fat": null,
    "carbohydrates": null,
    "sugars": null,
    "fiber": null,
    "protein": null,
    "salt": null,
    "sodium": null
  },
  "nutri_score": null,
  "nova_group": null,
  "origin_country": null,
  "confidence": 0
}
''';

    final raw = await OpenAIService.instance.callImageModel(
      prompt: prompt,
      imageDataUrl: imageDataUrl,
    );

    final parsed = OpenAIService.extractJSON(raw);
    if (parsed.isEmpty) return null;

    final rawIngredients = (parsed["ingredients"] as List?)
            ?.map((item) => item?.toString().trim() ?? "")
            .where((item) => item.isNotEmpty)
            .toList() ??
        const <String>[];
    if (rawIngredients.isEmpty) return null;

    final rawAdditives = (parsed["additives"] as List?)
            ?.map((item) => item?.toString().trim() ?? "")
            .where((item) => item.isNotEmpty)
            .toList() ??
        const <String>[];

    final rawProductAllergens = (parsed["product_allergens"] as List?)
            ?.map((item) => item?.toString().trim().toLowerCase() ?? "")
            .where((item) => item.isNotEmpty)
            .toList() ??
        const <String>[];

    final nutriments = _parseNutriments(parsed["nutriments"]);
    final nutrientLevels = _deriveNutrientLevels(nutriments);
    final nutriScore = _parseNutriScore(parsed["nutri_score"]);
    final novaGroup = _parseNovaGroup(parsed["nova_group"]);
    final normalizedFields = await _normalizeToEnglish(
      category: parsed["category"]?.toString().trim(),
      ingredients: rawIngredients,
      additives: rawAdditives,
      productAllergens: rawProductAllergens,
      originCountry: parsed["origin_country"]?.toString().trim(),
    );

    final product = <String, dynamic>{
      "code": barcode,
      "product_name": parsed["product_name"]?.toString().trim(),
      "brands": parsed["brand"]?.toString().trim(),
      if (normalizedFields.category != null && normalizedFields.category!.isNotEmpty)
        "categories": normalizedFields.category,
      "ingredients_text": normalizedFields.ingredients.join(", "),
      "allergens": normalizedFields.productAllergens.join(", "),
      if (normalizedFields.originCountry != null &&
          normalizedFields.originCountry!.isNotEmpty)
        "origins": normalizedFields.originCountry,
      if (localImagePath != null && localImagePath.isNotEmpty)
        "image_url": localImagePath,
      if (localImagePath != null && localImagePath.isNotEmpty)
        "local_image_path": localImagePath,
      "image_source": "local_capture",
    };

    return PhotoExtractionResult(
      product: product,
      ingredients: normalizedFields.ingredients,
      additives: normalizedFields.additives,
      productAllergens: normalizedFields.productAllergens,
      category: normalizedFields.category,
      nutriments: nutriments,
      nutrientLevels: nutrientLevels,
      nutriScore: nutriScore,
      novaGroup: novaGroup,
      confidence: (parsed["confidence"] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, double> _parseNutriments(dynamic raw) {
    if (raw is! Map) return {};
    final result = <String, double>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is num) {
        result[entry.key.toString()] = value.toDouble();
      }
    }
    return result;
  }

  static Map<String, String> _deriveNutrientLevels(
    Map<String, double> nutriments,
  ) {
    final levels = <String, String>{};

    String level(double value, double low, double moderate) {
      if (value <= low) return "low";
      if (value <= moderate) return "moderate";
      return "high";
    }

    if (nutriments.containsKey("fat")) {
      levels["fat"] = level(nutriments["fat"]!, 3, 17.5);
    }
    if (nutriments.containsKey("saturated_fat")) {
      levels["saturated-fat"] = level(nutriments["saturated_fat"]!, 1.5, 5);
    }
    if (nutriments.containsKey("sugars")) {
      levels["sugars"] = level(nutriments["sugars"]!, 5, 22.5);
    }
    if (nutriments.containsKey("salt")) {
      levels["salt"] = level(nutriments["salt"]!, 0.3, 1.5);
    }

    return levels;
  }

  static String? _parseNutriScore(dynamic raw) {
    final value = raw?.toString().trim().toUpperCase();
    if (value == null || value.isEmpty || value == "NULL") return null;
    if (!RegExp(r"^[A-E]$").hasMatch(value)) return null;
    return value;
  }

  static int? _parseNovaGroup(dynamic raw) {
    if (raw is num) {
      final value = raw.toInt();
      if (value >= 1 && value <= 4) return value;
    }
    return null;
  }

  static Future<_EnglishExtractionFields> _normalizeToEnglish({
    required String? category,
    required List<String> ingredients,
    required List<String> additives,
    required List<String> productAllergens,
    required String? originCountry,
  }) async {
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
      return _EnglishExtractionFields(
        category: category,
        ingredients: ingredients,
        additives: additives,
        productAllergens: productAllergens,
        originCountry: originCountry,
      );
    }

    return _EnglishExtractionFields(
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
      originCountry: parsed["origin_country"]?.toString().trim(),
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

class _EnglishExtractionFields {
  final String? category;
  final List<String> ingredients;
  final List<String> additives;
  final List<String> productAllergens;
  final String? originCountry;

  const _EnglishExtractionFields({
    required this.category,
    required this.ingredients,
    required this.additives,
    required this.productAllergens,
    required this.originCountry,
  });
}
