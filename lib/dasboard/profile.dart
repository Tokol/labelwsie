import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../diet_pref/restriction_definitions.dart';
import '../state/pref_store.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: const SizedBox.shrink(),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Dietary Profile",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Consumer<PreferenceStore>(
        builder: (_, store, __) {
          if (store.isLoading && !store.hasLoadedOnce) {
            return const Center(child: CircularProgressIndicator());
          }

          final prefs = store.prefs;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildReligion(context, prefs["religion"]),
                const SizedBox(height: 16),

                _buildEthical(context, prefs["ethical"]),
                const SizedBox(height: 16),

                _buildAllergy(context, prefs["allergy"]),
                const SizedBox(height: 16),

                _buildMedical(context, prefs["medical"]),
                const SizedBox(height: 16),

                _buildLifestyle(context, prefs["lifestyle"]),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────
  // RELIGION (POLISHED)
  // ───────────────────────────────────────────────

  Widget _buildReligion(BuildContext context, Map? data) {
    print("religion");
    print(data);
    if (data == null) {
      return _prefCard(
        context,
        title: "Religion / Cultural Diet",
        subtitle: "No preferences saved",
        actionLabel: "Set preferences",
        child: const Text(
          "You can add religious or cultural dietary rules.",
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        onAction: () {
          Navigator.pushNamed(
            context,
            "/preferencesWizard",
            arguments: {"religion": true, "fromProfile": true},
          );
        },
      );
    }

    final rules = (data["rules"] as List?) ?? [];
    final strictness = data["strictness"] ?? "";
    final religionId = data["id"] ?? "";

    final chips = rules.map((ruleId) {
      final title = restrictionDefinitions[ruleId]?.title ?? ruleId;
      return GestureDetector(
        onTap: () => _showRuleDetail(context, ruleId),
        child: _chip(title, active: true),
      );
    }).toList();

    return _prefCard(
      context,
      title: "Religion / Cultural Diet",
      subtitle: "$religionId (strictness: $strictness)",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Restricted ingredients:",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 10),
          _CollapsibleChipWrap(chips: chips, maxVisible: 3),
        ],
      ),
      actionLabel: "Edit",
      onAction: () {
        Navigator.pushNamed(
          context,
          "/preferencesWizard",
          arguments: {
            "religion": true,
            "fromProfile": true,
            "initialReligion": religionId,
            "initialStrictness": strictness,
          },
        );
      },
      secondaryActionLabel: "Clear",
      onSecondaryAction: () {
        _confirmClear(context, "Religion / Cultural Diet", "religion_pref");
      },
    );
  }

  // ───────────────────────────────────────────────
  // ETHICAL
  // ───────────────────────────────────────────────

  // ───────────────────────────────────────────────
// ETHICAL (UPDATED WITH BOTTOM SHEET LIKE RELIGION)
// ───────────────────────────────────────────────

  Widget _buildEthical(BuildContext context, List? data) {
    if (data == null || data.isEmpty) {
      return _prefCard(
        context,
        title: "Ethical / Personal Choices",
        subtitle: "No choices selected",
        actionLabel: "Set choices",
        child: const Text(
          "Add personal or ethical dietary considerations.",
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        onAction: () {
          Navigator.pushNamed(
            context,
            "/preferencesWizard",
            arguments: {"ethical": true, "fromProfile": true},
          );
        },
      );
    }

    final titles = data.map<String>((e) => e["title"]).toList();
    final ids = data.map<String>((e) => e["id"]).toList();

    final chips = data.map<Widget>((e) {
      final title = e["title"];
      final rules = (e["rules"] as List?)?.cast<String>() ?? [];

      return GestureDetector(
        onTap: () => _showEthicalDetail(context, title, rules),
        child: _chip(title, active: true),
      );
    }).toList();

    return _prefCard(
      context,
      title: "Ethical / Personal Choices",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          _CollapsibleChipWrap(chips: chips, maxVisible: 3),
        ],
      ),
      actionLabel: "Edit",
      onAction: () {
        Navigator.pushNamed(
          context,
          "/preferencesWizard",
          arguments: {
            "ethical": true,
            "fromProfile": true,
            "initialData": {"ethicalIds": ids},
          },
        );
      },
      secondaryActionLabel: "Clear",
      onSecondaryAction: () {
        _confirmClear(context, "Ethical / Personal Choices", "ethical_pref");
      },
    );
  }


// ───────────────────────────────────────────────
// ETHICAL DETAIL BOTTOM SHEET (MATCHING ETHICALCHOICESSCREEN)
// ───────────────────────────────────────────────

  void _showEthicalDetail(BuildContext context, String title, List<String> ruleIds) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.40,
        maxChildSize: 0.90,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Typical ingredient Forms:",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 16),

                ..._ethicalGroupedRules(ruleIds),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _ethicalGroupedRules(List<String> ruleIds) {
    final List<Widget> groups = [];

    for (final id in ruleIds) {
      final rule = restrictionDefinitions[id];
      if (rule == null) continue;

      groups.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.block, size: 18, color: const Color(0xFF2E7D32)),
                  const SizedBox(width: 6),
                  Text(
                    rule.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rule.examples.map((ex) {
                  return Chip(
                    backgroundColor: const Color(0xFFEFF7F1),
                    side: const BorderSide(color: Color(0xFFCCE8D0)),
                    label: Text(
                      ex,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    return groups;
  }

  Widget _buildAllergy(BuildContext context, Map? data) {
    if (data == null) {
      return _prefCard(
        context,
        title: "Allergies & Sensitivities",
        subtitle: "No allergies added",
        actionLabel: "Add allergies",
        child: const Text(
          "Include allergens, sensitivities, and custom triggers.",
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        onAction: () {
          Navigator.pushNamed(
            context,
            "/preferencesWizard",
            arguments: {
              "allergy": true,
              "fromProfile": true,
              "initialData": {
                "initialAllergens": <String>[],
                "initialSensitivities": <String>[],
                "initialCustom": <String>[],
              },
            },
          );
        },
      );
    }

    // --- ALLERGEN CHIPS (system-defined, has restrictionDefinition) ---
    final allergenChips = (data["allergens"] as List? ?? []).map<Widget>((e) {
      return GestureDetector(
        onTap: () => _showAllergyDetail(
          context,
           e["title"],
          type: "allergen",
          ruleId: e["restriction"], // ✅ FIXED
        ),
        child: _chip("${e["title"]} (allergen)", active: true),
      );
    });

    // --- SENSITIVITY CHIPS (no restriction definition, simple explanation) ---
    final sensitivityChips = (data["sensitivities"] as List? ?? []).map<Widget>((e) {
      return GestureDetector(
        onTap: () => _showAllergyDetail(
          context,
          e.toString(),
          type: "sensitivity",
        ),
        child: _chip("$e (sensitivity)", active: true),
      );
    });

    // --- CUSTOM USER-ADDED ITEMS ---
    final customChips = (data["custom"] as List? ?? []).map<Widget>((e) {
      return GestureDetector(
        onTap: () => _showAllergyDetail(
          context,
           e.toString(),
          type: "custom",
        ),
        child: _chip("$e (user-added)", active: true),
      );
    });

    return _prefCard(
      context,
      title: "Allergies & Sensitivities",
      child: _CollapsibleChipWrap(
        chips: [
          ...allergenChips,
          ...sensitivityChips,
          ...customChips,
        ],
        maxVisible: 4,
      ),
      actionLabel: "Edit",
      onAction: () {
        final allergens = (data["allergens"] as List?)?.map((e) => e["id"]).toList() ?? [];
        final sensitivities = (data["sensitivities"] as List?)?.cast<String>() ?? [];
        final custom = (data["custom"] as List?)?.cast<String>() ?? [];

        Navigator.pushNamed(
          context,
          "/preferencesWizard",
          arguments: {
            "allergy": true,
            "fromProfile": true,
            "initialData": {
              "initialAllergens": allergens,
              "initialSensitivities": sensitivities,
              "initialCustom": custom,
            },
          },
        );
      },
      secondaryActionLabel: "Clear",
      onSecondaryAction: () {
        _confirmClear(context, "Allergies & Sensitivities", "allergy_pref");
      },
    );
  }

// ───────────────────────────────────────────────
// ALLERGY DETAIL (Allergen / Sensitivity / Custom)
// ───────────────────────────────────────────────
  void _showAllergyDetail(
      BuildContext context,
      String title, {
        required String type,
        String? ruleId,
      }) {
    // 1️⃣ SYSTEM ALLERGEN → uses restrictionDefinitions
    if (type == "allergen" && ruleId != null) {
      final def = restrictionDefinitions[ruleId];
      if (def == null) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.40,
          maxChildSize: 0.90,
          builder: (_, controller) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),

                const Text(
                  "May appear on labels as:",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF444444),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 14),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: def.examples.map((e) {
                    return Chip(
                      backgroundColor: const Color(0xFFE9F6EA),
                      side: const BorderSide(color: Color(0xFFCCE8D0)),
                      label: Text(
                        e,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      );

      return;
    }

    // 2️⃣ SENSITIVITY → gentle guidance text
    if (type == "sensitivity") {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),

              const Text(
                "This is a sensitivity you monitor.\n\n"
                    "Because sensitivities vary widely between people, there are no standard ingredient forms. "
                    "However, the AI reasoning engine in LabelWise may still detect related terms on food labels that could matter to you.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),

              const SizedBox(height: 14),

              const Text(
                "Tip: Look for similar or related ingredient names when checking labels.",
                style: TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      );
      return;
    }

    // 3️⃣ USER-CUSTOM ITEM → friendly and neutral text
    if (type == "custom") {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),

              const Text(
                "This item is something you personally want to avoid.\n\n"
                    "LabelWise cannot list predefined ingredient forms for custom items, but the AI reasoning engine may still recognize variations or related terms on food labels.",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),

              const SizedBox(height: 14),

              const Text(
                "Tip: Keep an eye out for variations of this item when reading labels.",
                style: TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      );
    }
  }







  // ───────────────────────────────────────────────
  // MEDICAL (unchanged)
  // ───────────────────────────────────────────────

  Widget _buildMedical(BuildContext context, List? grouped) {
    if (grouped == null || grouped.isEmpty) {
      return _prefCard(
        context,
        title: "Medical Dietary Needs",
        subtitle: "No medical restrictions set",
        actionLabel: "Add conditions",
        child: const Text(
          "Include medical-triggered diets such as diabetes or celiac.",
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        onAction: () {
          Navigator.pushNamed(
            context,
            "/preferencesWizard",
            arguments: {
              "medical": true,
              "fromProfile": true,
              "initialData": {"initialMedical": <dynamic>[]},
            },
          );
        },
      );
    }

    // Build chips with category-aware formatting
    final chipWidgets = <Widget>[];

    for (final cat in grouped) {
      final catLabel = cat["category"]["label"];
      final diseases = cat["diseases"] as List;

      for (final d in diseases) {
        final diseaseLabel = d["label"];

        // pregnancy: "Pregnancy · Avoid Raw Ingredients"
        final bool isPregnancy = (cat["category"]["id"] == "pregnancy");
        final chipText =
        isPregnancy ? "$catLabel · $diseaseLabel" : diseaseLabel;

        chipWidgets.add(
          GestureDetector(
            onTap: () => _showMedicalDetail(
              context,
              categoryLabel: catLabel,
              diseaseLabel: diseaseLabel,
              restrictions: (d["restrictions"] as List).cast<String>(),
            ),
            child: _chip(chipText, active: true),
          ),
        );
      }
    }

    return _prefCard(
      context,
      title: "Medical Dietary Needs",
      child: _CollapsibleChipWrap(
        chips: chipWidgets,
        maxVisible: 4,
      ),
      actionLabel: "Edit",
      onAction: () {
        Navigator.pushNamed(
          context,
          "/preferencesWizard",
          arguments: {
            "medical": true,
            "fromProfile": true,
            "initialData": {"initialMedical": grouped},
          },
        );
      },
      secondaryActionLabel: "Clear",
      onSecondaryAction: () {
        _confirmClear(context, "Medical Dietary Needs", "medical_pref");
      },
    );
  }
  void _showMedicalDetail(
      BuildContext context, {
        required String categoryLabel,
        required String diseaseLabel,
        required List<String> restrictions,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.40,
        maxChildSize: 0.90,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  diseaseLabel,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),

                // Category
                Text(
                  categoryLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 22),

                const Text(
                  "Typical ingredient forms:",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 16),

                // Restriction groups
                ..._medicalRestrictionGroups(restrictions),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  List<Widget> _medicalRestrictionGroups(List<String> restrictionIds) {
    final List<Widget> groups = [];

    for (final id in restrictionIds) {
      final def = restrictionDefinitions[id];
      if (def == null) continue;

      groups.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(def.icon, size: 18, color: const Color(0xFF2E7D32)),
                  const SizedBox(width: 6),
                  Text(
                    def.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: def.examples.map((e) {
                  return Chip(
                    backgroundColor: const Color(0xFFEFF7F1),
                    side: const BorderSide(color: Color(0xFFCCE8D0)),
                    label: Text(
                      e,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    return groups;
  }


  // ───────────────────────────────────────────────
  // LIFESTYLE (unchanged)
  // ───────────────────────────────────────────────

  Widget _buildLifestyle(BuildContext context, Map? data) {
    if (data == null) {
      return _prefCard(
        context,
        title: "Lifestyle & Fitness Goals",
        subtitle: "No goals selected",
        actionLabel: "Add goals",
        child: const Text(
          "Include restriction goals and awareness goals.",
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        onAction: () {
          Navigator.pushNamed(
            context,
            "/preferencesWizard",
            arguments: {"fitness": true, "fromProfile": true},
          );
        },
      );
    }

    final restrictGoals = (data["restrict_goals"] as List? ?? []);
    final awarenessGoals = (data["awareness_goals"] as List? ?? []);

    final chips = <Widget>[];

    // ---------------------------
    // RESTRICT GOAL CHIPS (green)
    // ---------------------------
    for (final g in restrictGoals) {
      chips.add(
        GestureDetector(
          onTap: () => _showLifestyleDetail(
            context,
            title: g["title"],
            restrictions: (g["restrictions"] as List?)?.cast<String>() ?? [],
            isAwareness: false,
          ),
          child: _chip(g["title"], active: true),
        ),
      );
    }

    // -------------------------------
    // AWARENESS GOAL CHIPS (amber)
    // -------------------------------
    for (final g in awarenessGoals) {
      chips.add(
        GestureDetector(
          onTap: () => _showLifestyleDetail(
            context,
            title: g["title"],
            isAwareness: true,
            scoringRule: g["scoring"],
          ),
          child: _chipAmber(g["title"]),
        ),
      );
    }

    return _prefCard(
      context,
      title: "Lifestyle & Fitness Goals",
      child: _CollapsibleChipWrap(chips: chips, maxVisible: 4),
      actionLabel: "Edit",
      onAction: () {
        Navigator.pushNamed(
          context,
          "/preferencesWizard",
          arguments: {
            "fitness": true,
            "fromProfile": true,
            "initialData": {"initialLifestyleGoals": data},
          },
        );
      },
      secondaryActionLabel: "Clear",
      onSecondaryAction: () {
        _confirmClear(context, "Lifestyle & Fitness Goals", "life_style_pref");
      },
    );
  }
// -----------------------------------------------------
// LIFESTYLE GOAL DETAIL (Restrict vs Awareness)
// -----------------------------------------------------
  void _showLifestyleDetail(
      BuildContext context, {
        required String title,
        required bool isAwareness,
        List<String>? restrictions,
        String? scoringRule,
      }) {
    // Ensure restrictions list is always safe
    final safeRestrictions = restrictions ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.40,
        maxChildSize: 0.90,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------------------------------------
                // HEADER
                // ---------------------------------------------------
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),

                // ===================================================
                // 🔵 CASE 1 — RESTRICT GOAL (Green chips)
                // ===================================================
                if (!isAwareness) ...[
                  const Text(
                    "Restricted ingredient forms:",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grouped restriction list
                  ...safeRestrictions.map((ruleId) {
                    final rule = restrictionDefinitions[ruleId];
                    if (rule == null) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(rule.icon,
                                  size: 18, color: const Color(0xFF2E7D32)),
                              const SizedBox(width: 6),
                              Text(
                                rule.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: rule.examples.map((ex) {
                              return Chip(
                                backgroundColor: const Color(0xFFEFF7F1),
                                side: const BorderSide(
                                    color: Color(0xFFCCE8D0)),
                                label: Text(
                                  ex,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],

                // ===================================================
                // 🟡 CASE 2 — AWARENESS GOAL (Amber/yellow theme)
                // ===================================================
                if (isAwareness) ...[
                  const Text(
                    "Awareness guidance:",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8C6D1F), // amber tone
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE6C67A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "This is an awareness goal.",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8C6D1F),
                          ),
                        ),
                        const SizedBox(height: 10),

                        const Text(
                          "LabelWise will not block ingredients for this goal, but it may "
                              "use the scoring engine to help you understand how well this product "
                              "fits your chosen lifestyle goal.",
                          style: TextStyle(fontSize: 14, height: 1.4),
                        ),

                        if (scoringRule != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            "Scoring rule: $scoringRule",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8C6D1F),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }



  // ───────────────────────────────────────────────
  // CHIP UI (Option-A color)
  // ───────────────────────────────────────────────

  Widget _chip(String label, {bool active = false}) {
    return Chip(
      label: Text(label),
      backgroundColor:
      active ? const Color(0xFFE9F6EA) : const Color(0xFFE9F6EA),
      labelStyle: TextStyle(
        color: active ? const Color(0xFF2E7D32) : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: active ? const Color(0xFF4CAF50) : const Color(0xFFCCE8D0),
        width: 1.2,
      ),
    );
  }

  // ───────────────────────────────────────────────
  // CARD WRAPPER
  // ───────────────────────────────────────────────

  // Amber chip for awareness goals
  Widget _chipAmber(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: const Color(0xFFFFF4DB),      // soft warm yellow
      labelStyle: const TextStyle(
        color: Color(0xFFB76E00),                   // dark amber
        fontWeight: FontWeight.w600,
      ),
      side: const BorderSide(
        color: Color(0xFFF0C663),                    // amber border
        width: 1.2,
      ),
    );
  }



  Widget _prefCard(
      BuildContext context, {
        required String title,
        String? subtitle,
        required Widget child,
        required String actionLabel,
        VoidCallback? onAction,
        String? secondaryActionLabel,
        VoidCallback? onSecondaryAction,
      }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE3E5E4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ),

                if (secondaryActionLabel != null)
                  TextButton(
                    onPressed: onSecondaryAction,
                    child: Text(
                      secondaryActionLabel!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                if (onAction != null)
                  TextButton(
                    onPressed: onAction,
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),

            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // CLEAR DIALOG (unchanged)
  // ───────────────────────────────────────────────

  void _confirmClear(
      BuildContext context, String displayName, String hiveKey) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          "Remove $displayName?",
          style: const TextStyle(
              color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          "Are you sure you want to remove the saved preferences for \"$displayName\"?",
          style: const TextStyle(color: Colors.black54, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text("Remove",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (yes == true) {
      await Future.delayed(const Duration(milliseconds: 30));
      await context.read<PreferenceStore>().clear(hiveKey);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$displayName removed"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ───────────────────────────────────────────────
  // RULE DETAIL BOTTOM SHEET (Polished)
  // ───────────────────────────────────────────────

  void _showRuleDetail(BuildContext context, String ruleId) {
    final def = restrictionDefinitions[ruleId];
    if (def == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.40,
        maxChildSize: 0.90,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),

                const Text(
                  "May appear on labels as:",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF444444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: def.examples.map((e) {
                    return Chip(
                      label: Text(e),
                      backgroundColor: const Color(0xFFE9F6EA),
                      side: const BorderSide(color: Color(0xFFCCE8D0)),
                      labelStyle: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────
// COLLAPSIBLE CHIP WRAP (unchanged)
// ───────────────────────────────────────────────

class _CollapsibleChipWrap extends StatefulWidget {
  final List<Widget> chips;
  final int maxVisible;

  const _CollapsibleChipWrap({
    required this.chips,
    this.maxVisible = 3,
  });

  @override
  State<_CollapsibleChipWrap> createState() =>
      _CollapsibleChipWrapState();
}

class _CollapsibleChipWrapState extends State<_CollapsibleChipWrap> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.chips.length;
    final visible =
    expanded ? widget.chips : widget.chips.take(widget.maxVisible).toList();

    final items = [...visible];

    if (total > widget.maxVisible) {
      items.add(
        ActionChip(
          label: Text(expanded ? "Show less" : "+${total - widget.maxVisible} more"),
          onPressed: () => setState(() => expanded = !expanded),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items,
    );
  }
}
