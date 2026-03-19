import 'package:hive_ce/hive.dart';

class ScanHistoryService {
  ScanHistoryService._();

  static const _boxName = "app_data";
  static const _historyKey = "scan_history";

  static Future<List<Map<String, dynamic>>> readEntries() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get(_historyKey);
    if (raw is! List) return const [];

    final entries = raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    entries.sort((a, b) {
      final aTs = (a["epochMillis"] as num?)?.toInt() ?? 0;
      final bTs = (b["epochMillis"] as num?)?.toInt() ?? 0;
      return bTs.compareTo(aTs);
    });

    return entries;
  }

  static Future<void> upsertEntry(Map<String, dynamic> entry) async {
    final box = await Hive.openBox(_boxName);
    final existing = await readEntries();
    final epochMillis = (entry["epochMillis"] as num?)?.toInt();

    final next = existing
        .where((item) => (item["epochMillis"] as num?)?.toInt() != epochMillis)
        .toList();
    next.insert(0, Map<String, dynamic>.from(entry));

    await box.put(_historyKey, next);
  }

  static Future<void> deleteEntry(int? epochMillis) async {
    if (epochMillis == null) return;

    final box = await Hive.openBox(_boxName);
    final existing = await readEntries();
    final next = existing
        .where((item) => (item["epochMillis"] as num?)?.toInt() != epochMillis)
        .toList();

    await box.put(_historyKey, next);
  }

  static Future<void> clearAll() async {
    final box = await Hive.openBox(_boxName);
    await box.put(_historyKey, <Map<String, dynamic>>[]);
  }
}
