import 'package:flutter/material.dart';

import 'models/home_insights.dart';
import 'services/history_entry_result_mapper.dart';
import 'services/scan_history_service.dart';
import 'widgets/history_card.dart';
import 'widgets/home_insights_preview_card.dart';

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

            final insights = HomeInsights.fromEntries(entries);

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
                  HomeInsightsPreviewCard(
                    insights: insights,
                    entries: entries,
                  ),
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
                      child: HistoryCard(
                        entry: entries[i],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  HistoryEntryResultMapper.build(entries[i]),
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

}
