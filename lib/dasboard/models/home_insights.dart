class HomeInsights {
  final int totalScans;
  final int safeCount;
  final int warningCount;
  final int unsafeCount;
  final int cannotAssessCount;
  final int alternativesTriggered;
  final int? avgConfidence;

  const HomeInsights({
    required this.totalScans,
    required this.safeCount,
    required this.warningCount,
    required this.unsafeCount,
    required this.cannotAssessCount,
    required this.alternativesTriggered,
    required this.avgConfidence,
  });

  String get avgConfidenceLabel =>
      avgConfidence == null ? "-" : "${avgConfidence!}%";

  factory HomeInsights.fromEntries(List<Map<String, dynamic>> entries) {
    var safe = 0;
    var warning = 0;
    var unsafe = 0;
    var cannotAssess = 0;
    var alternatives = 0;
    var confidenceSum = 0;
    var confidenceCount = 0;

    for (final entry in entries) {
      final status = entry["overallStatus"]?.toString().toLowerCase() ?? "";
      switch (status) {
        case "safe":
          safe++;
          break;
        case "warning":
          warning++;
          break;
        case "unsafe":
        case "violation":
          unsafe++;
          break;
        case "cannot assess":
        case "cannot_assess":
          cannotAssess++;
          break;
      }

      final confidence = (entry["analysisConfidencePercent"] as num?)?.toInt();
      if (confidence != null) {
        confidenceSum += confidence;
        confidenceCount++;
      }

      final savedAlternatives = entry["alternatives"];
      if (savedAlternatives is List && savedAlternatives.isNotEmpty) {
        alternatives++;
      }
    }

    return HomeInsights(
      totalScans: entries.length,
      safeCount: safe,
      warningCount: warning,
      unsafeCount: unsafe,
      cannotAssessCount: cannotAssess,
      alternativesTriggered: alternatives,
      avgConfidence:
          confidenceCount == 0 ? null : (confidenceSum / confidenceCount).round(),
    );
  }
}
