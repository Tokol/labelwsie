import 'package:flutter/material.dart';

import '../result_page.dart';

class HistoryEntryResultMapper {
  const HistoryEntryResultMapper._();

  static ResultPage build(Map<String, dynamic> entry) {
    return ResultPage(
      product: Map<String, dynamic>.from(entry["product"] as Map? ?? const {}),
      ingredients: (entry["ingredients"] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      additives:
          (entry["additives"] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      allergens:
          (entry["allergens"] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      nutriments: (entry["nutriments"] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              (value as num).toDouble(),
            ),
          ) ??
          const {},
      nutrientLevels: (entry["nutrientLevels"] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              value.toString(),
            ),
          ) ??
          const {},
      nutriScore: entry["nutriScore"]?.toString(),
      novaGroup: (entry["novaGroup"] as num?)?.toInt(),
      ranEvaluations:
          (entry["ranEvaluations"] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      evaluationResults: (entry["evaluationResults"] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              Map<String, dynamic>.from(value as Map? ?? const {}),
            ),
          ) ??
          const {},
      userMarketCountry: entry["userMarketCountry"]?.toString(),
      userMarketCountrySource:
          entry["userMarketCountrySource"]?.toString() ?? "unavailable",
      historyEpochMillis: (entry["epochMillis"] as num?)?.toInt(),
      isHistoryEntry: true,
      initialTips:
          (entry["tips"] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      initialTipsConfidencePercent:
          (entry["tipsConfidencePercent"] as num?)?.toInt(),
      initialAlternatives: (entry["alternatives"] as List?)
              ?.whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList() ??
          const [],
      initialAlternativesConfidencePercent:
          (entry["alternativesConfidencePercent"] as num?)?.toInt(),
    );
  }
}
