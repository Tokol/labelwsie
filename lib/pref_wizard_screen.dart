import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'diet_pref/condition_list_sheet.dart';
import 'diet_pref/pref_screen/allergy_pref_screen.dart';
import 'diet_pref/pref_screen/ethical_pref_screen.dart';
import 'diet_pref/pref_screen/helper/ehical_choices.dart';
import 'diet_pref/pref_screen/helper/strictness_loader.dart';
import 'diet_pref/pref_screen/medical_pref_screen.dart';
import 'diet_pref/pref_screen/pref_lifestyle.dart';
import 'diet_pref/pref_screen/religion_pref_screen.dart';
import 'diet_pref/pref_screen/religion_strickness.dart';
import 'state/pref_store.dart';

class PreferencesWizardScreen extends StatefulWidget {
  final Map<String, bool> selected;
  final Map<String, dynamic>? initialData;
  final bool fromProfile;

  const PreferencesWizardScreen({
    super.key,
    required this.selected,
    this.initialData,
    this.fromProfile = false,
  });

  @override
  State<PreferencesWizardScreen> createState() =>
      _PreferencesWizardScreenState();
}

class _PreferencesWizardScreenState extends State<PreferencesWizardScreen> {
  final PageController _controller = PageController();

  int currentIndex = 0;
  bool canProceed = false;

  // Religion
  String? chosenReligion;
  String? chosenStrictness;
  String? initialReligion;
  String? initialStrictness;

  // Ethical
  Set<String> ethicalChoices = {};
  Set<String>? _initialEthicalIds;

  // Allergy
  Set<String> chosenAllergens = {};
  Set<String> chosenSensitivities = {};
  List<String> customAllergens = [];

  // Medical
  Set<String> selectedMedical = {};
  Map<String, Map<String, bool>> selectedMedicalRestrictions = {};

  // Lifestyle
  List<Map<String, dynamic>> selectedLifestyleGoals = [];

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;
    if (data != null) {
      initialReligion = data["initialReligion"];
      initialStrictness = data["initialStrictness"];

      if (data["ethicalIds"] != null) {
        _initialEthicalIds = Set<String>.from(data["ethicalIds"]);
      }
    }

    pages = _buildPages();
  }

  List<Widget> _buildPages() {
    final list = <Widget>[];

    // RELIGION
    if (widget.selected["religion"] == true) {
      list.add(
        ReligionSelectionPage(
          initialSelectedReligion: initialReligion,
          onSelected: (v) => chosenReligion = v,
          onStateChanged: (ok) => setState(() => canProceed = ok),
        ),
      );

      list.add(
        ReligionStrictnessPage(
          getReligion: () => chosenReligion ?? initialReligion!,
          initialStrictness: initialStrictness,
          onSelected: (v) => chosenStrictness = v,
          onStateChanged: (ok) => setState(() => canProceed = ok),
        ),
      );
    }

    // ETHICAL
    if (widget.selected["ethical"] == true) {
      list.add(
        EthicalChoicesScreen(
          initialSelectedIds: _initialEthicalIds,
          onChanged: (ids) {
            ethicalChoices = ids;
            setState(() => canProceed = ids.isNotEmpty);
          },
        ),
      );
    }

    // ALLERGY
    if (widget.selected["allergy"] == true) {
      final initialA = widget.initialData?["initialAllergens"] as List<dynamic>? ?? [];
      final initialS = widget.initialData?["initialSensitivities"] as List<dynamic>? ?? [];
      final initialC = widget.initialData?["initialCustom"] as List<dynamic>? ?? [];

      list.add(
        PreAllergiesScreen(
          initialAllergens: Set<String>.from(initialA),
          initialSensitivities: Set<String>.from(initialS),
          initialCustom: List<String>.from(initialC),

          onChanged: ({
            required Set<String> allergens,
            required Set<String> sensitivities,
            required List<String> custom,
          }) {
            chosenAllergens = allergens;
            chosenSensitivities = sensitivities;
            customAllergens = custom;

            setState(() => canProceed =
                allergens.isNotEmpty ||
                    sensitivities.isNotEmpty ||
                    custom.isNotEmpty);
          },
        ),
      );
    }

    // MEDICAL
    if (widget.selected["medical"] == true) {
      final raw = widget.initialData?["initialMedical"];

      List<dynamic>? initial = raw is List ? List<dynamic>.from(raw) : null;

      // Build hydration structures
      Set<String> initialConditions = {};
      Map<String, Map<String, bool>> initialRestrictions = {};

      if (initial != null) {
        for (final cat in initial) {
          final diseases = cat["diseases"] as List<dynamic>? ?? [];
          for (final d in diseases) {
            final id = d["id"].toString();
            initialConditions.add(id);

            final rList = (d["restrictions"] as List?) ?? [];
            initialRestrictions[id] =
            {for (final r in rList) r.toString(): true};
          }
        }
      }

      list.add(
        PrefMedicalScreen(
          initialSelectedConditions: initialConditions,
          initialRestrictions: initialRestrictions,
          onChanged: ({required conditions, required restrictions}) {
            selectedMedical = conditions;
            selectedMedicalRestrictions = restrictions;
            setState(() => canProceed = conditions.isNotEmpty);
          },
        ),
      );
    }


    // LIFESTYLE
    // LIFESTYLE
    if (widget.selected["fitness"] == true) {
      final raw = widget.initialData?["initialLifestyleGoals"];
      Map<String, dynamic>? initial =
      raw is Map ? Map<String, dynamic>.from(raw) : null;

      List<String> initialIds = [];
      if (initial != null) {
        final restrict = (initial["restrict_goals"] as List?) ?? [];
        final aware = (initial["awareness_goals"] as List?) ?? [];

        initialIds = [
          ...restrict.map((e) => e["id"].toString()),
          ...aware.map((e) => e["id"].toString()),
        ];
      }

      list.add(
        PrefLifestyleScreen(
          initialSelectedIds: initialIds.toSet(),
          onChanged: (goals) {
            selectedLifestyleGoals = goals;
            setState(() => canProceed = goals.isNotEmpty);
          },
        ),
      );
    }



    return list;
  }

  /// NEXT button
  void _goNext() {
    if (currentIndex == pages.length - 1) {
      _finishWizard();
      return;
    }

    setState(() {
      currentIndex++;
      canProceed = false;
    });

    _controller.animateToPage(
      currentIndex,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  /// BACK button
  void _goBack() {
    if (currentIndex == 0) return;

    setState(() {
      currentIndex--;
      canProceed = true;
    });

    _controller.animateToPage(
      currentIndex,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  // ─────────────────────────────────────────────
  // SAVE EVERYTHING
  // ─────────────────────────────────────────────
  Future<void> _finishWizard() async {
    final store = context.read<PreferenceStore>();

    // RELIGION
    if (widget.selected["religion"] == true) {
      final religionId = chosenReligion ?? initialReligion;
      final strictnessId = chosenStrictness ?? initialStrictness;

      if (religionId != null && strictnessId != null) {
        final strictnessLevels = loadStrictness(religionId);
        final chosenLevel =
        strictnessLevels.firstWhere((lvl) => lvl.id == strictnessId);

        final data = {
          "id": religionId,
          "strictness": strictnessId,
          "rules": chosenLevel.rules,
        };

        await store.update("religion_pref", data);
      }
    }

    // ETHICAL
    if (widget.selected["ethical"] == true) {
      final selectedList = choices
          .where((c) => ethicalChoices.contains(c.id))
          .map((c) => {
        "id": c.id,
        "title": c.title,
        "rules": c.rules,
      })
          .toList();

      await store.update("ethical_pref", selectedList);
    }

    // ALLERGY
    if (widget.selected["allergy"] == true) {
      final selectedAllergens = kAllergens
          .where((a) => chosenAllergens.contains(a.id))
          .map((a) => {
        "id": a.id,
        "title": a.title,
        "restriction": a.restrictionId,
      })
          .toList();

      final allergyData = {
        "allergens": selectedAllergens,
        "sensitivities": chosenSensitivities.toList(),
        "custom": customAllergens,
      };

      await store.update("allergy_pref", allergyData);
    }

    // MEDICAL
    if (widget.selected["medical"] == true) {
      final grouped = <Map<String, dynamic>>[];

      for (final cat in categories) {
        final diseases = <Map<String, dynamic>>[];

        for (final id in cat.diseaseIds) {
          if (!selectedMedical.contains(id)) continue;

          final label = getDiseaseLabel(id);
          final restrictionMap = selectedMedicalRestrictions[id] ?? {};
          final enabled = restrictionMap.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList();

          if (enabled.isEmpty) continue;

          diseases.add({
            "id": id,
            "label": label,
            "restrictions": enabled,
          });
        }

        if (diseases.isNotEmpty) {
          grouped.add({
            "category": {"id": cat.id, "label": cat.label},
            "diseases": diseases,
          });
        }
      }

      await store.update("medical_pref", grouped);
    }

    // LIFESTYLE
    if (widget.selected["fitness"] == true) {
      final restrict = <Map<String, dynamic>>[];
      final awareness = <Map<String, dynamic>>[];

      for (final goal in selectedLifestyleGoals) {
        if (goal["type"] == "restriction") {
          restrict.add({
            "id": goal["id"],
            "title": goal["title"],
            "restrictions": goal["restrictions"],
          });
        } else {
          awareness.add({
            "id": goal["id"],
            "title": goal["title"],
            "scoring": goal["scoringProfile"] ?? goal["id"],
          });
        }
      }

      final data = {
        "restrict_goals": restrict,
        "awareness_goals": awareness,
      };

      await store.update("life_style_pref", data);
    }

    // mark onboarding done
    await store.update("hasSetPreferences", true);

    // Navigation
    if (widget.fromProfile) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  String getDiseaseLabel(String id) {
    for (final list in kDiseaseMap.values) {
      for (final d in list) {
        if (d.id == id) return d.label;
      }
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Step ${currentIndex + 1} of ${pages.length}",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),

      body: PageView.builder(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: pages.length,
        itemBuilder: (_, i) => pages[i],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (currentIndex != 0)
              TextButton(
                onPressed: _goBack,
                child: const Text(
                  "Back",
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const Spacer(),

            ElevatedButton(
              onPressed: canProceed ? _goNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                canProceed ? const Color(0xFF4CAF50) : Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: Text(
                currentIndex == pages.length - 1 ? "Finish" : "Next",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                  canProceed ? Colors.white : const Color(0xFF9E9E9E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
