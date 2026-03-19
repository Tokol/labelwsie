import 'dart:convert';

import '../../ai/services.dart';

class PhotoValidationResult {
  final bool isFoodPackage;
  final bool isUsableForAnalysis;
  final String imageType;
  final int confidence;
  final String reason;
  final String nextAction;

  const PhotoValidationResult({
    required this.isFoodPackage,
    required this.isUsableForAnalysis,
    required this.imageType,
    required this.confidence,
    required this.reason,
    required this.nextAction,
  });

  factory PhotoValidationResult.fromJson(Map<String, dynamic> json) {
    return PhotoValidationResult(
      isFoodPackage: json["is_food_package"] == true,
      isUsableForAnalysis: json["is_usable_for_analysis"] == true,
      imageType: json["image_type"]?.toString() ?? "unknown",
      confidence: (json["confidence"] as num?)?.toInt() ?? 0,
      reason: json["reason"]?.toString() ?? "Validation result unavailable.",
      nextAction: json["next_action"]?.toString() ?? "retake",
    );
  }

  bool get canProceed => isFoodPackage && isUsableForAnalysis;
}

class PhotoValidationService {
  PhotoValidationService._();

  static Future<PhotoValidationResult> validateImage({
    required String imageDataUrl,
  }) async {
    final prompt = '''
You are validating whether an uploaded image is usable for packaged food analysis.

Rules:
- Return ONLY valid JSON.
- Be strict. Do not assume missing details.
- Decide whether the image is of a packaged food product or a packaged food label.
- Decide whether the image is usable for ingredient-based food analysis.
- If the image is not a packaged food product/label, mark it invalid.
- If the text or label is too blurry, too far, cut off, or unreadable, mark it not usable.

Allowed values:
- image_type: "front_of_pack", "ingredients_panel", "nutrition_panel", "food_package_other", "not_food_package", "unknown"
- next_action: "proceed", "retake_food_package", "retake_clear_ingredients"

Return this exact JSON shape:
{
  "is_food_package": true,
  "is_usable_for_analysis": false,
  "image_type": "front_of_pack",
  "confidence": 88,
  "reason": "This is a packaged food product, but the ingredient list is not visible clearly enough.",
  "next_action": "retake_clear_ingredients"
}
''';

    final raw = await OpenAIService.instance.callImageModel(
      prompt: prompt,
      imageDataUrl: imageDataUrl,
    );

    final parsed = OpenAIService.extractJSON(raw);
    if (parsed.isEmpty) {
      return const PhotoValidationResult(
        isFoodPackage: false,
        isUsableForAnalysis: false,
        imageType: "unknown",
        confidence: 0,
        reason: "We could not validate this photo. Please retake a clear food package image.",
        nextAction: "retake_food_package",
      );
    }

    return PhotoValidationResult.fromJson(
      Map<String, dynamic>.from(parsed),
    );
  }

  static String toDataUrl(List<int> bytes, {String mimeType = "image/jpeg"}) {
    final encoded = base64Encode(bytes);
    return "data:$mimeType;base64,$encoded";
  }
}
