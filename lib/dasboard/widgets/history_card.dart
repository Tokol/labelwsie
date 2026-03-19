import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HistoryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onTap;

  const HistoryCard({
    super.key,
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
