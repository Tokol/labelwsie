import '../../ai/services.dart';

class PhotoExtractionResult {
  final Map<String, dynamic> product;
  final List<String> ingredients;
  final List<String> additives;
  final List<String> productAllergens;
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

Return this exact JSON shape:
{
  "product_name": "string or null",
  "brand": "string or null",
  "ingredients": ["ingredient 1", "ingredient 2"],
  "additives": ["E330"],
  "product_allergens": ["milk", "gluten"],
  "nutriments": {
    "energy_kcal": 0,
    "fat": 0,
    "saturated_fat": 0,
    "carbohydrates": 0,
    "sugars": 0,
    "fiber": 0,
    "protein": 0,
    "salt": 0,
    "sodium": 0
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

    final ingredients = (parsed["ingredients"] as List?)
            ?.map((item) => item?.toString().trim() ?? "")
            .where((item) => item.isNotEmpty)
            .toList() ??
        const <String>[];
    if (ingredients.isEmpty) return null;

    final additives = (parsed["additives"] as List?)
            ?.map((item) => item?.toString().trim() ?? "")
            .where((item) => item.isNotEmpty)
            .toList() ??
        const <String>[];

    final productAllergens = (parsed["product_allergens"] as List?)
            ?.map((item) => item?.toString().trim().toLowerCase() ?? "")
            .where((item) => item.isNotEmpty)
            .toList() ??
        const <String>[];

    final nutriments = _parseNutriments(parsed["nutriments"]);
    final nutrientLevels = _deriveNutrientLevels(nutriments);
    final nutriScore = _parseNutriScore(parsed["nutri_score"]);
    final novaGroup = _parseNovaGroup(parsed["nova_group"]);
    final originCountry = parsed["origin_country"]?.toString().trim();

    final product = <String, dynamic>{
      "code": barcode,
      "product_name": parsed["product_name"]?.toString().trim(),
      "brands": parsed["brand"]?.toString().trim(),
      "ingredients_text": ingredients.join(", "),
      "allergens": productAllergens.join(", "),
      if (originCountry != null && originCountry.isNotEmpty) "origins": originCountry,
      if (localImagePath != null && localImagePath.isNotEmpty)
        "image_url": localImagePath,
      if (localImagePath != null && localImagePath.isNotEmpty)
        "local_image_path": localImagePath,
      "image_source": "local_capture",
    };

    return PhotoExtractionResult(
      product: product,
      ingredients: ingredients,
      additives: additives,
      productAllergens: productAllergens,
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
}
