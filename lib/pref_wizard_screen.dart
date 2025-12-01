import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import 'diet_pref/condition_list_sheet.dart';
import 'diet_pref/pref_screen/allergy_pref_screen.dart';
import 'diet_pref/pref_screen/ethical_pref_screen.dart';
import 'diet_pref/pref_screen/helper/ehical_choices.dart';
import 'diet_pref/pref_screen/helper/strictness_loader.dart';
import 'diet_pref/pref_screen/medical_pref_screen.dart';
import 'diet_pref/pref_screen/pref_lifestyle.dart';
import 'diet_pref/pref_screen/religion_pref_screen.dart';
import 'diet_pref/pref_screen/religion_strickness.dart';

class PreferencesWizardScreen extends StatefulWidget {
  final Map<String, bool> selected;
  const PreferencesWizardScreen({required this.selected, super.key});

  @override
  State<PreferencesWizardScreen> createState() =>
      _PreferencesWizardScreenState();
}

class _PreferencesWizardScreenState extends State<PreferencesWizardScreen> {
  final PageController _controller = PageController();
  late final List<Widget> pages;

  int currentIndex = 0;
  bool canProceed = false;

  String? chosenReligion;
  String? chosenStrictness;

  Set<String> ethicalChoices = {};

  Set<String> chosenAllergens = {};
  Set<String> chosenSensitivities = {};
  List<String> customAllergens = [];


  Set<String> selectedMedical = {};
  Map<String, Map<String, bool>> selectedMedicalRestrictions = {};


  List<Map<String, dynamic>> selectedLifestyleGoals = [];




  @override
  void initState() {
    super.initState();

    pages = [];

    if (widget.selected["religion"] == true) {
      pages.add(
        ReligionSelectionPage(
          onSelected: (v) => chosenReligion = v,
          onStateChanged: (ok) => setState(() => canProceed = ok),
        ),
      );

      pages.add(
        ReligionStrictnessPage(
          getReligion: () => chosenReligion!,
          onSelected: (v) => chosenStrictness = v,
          onStateChanged: (ok) => setState(() => canProceed = ok),
        ),
      );
    }


    if (widget.selected["ethical"] == true) {
      pages.add(
        EthicalChoicesScreen(
          onChanged: (ids) {
          ethicalChoices = ids;
          setState(() => canProceed = ids.isNotEmpty);
          },
        ),
      );
    }


    if (widget.selected["allergy"] == true) {
      pages.add(
        PreAllergiesScreen(
          onChanged: ({
            required Set<String> allergens,
            required Set<String> sensitivities,
            required List<String> custom,
          }) {
            chosenAllergens = allergens;
            chosenSensitivities = sensitivities;
            customAllergens = custom;

            final anySelected =
                allergens.isNotEmpty ||
                    sensitivities.isNotEmpty ||
                    custom.isNotEmpty;

            setState(() => canProceed = anySelected);
          },
        ),
      );
    }




    if (widget.selected["medical"] == true) {
      pages.add(
        PrefMedicalScreen(
          onChanged: ({required conditions, required restrictions}) {
            selectedMedical = conditions;
            selectedMedicalRestrictions = restrictions;

            setState(() {
              canProceed = conditions.isNotEmpty;
            });
          },
        ),
      );
    }


    if (widget.selected["fitness"] == true) {
      pages.add(
        PrefLifestyleScreen(
          onChanged: (goals) {
            selectedLifestyleGoals = goals;
            setState(() => canProceed = goals.isNotEmpty);
          },
        ),
      );
    }


  }






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

  Future<void> _finishWizard() async {
    final box = await Hive.openBox("app_data");

    // RELIGION
    if (widget.selected["religion"] == true) {
      final strictnessLevels =
      loadStrictness(chosenReligion!); // e.g. loadStrictness("buddhist")

      // 2. Find the exact strictness object
      final chosenLevel = strictnessLevels.firstWhere(
            (lvl) => lvl.id == chosenStrictness,
      );

      // 3. Save using normalized structure
      final religionData = {
        "id": chosenReligion,                   // "buddhist"
        "strictness": chosenStrictness,         // "strict"
        "rules": chosenLevel.rules,             // <-- list of restriction IDs
      };

        print(religionData);

      // Save to Hive
      await box.put("religion_pref", religionData);
    }

    // ETHICAL
    if (widget.selected["ethical"] == true) {

      final allChoices = choices;

      final selectedChoices = allChoices
          .where((c) => ethicalChoices.contains(c.id))
          .toList();

      // Build structured data
      final ethicalData = selectedChoices.map((choice) {
        return {
          "id": choice.id,
          "title": choice.title,   // <-- added title
          "rules": choice.rules,   // <-- raw list
        };
      }).toList();


      await box.put("ethical_pref", ethicalData);

      print("Ethical saved:");
      print(ethicalData);
    }

    // ALLERGY
    if (widget.selected["allergy"] == true) {


      // Build allergen objects list
      final selectedList = kAllergens
          .where((a) => chosenAllergens.contains(a.id))
          .map((a) => {
        "id": a.id,
        "title": a.title,
        "restriction": a.restrictionId,
      })
          .toList();

      final allergyData = {
        "allergens": selectedList,                  // structured list
        "sensitivities": chosenSensitivities.toList(),
        "custom": customAllergens,                 // raw user text
      };

      await box.put("allergy_pref", allergyData);

      print("Allergy saved:");
      print(allergyData);
    }

    // MEDICAL
    if (widget.selected["medical"] == true) {
    //  final box = await Hive.openBox("app_data");

      // 1. Master list to store everything
      final List<Map<String, dynamic>> grouped = [];

      for (final category in categories) {
        // Filter diseases that user actually selected under this category
        final List<Map<String, dynamic>> diseaseList = [];

        for (final diseaseId in category.diseaseIds) {

          if (!selectedMedical.contains(diseaseId)) continue;

          final diseaseLabel = getDiseaseLabel(diseaseId);

          final restrictionMap = selectedMedicalRestrictions[diseaseId] ?? {};
          final enabledRestrictions = restrictionMap.entries
              .where((e) => e.value == true)
              .map((e) => e.key)
              .toList();

          // Skip if no check enabled for this disease
          if (enabledRestrictions.isEmpty) continue;

          diseaseList.add({
            "id": diseaseId,
            "label": diseaseLabel,
            "restrictions": enabledRestrictions,
          });
        }

        // If category contains no active diseases, skip category
        if (diseaseList.isEmpty) continue;

        grouped.add({
          "category": {
            "id": category.id,
            "label": category.label,
          },
          "diseases": diseaseList,
        });
      }

      await box.put("medical_pref", grouped);

      print("FINAL MEDICAL SAVED:");
      print(grouped);
    }



    // LIFESTYLE
    // LIFESTYLE
    if (widget.selected["fitness"] == true) {


      // Use the already-prepared list coming from PrefLifestyleScreen
      final goals = selectedLifestyleGoals;

      final restrictList = <Map<String, dynamic>>[];
      final awarenessList = <Map<String, dynamic>>[];

      for (final goal in goals) {
        final type = goal["type"]; // "restriction" or "awareness"

        if (type == "restriction") {
          restrictList.add({
            "id": goal["id"],
            "title": goal["title"],
            "restrictions": goal["restrictions"],
          });
        } else {
          awarenessList.add({
            "id": goal["id"],
            "title": goal["title"],
            "scoring": goal["scoringProfile"] ?? goal["id"],
          });
        }
      }

      final lifestyleData = {
        "restrict_goals": restrictList,
        "awareness_goals": awarenessList,
      };

      print("Saved lifestyle:");
      print(lifestyleData);



      await box.put("life_style_pref", lifestyleData);
    }


    await box.put("hasSetPreferences", true);

    // Navigate to home screen
    if (mounted) {
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

  String getCategoryIdForDisease(String diseaseId) {
    for (final cat in categories) {
      if (cat.diseaseIds.contains(diseaseId)) return cat.id;
    }
    return "";
  }

  String getCategoryLabelForDisease(String diseaseId) {
    for (final cat in categories) {
      if (cat.diseaseIds.contains(diseaseId)) return cat.label;
    }
    return "";
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
                padding:
                const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: Text(
                currentIndex == pages.length - 1 ? "Finish" : "Next",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: canProceed ? Colors.white : const Color(0xFF9E9E9E),
                ),
              ),

            ),
          ],
        ),
      ),
    );
  }
}
