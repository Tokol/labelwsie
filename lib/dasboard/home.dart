import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show File;

import 'insights_page.dart';
import 'result_page.dart';
import 'services/scan_history_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _destructiveTone = Color(0xFF8A5A46);
  static const _destructiveFill = Color(0xFFA7654F);

  Future<void> _refresh() async {
    setState(() {});
    await ScanHistoryService.readEntries();
  }

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    await ScanHistoryService.deleteEntry((entry["epochMillis"] as num?)?.toInt());
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${_entryName(entry)} removed from history",
        ),
      ),
    );
  }

  Future<void> _clearAllEntries() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text("Clear history?"),
              content: const Text(
                "This will remove all saved scan results from your device.",
                style: TextStyle(
                  color: Color(0xFF6A7C6F),
                  fontWeight: FontWeight.w500,
                ),
              ),
              titleTextStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF224D35),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2F7A4B),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: TextButton.styleFrom(
                    foregroundColor: _destructiveTone,
                  ),
                  child: const Text(
                    "Delete all",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    await ScanHistoryService.clearAll();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Scan history cleared"),
      ),
    );
  }

  String _entryName(Map<String, dynamic> entry) {
    final name = entry["productName"]?.toString().trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return "Product";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F3),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: ScanHistoryService.readEntries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final entries = snapshot.data ?? const [];
            if (entries.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  children: const [
                    SizedBox(height: 120),
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 58,
                      color: Color(0xFF9AAF9D),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "No scan history yet",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF29543A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Your scanned product results will appear here for quick access.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Color(0xFF6A7C6F),
                      ),
                    ),
                  ],
                ),
              );
            }

            final insights = _HomeInsights.fromEntries(entries);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  const Text(
                    "Home",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E5A39),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Your recent food analysis insights and scan history",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF6A7C6F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInsightsPreview(context, insights, entries),
                  const SizedBox(height: 20),
                  const Text(
                    "Recent History",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E5A39),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${entries.length} saved scan${entries.length == 1 ? "" : "s"}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6A7C6F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearAllEntries,
                        style: TextButton.styleFrom(
                          foregroundColor: _destructiveTone,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          "Delete all",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < entries.length; i++) ...[
                    Dismissible(
                      key: ValueKey(
                        (entries[i]["epochMillis"] as num?)?.toInt() ??
                            entries[i].hashCode,
                      ),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: _destructiveFill,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Delete",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  backgroundColor: Colors.white,
                                  surfaceTintColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  title: const Text("Delete this scan?"),
                                  content: Text(
                                    "Remove ${_entryName(entries[i])} from your saved history?",
                                    style: const TextStyle(
                                      color: Color(0xFF6A7C6F),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  titleTextStyle: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF224D35),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF2F7A4B),
                                      ),
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: _destructiveTone,
                                      ),
                                      child: const Text(
                                        "Delete",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ) ??
                            false;
                      },
                      onDismissed: (_) {
                        _deleteEntry(entries[i]);
                      },
                      child: _HistoryCard(
                        entry: entries[i],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResultPage(
                                product: Map<String, dynamic>.from(
                                  entries[i]["product"] as Map? ?? const {},
                                ),
                                ingredients: (entries[i]["ingredients"] as List?)
                                        ?.map((e) => e.toString())
                                        .toList() ??
                                    const [],
                                additives: (entries[i]["additives"] as List?)
                                        ?.map((e) => e.toString())
                                        .toList() ??
                                    const [],
                                allergens: (entries[i]["allergens"] as List?)
                                        ?.map((e) => e.toString())
                                        .toList() ??
                                    const [],
                                nutriments: (entries[i]["nutriments"] as Map?)
                                        ?.map(
                                          (key, value) => MapEntry(
                                            key.toString(),
                                            (value as num).toDouble(),
                                          ),
                                        ) ??
                                    const {},
                                nutrientLevels:
                                    (entries[i]["nutrientLevels"] as Map?)
                                            ?.map(
                                              (key, value) => MapEntry(
                                                key.toString(),
                                                value.toString(),
                                              ),
                                            ) ??
                                        const {},
                                nutriScore: entries[i]["nutriScore"]?.toString(),
                                novaGroup:
                                    (entries[i]["novaGroup"] as num?)?.toInt(),
                                ranEvaluations:
                                    (entries[i]["ranEvaluations"] as List?)
                                            ?.map((e) => e.toString())
                                            .toList() ??
                                        const [],
                                evaluationResults:
                                    (entries[i]["evaluationResults"] as Map?)
                                            ?.map(
                                              (key, value) => MapEntry(
                                                key.toString(),
                                                Map<String, dynamic>.from(
                                                  value as Map? ?? const {},
                                                ),
                                              ),
                                            ) ??
                                        const {},
                                userMarketCountry:
                                    entries[i]["userMarketCountry"]?.toString(),
                                userMarketCountrySource:
                                    entries[i]["userMarketCountrySource"]
                                            ?.toString() ??
                                        "unavailable",
                                historyEpochMillis:
                                    (entries[i]["epochMillis"] as num?)?.toInt(),
                                isHistoryEntry: true,
                                initialTips: (entries[i]["tips"] as List?)
                                        ?.map((e) => e.toString())
                                        .toList() ??
                                    const [],
                                initialTipsConfidencePercent:
                                    (entries[i]["tipsConfidencePercent"] as num?)
                                        ?.toInt(),
                                initialAlternatives:
                                    (entries[i]["alternatives"] as List?)
                                            ?.whereType<Map>()
                                            .map(
                                              (item) =>
                                                  Map<String, dynamic>.from(item),
                                            )
                                            .toList() ??
                                        const [],
                                initialAlternativesConfidencePercent:
                                    (entries[i]["alternativesConfidencePercent"]
                                            as num?)
                                        ?.toInt(),
                              ),
                            ),
                          );
                          if (!mounted) return;
                          setState(() {});
                        },
                      ),
                    ),
                    if (i != entries.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInsightsPreview(
    BuildContext context,
    _HomeInsights insights,
    List<Map<String, dynamic>> entries,
  ) {
    final statusItems = [
      _BreakdownItem(
        label: "Safe",
        count: insights.safeCount,
        color: const Color(0xFF2F7A4B),
      ),
      _BreakdownItem(
        label: "Warning",
        count: insights.warningCount,
        color: const Color(0xFFB67817),
      ),
      _BreakdownItem(
        label: "Unsafe",
        count: insights.unsafeCount,
        color: const Color(0xFF9B4233),
      ),
      _BreakdownItem(
        label: "Cannot Assess",
        count: insights.cannotAssessCount,
        color: const Color(0xFF7A8B80),
      ),
    ];

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Insights Preview",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF224D35),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InsightsPage(entries: entries),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF456B9B),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "See insights",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${insights.totalScans} scans, ${insights.unsafeCount} unsafe, ${insights.avgConfidenceLabel} avg confidence",
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF6A7C6F),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (final item in statusItems)
                    if (item.count > 0)
                      Expanded(
                        flex: item.count,
                        child: Container(color: item.color),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _HomeInsights {
  final int totalScans;
  final int safeCount;
  final int warningCount;
  final int unsafeCount;
  final int cannotAssessCount;
  final int alternativesTriggered;
  final int? avgConfidence;

  const _HomeInsights({
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

  factory _HomeInsights.fromEntries(List<Map<String, dynamic>> entries) {
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

    return _HomeInsights(
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

class _BreakdownItem {
  final String label;
  final int count;
  final Color color;

  const _BreakdownItem({
    required this.label,
    required this.count,
    required this.color,
  });
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = entry["productImage"]?.toString();
    final isNetworkLike = imageUrl != null &&
        (imageUrl.startsWith("http://") ||
            imageUrl.startsWith("https://") ||
            imageUrl.startsWith("blob:") ||
            imageUrl.startsWith("data:"));
    final name = entry["productName"]?.toString().trim().isNotEmpty == true
        ? entry["productName"].toString().trim()
        : "Unnamed product";
    final overallStatus =
        entry["overallStatus"]?.toString().trim().isNotEmpty == true
            ? entry["overallStatus"].toString().trim()
            : "Unknown";
    final confidence = (entry["analysisConfidencePercent"] as num?)?.toInt();
    final epochMillis = (entry["epochMillis"] as num?)?.toInt();
    final dateLabel = _formatEpoch(epochMillis);
    final colors = _statusColors(overallStatus);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              width: 76,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F2F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: imageUrl == null || imageUrl.isEmpty
                  ? const Icon(
                      Icons.image_outlined,
                      color: Color(0xFF9AA7B5),
                      size: 34,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isNetworkLike || kIsWeb
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image_outlined,
                                color: Color(0xFF9AA7B5),
                                size: 34,
                              ),
                            )
                          : Image.file(
                              File(imageUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image_outlined,
                                color: Color(0xFF9AA7B5),
                                size: 34,
                              ),
                            ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF224D35),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF728579),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.$2,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: colors.$3),
                        ),
                        child: Text(
                          overallStatus,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: colors.$1,
                          ),
                        ),
                      ),
                      if (confidence != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8FA),
                            borderRadius: BorderRadius.circular(999),
                            border:
                                Border.all(color: const Color(0xFFD8E1E9)),
                          ),
                          child: Text(
                            "$confidence% confidence",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF546575),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF7A8E81),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEpoch(int? epochMillis) {
    if (epochMillis == null) return "Unknown time";
    final date = DateTime.fromMillisecondsSinceEpoch(epochMillis);
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
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, "0");
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, "0");
    final minute = date.minute.toString().padLeft(2, "0");
    return "$day $month $year • $hour:$minute";
  }

  (Color, Color, Color) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case "safe":
        return (
          const Color(0xFF2F7A4B),
          const Color(0xFFE8F6EC),
          const Color(0xFFCDE7D4),
        );
      case "warning":
      case "cannot assess":
        return (
          const Color(0xFF9A6414),
          const Color(0xFFFBF1DD),
          const Color(0xFFF0D8A9),
        );
      case "violation":
      case "unsafe":
        return (
          const Color(0xFF9B4233),
          const Color(0xFFFBE7E4),
          const Color(0xFFF0C3BC),
        );
      default:
        return (
          const Color(0xFF56685C),
          const Color(0xFFF1F4F2),
          const Color(0xFFD7E0D9),
        );
    }
  }
}
