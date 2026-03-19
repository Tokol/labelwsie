import 'package:flutter/material.dart';

class InsightsPage extends StatelessWidget {
  final List<Map<String, dynamic>> entries;

  const InsightsPage({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final insights = _InsightsData.fromEntries(entries);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F3),
      appBar: AppBar(
        title: const Text("Insights"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D5E3A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Your scan analytics dashboard",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6A7C6F),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle("Overview"),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: "Total Scans",
                  value: insights.totalScans.toString(),
                  subtitle: "Saved locally",
                  tone: const Color(0xFF2F7A4B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: "Unsafe Results",
                  value: insights.unsafeCount.toString(),
                  subtitle: "Need replacement",
                  tone: const Color(0xFF9B4233),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: "Avg Confidence",
                  value: insights.avgConfidenceLabel,
                  subtitle: "Analysis quality",
                  tone: const Color(0xFF456B9B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: "Alternatives Suggested",
                  value: insights.alternativesSuggested.toString(),
                  subtitle: "Unsafe support",
                  tone: const Color(0xFF8D5E11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle("Outcomes"),
          const SizedBox(height: 12),
          _InsightCard(
            title: "Status Breakdown",
            subtitle: "How your scanned products are currently distributed",
            child: _StatusBreakdown(insights: insights),
          ),
          const SizedBox(height: 24),
          _SectionTitle("Patterns"),
          const SizedBox(height: 12),
          _InsightCard(
            title: "Most Common Conflict Domains",
            subtitle: "Which preference checks most often flag your scanned foods",
            child: _RankedBars(
              emptyText: "No preference conflicts have been recorded yet.",
              items: insights.domainCounts,
              barColor: const Color(0xFF2F7A4B),
            ),
          ),
          const SizedBox(height: 12),
          _InsightCard(
            title: "Top Origins Scanned",
            subtitle: "Where your scanned products most commonly come from",
            child: _RankedBars(
              emptyText: "No origin data has been recorded yet.",
              items: insights.originCounts,
              barColor: const Color(0xFF456B9B),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle("Trends"),
          const SizedBox(height: 12),
          _InsightCard(
            title: "Weekly Scan Activity",
            subtitle: "How often you have been scanning products recently",
            child: _WeeklyTrend(entries: insights.weeklyCounts),
          ),
          const SizedBox(height: 12),
          _InsightCard(
            title: "Safe vs Unsafe Trend",
            subtitle: "How your scan outcomes are shifting over recent weeks",
            child: _DualTrend(
              entries: insights.safeUnsafeTrend,
              primaryLabel: "Safe",
              primaryColor: const Color(0xFF2F7A4B),
              secondaryLabel: "Unsafe",
              secondaryColor: const Color(0xFF9B4233),
              emptyText: "Not enough scan outcomes yet to compare safe and unsafe trends.",
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle("Confidence"),
          const SizedBox(height: 12),
          _InsightCard(
            title: "Confidence Distribution",
            subtitle: "How often your saved analyses land in low, medium, or high confidence",
            child: _ConfidenceDistribution(distribution: insights.confidenceDistribution),
          ),
          const SizedBox(height: 24),
          _SectionTitle("Categories"),
          const SizedBox(height: 12),
          _InsightCard(
            title: "Most Frequently Scanned Categories",
            subtitle: "Which food categories appear most often in your saved scan history",
            child: _RankedBars(
              emptyText: "No category data has been recorded yet.",
              items: insights.categoryCounts,
              barColor: const Color(0xFF6F8D45),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsData {
  final int totalScans;
  final int safeCount;
  final int warningCount;
  final int unsafeCount;
  final int cannotAssessCount;
  final int alternativesSuggested;
  final int? avgConfidence;
  final Map<String, int> domainCounts;
  final Map<String, int> originCounts;
  final Map<String, int> categoryCounts;
  final List<_TrendEntry> safeUnsafeTrend;
  final List<_ConfidenceBucket> confidenceDistribution;
  final List<MapEntry<String, int>> weeklyCounts;

  const _InsightsData({
    required this.totalScans,
    required this.safeCount,
    required this.warningCount,
    required this.unsafeCount,
    required this.cannotAssessCount,
    required this.alternativesSuggested,
    required this.avgConfidence,
    required this.domainCounts,
    required this.originCounts,
    required this.categoryCounts,
    required this.safeUnsafeTrend,
    required this.confidenceDistribution,
    required this.weeklyCounts,
  });

  String get avgConfidenceLabel =>
      avgConfidence == null ? "-" : "${avgConfidence!}%";

  factory _InsightsData.fromEntries(List<Map<String, dynamic>> entries) {
    var safe = 0;
    var warning = 0;
    var unsafe = 0;
    var cannotAssess = 0;
    var alternatives = 0;
    var confidenceSum = 0;
    var confidenceCount = 0;
    final domainCounts = <String, int>{};
    final originCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    final weeklyCounts = <int, int>{};
    final safeWeeklyCounts = <int, int>{};
    final unsafeWeeklyCounts = <int, int>{};
    var highConfidence = 0;
    var mediumConfidence = 0;
    var lowConfidence = 0;

    for (final entry in entries) {
      final status = entry["overallStatus"]?.toString().toLowerCase() ?? "";
      var isSafe = false;
      var isUnsafe = false;
      switch (status) {
        case "safe":
          safe++;
          isSafe = true;
          break;
        case "warning":
          warning++;
          break;
        case "unsafe":
        case "violation":
          unsafe++;
          isUnsafe = true;
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
        if (confidence >= 80) {
          highConfidence++;
        } else if (confidence >= 60) {
          mediumConfidence++;
        } else {
          lowConfidence++;
        }
      }

      final savedAlternatives = entry["alternatives"];
      if (savedAlternatives is List && savedAlternatives.isNotEmpty) {
        alternatives++;
      }

      final product = entry["product"];
      if (product is Map) {
        final origin = _extractOrigin(product);
        if (origin != null) {
          originCounts[origin] = (originCounts[origin] ?? 0) + 1;
        }
        final category = _extractCategory(product);
        if (category != null) {
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }

      final evaluationResults = entry["evaluationResults"];
      if (evaluationResults is Map) {
        evaluationResults.forEach((key, value) {
          if (value is! Map) return;
          final result = value["result"];
          if (result is! Map) return;

          var flagged = false;
          final resultStatus = result["status"]?.toString().toLowerCase();
          if (resultStatus == "unsafe" ||
              resultStatus == "warning" ||
              resultStatus == "violation") {
            flagged = true;
          }

          if (key == "allergy") {
            final summary = result["summary"];
            if (summary is Map) {
              final summaryStatus =
                  summary["status"]?.toString().toLowerCase() ?? "";
              if (summaryStatus == "unsafe" || summaryStatus == "warning") {
                flagged = true;
              }
            }
          }

          if (flagged) {
            final label = _domainTitle(key.toString());
            domainCounts[label] = (domainCounts[label] ?? 0) + 1;
          }
        });
      }

      final epochMillis = (entry["epochMillis"] as num?)?.toInt();
      if (epochMillis != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(epochMillis);
        final startOfWeek = DateTime(
          date.year,
          date.month,
          date.day,
        ).subtract(Duration(days: date.weekday - 1));
        final bucketKey = startOfWeek.millisecondsSinceEpoch;
        weeklyCounts[bucketKey] = (weeklyCounts[bucketKey] ?? 0) + 1;
        if (isSafe) {
          safeWeeklyCounts[bucketKey] = (safeWeeklyCounts[bucketKey] ?? 0) + 1;
        }
        if (isUnsafe) {
          unsafeWeeklyCounts[bucketKey] = (unsafeWeeklyCounts[bucketKey] ?? 0) + 1;
        }
      }
    }

    List<MapEntry<String, int>> sortMap(Map<String, int> input) {
      final list = input.entries.toList();
      list.sort((a, b) => b.value.compareTo(a.value));
      return list;
    }

    final sortedWeeklyEntries = weeklyCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final sortedWeekly = sortedWeeklyEntries
        .map(
          (entry) => MapEntry(
            _formatWeekRange(
              DateTime.fromMillisecondsSinceEpoch(entry.key),
            ),
            entry.value,
          ),
        )
        .toList();

    final trendBucketKeys = {
      ...safeWeeklyCounts.keys,
      ...unsafeWeeklyCounts.keys,
    }.toList()
      ..sort();

    final safeUnsafeTrend = trendBucketKeys
        .map(
          (bucketKey) => _TrendEntry(
            label: _formatWeekRange(
              DateTime.fromMillisecondsSinceEpoch(bucketKey),
            ),
            primaryValue: safeWeeklyCounts[bucketKey] ?? 0,
            secondaryValue: unsafeWeeklyCounts[bucketKey] ?? 0,
          ),
        )
        .toList();

    final confidenceDistribution = [
      _ConfidenceBucket("High", highConfidence, const Color(0xFF2F7A4B)),
      _ConfidenceBucket("Medium", mediumConfidence, const Color(0xFFB67817)),
      _ConfidenceBucket("Low", lowConfidence, const Color(0xFF9B4233)),
    ];

    return _InsightsData(
      totalScans: entries.length,
      safeCount: safe,
      warningCount: warning,
      unsafeCount: unsafe,
      cannotAssessCount: cannotAssess,
      alternativesSuggested: alternatives,
      avgConfidence:
          confidenceCount == 0 ? null : (confidenceSum / confidenceCount).round(),
      domainCounts: {for (final item in sortMap(domainCounts)) item.key: item.value},
      originCounts: {for (final item in sortMap(originCounts)) item.key: item.value},
      categoryCounts: {for (final item in sortMap(categoryCounts)) item.key: item.value},
      safeUnsafeTrend: safeUnsafeTrend,
      confidenceDistribution: confidenceDistribution,
      weeklyCounts: sortedWeekly,
    );
  }

  static String _domainTitle(String domain) {
    switch (domain) {
      case "religion":
        return "Religion";
      case "ethical":
        return "Ethical";
      case "allergy":
        return "Allergy";
      case "medical":
        return "Medical";
      case "lifestyle":
        return "Lifestyle";
      default:
        return domain;
    }
  }

  static String? _extractOrigin(Map product) {
    final origins = product["origins"]?.toString().trim();
    if (origins != null && origins.isNotEmpty) {
      return _normalizeCountryDisplay(origins.split(",").first.trim());
    }
    final countries = product["countries"]?.toString().trim();
    if (countries != null && countries.isNotEmpty) {
      return _normalizeCountryDisplay(
        countries.replaceFirst(RegExp(r"^[a-z]{2}:"), "").split(",").first.trim(),
      );
    }
    return null;
  }

  static String? _extractCategory(Map product) {
    final raw = product["categories"]?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final parts = raw
        .split(",")
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return null;
    }

    final preferred = parts.firstWhere(
      (part) => !part.contains(":"),
      orElse: () => parts.last,
    );

    return _normalizeCategoryDisplay(
      preferred.replaceFirst(RegExp(r"^[a-z]{2}:"), ""),
    );
  }

  static String _normalizeCountryDisplay(String value) {
    final raw = value.trim();
    switch (raw.toLowerCase()) {
      case "suomi":
        return "Finland";
      case "deutschland":
        return "Germany";
      case "sverige":
        return "Sweden";
      case "norge":
        return "Norway";
      case "españa":
      case "espana":
        return "Spain";
      case "italia":
        return "Italy";
      default:
        return raw;
    }
  }

  static String _normalizeCategoryDisplay(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return normalized;
    }

    final lower = normalized.toLowerCase();
    switch (lower) {
      case "fi:ruisleipä":
      case "ruisleipä":
        return "Rye Bread";
      default:
        final cleaned = normalized.replaceAll("-", " ");
        return cleaned
            .split(" ")
            .where((part) => part.isNotEmpty)
            .map(
              (part) => part[0].toUpperCase() + part.substring(1).toLowerCase(),
            )
            .join(" ");
    }
  }

  static String _formatWeekRange(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    final startMonth = months[startOfWeek.month - 1];
    final endMonth = months[endOfWeek.month - 1];

    if (startOfWeek.month == endOfWeek.month) {
      return "${startOfWeek.day}-${endOfWeek.day} $startMonth";
    }

    return "${startOfWeek.day} $startMonth-${endOfWeek.day} $endMonth";
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E5A39),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color tone;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7DD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6A7C6F),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: tone,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7A8B80),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _InsightCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7DD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF224D35),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF6A7C6F),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final _InsightsData insights;

  const _StatusBreakdown({required this.insights});

  @override
  Widget build(BuildContext context) {
    final total = insights.totalScans == 0 ? 1 : insights.totalScans;
    final items = [
      _BreakdownItem("Safe", insights.safeCount, const Color(0xFF2F7A4B)),
      _BreakdownItem("Warning", insights.warningCount, const Color(0xFFB67817)),
      _BreakdownItem("Unsafe", insights.unsafeCount, const Color(0xFF9B4233)),
      _BreakdownItem(
        "Cannot Assess",
        insights.cannotAssessCount,
        const Color(0xFF7A8B80),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                for (final item in items)
                  if (item.count > 0)
                    Expanded(
                      flex: item.count,
                      child: Container(color: item.color),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final item in items)
          if (item.count > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF31523F),
                      ),
                    ),
                  ),
                  Text(
                    "${item.count} (${((item.count / total) * 100).round()}%)",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6A7C6F),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _RankedBars extends StatelessWidget {
  final String emptyText;
  final Map<String, int> items;
  final Color barColor;

  const _RankedBars({
    required this.emptyText,
    required this.items,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        emptyText,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF6A7C6F),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final maxValue = items.values.first == 0 ? 1 : items.values.first;

    return Column(
      children: items.entries.take(5).map((entry) {
        final ratio = entry.value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF31523F),
                      ),
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6A7C6F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE7EFE9),
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _WeeklyTrend extends StatelessWidget {
  final List<MapEntry<String, int>> entries;

  const _WeeklyTrend({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text(
        "Not enough scan activity yet to show a trend.",
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF6A7C6F),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final trimmed = entries.length > 6 ? entries.sublist(entries.length - 6) : entries;
    final maxValue = trimmed.fold<int>(1, (max, entry) => entry.value > max ? entry.value : max);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: trimmed.map((entry) {
        final height = 26 + (72 * (entry.value / maxValue));
        final label = entry.key;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6A7C6F),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: const Color(0xFF456B9B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6A7C6F),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DualTrend extends StatelessWidget {
  final List<_TrendEntry> entries;
  final String primaryLabel;
  final Color primaryColor;
  final String secondaryLabel;
  final Color secondaryColor;
  final String emptyText;

  const _DualTrend({
    required this.entries,
    required this.primaryLabel,
    required this.primaryColor,
    required this.secondaryLabel,
    required this.secondaryColor,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(
        emptyText,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF6A7C6F),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final trimmed = entries.length > 6 ? entries.sublist(entries.length - 6) : entries;
    final maxValue = trimmed.fold<int>(
      1,
      (max, entry) {
        final localMax =
            entry.primaryValue > entry.secondaryValue ? entry.primaryValue : entry.secondaryValue;
        return localMax > max ? localMax : max;
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendChip(label: primaryLabel, color: primaryColor),
            const SizedBox(width: 8),
            _LegendChip(label: secondaryLabel, color: secondaryColor),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: trimmed.map((entry) {
            final primaryHeight = 18 + (58 * (entry.primaryValue / maxValue));
            final secondaryHeight = 18 + (58 * (entry.secondaryValue / maxValue));
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${entry.primaryValue}/${entry.secondaryValue}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6A7C6F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            height: primaryHeight,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: secondaryHeight,
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6A7C6F),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ConfidenceDistribution extends StatelessWidget {
  final List<_ConfidenceBucket> distribution;

  const _ConfidenceDistribution({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final total = distribution.fold<int>(0, (sum, item) => sum + item.count);
    if (total == 0) {
      return const Text(
        "No saved confidence data is available yet.",
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF6A7C6F),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                for (final item in distribution)
                  if (item.count > 0)
                    Expanded(
                      flex: item.count,
                      child: Container(color: item.color),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final item in distribution)
          if (item.count > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF31523F),
                      ),
                    ),
                  ),
                  Text(
                    "${item.count} (${((item.count / total) * 100).round()}%)",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6A7C6F),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem {
  final String label;
  final int count;
  final Color color;

  const _BreakdownItem(this.label, this.count, this.color);
}

class _TrendEntry {
  final String label;
  final int primaryValue;
  final int secondaryValue;

  const _TrendEntry({
    required this.label,
    required this.primaryValue,
    required this.secondaryValue,
  });
}

class _ConfidenceBucket {
  final String label;
  final int count;
  final Color color;

  const _ConfidenceBucket(this.label, this.count, this.color);
}
