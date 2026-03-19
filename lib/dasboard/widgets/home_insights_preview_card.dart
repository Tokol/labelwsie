import 'package:flutter/material.dart';

import '../insights_page.dart';
import '../models/home_insights.dart';

class HomeInsightsPreviewCard extends StatelessWidget {
  final HomeInsights insights;
  final List<Map<String, dynamic>> entries;

  const HomeInsightsPreviewCard({
    super.key,
    required this.insights,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
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
