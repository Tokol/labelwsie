// lib/state/pref_store.dart
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

class PreferenceStore extends ChangeNotifier {
  Map<String, dynamic> prefs = {};
  bool isLoading = true;
  bool hasLoadedOnce = false;

  PreferenceStore() {
    loadPrefs();
  }

  Future<void> loadPrefs() async {
    isLoading = true;
    notifyListeners();

    final box = await Hive.openBox("app_data");

    prefs = {
      "religion": box.get("religion_pref"),
      "ethical": box.get("ethical_pref"),
      "allergy": box.get("allergy_pref"),
      "medical": box.get("medical_pref"),
      "lifestyle": box.get("life_style_pref"),
    };

    isLoading = false;
    hasLoadedOnce = true;
    notifyListeners();
  }

  Future<void> update(String key, dynamic value) async {
    final box = await Hive.openBox("app_data");
    await box.put(key, value);
    await loadPrefs(); // refresh + notify
  }

  Future<void> clear(String key) async {
    final box = await Hive.openBox("app_data");
    await box.delete(key);
    await loadPrefs();
  }
}

