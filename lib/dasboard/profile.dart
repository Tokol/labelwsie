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
  // RELIGION
  // ───────────────────────────────────────────────

  Widget _buildReligion(BuildContext context, Map? data) {
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
        child: _chip(title),
      );
    }).toList();

    return _prefCard(
      context,
      title: "Religion / Cultural Diet",
      subtitle: "$religionId (strictness: $strictness)",
      child: _CollapsibleChipWrap(chips: chips, maxVisible: 3),
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
        _confirmClear(
          context,
          "Religion / Cultural Diet",
          "religion_pref",
        );
      },
    );
  }

  // ───────────────────────────────────────────────
  // ETHICAL
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

    return _prefCard(
      context,
      title: "Ethical / Personal Choices",
      child: _CollapsibleChipWrap(
        chips: titles.map(_chip).toList(),
        maxVisible: 3,
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
  // ALLERGY
  // ───────────────────────────────────────────────

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

    final chips = <String>[
      ...(data["allergens"] as List? ?? [])
          .map((e) => "${e["title"]} (allergen)"),
      ...(data["sensitivities"] as List? ?? [])
          .map((e) => "${e.toString()} (sensitivity)"),
      ...(data["custom"] as List? ?? [])
          .map((e) => "${e.toString()} (user-added)"),
    ];


    return _prefCard(
      context,
      title: "Allergies & Sensitivities",
      child: _CollapsibleChipWrap(
        chips: chips.map(_chip).toList(),
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
            }
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
  // MEDICAL
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
              "initialData": {
                "initialMedical": <dynamic>[],  // <--- send hive structure
              }
            },
          );
        },
      );
    }

    final chips = <String>[];
    for (final cat in grouped) {
      for (final d in cat["diseases"]) {
        chips.add(d["label"]);
      }
    }

    return _prefCard(
      context,
      title: "Medical Dietary Needs",
      child: _CollapsibleChipWrap(
        chips: chips.map(_chip).toList(),
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
              "initialData": {
                "initialMedical": grouped, // pass saved medical hive data
              }
            },
          );
        },


      secondaryActionLabel: "Clear",
      onSecondaryAction: () {
        _confirmClear(context, "Medical Dietary Needs", "medical_pref");
      },
    );
  }

  // ───────────────────────────────────────────────
  // LIFESTYLE
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
            arguments: {
              "fitness": true,
              "fromProfile": true,
              // 🔹 no initialData when nothing saved yet
            },
          );
        },
      );
    }


    final chips = <String>[
      ...(data["restrict_goals"] as List? ?? []).map((e) => e["title"]),
      ...(data["awareness_goals"] as List? ?? []).map((e) => e["title"]),
    ];

    return _prefCard(
      context,
      title: "Lifestyle & Fitness Goals",
      child: _CollapsibleChipWrap(
        chips: chips.map(_chip).toList(),
        maxVisible: 4,
      ),
      actionLabel: "Edit",
      onAction: () {
        Navigator.pushNamed(
          context,
          "/preferencesWizard",
          arguments: {
            "fitness": true,
            "fromProfile": true,
            "initialData": {
              "initialLifestyleGoals": data,  // 🔹 send entire lifestyle map
            },
          },
        );
      },

      secondaryActionLabel: "Clear",
      onSecondaryAction: () {
        _confirmClear(context, "Lifestyle & Fitness Goals", "life_style_pref");
      },
    );

  }

  // ───────────────────────────────────────────────
  // UI HELPERS
  // ───────────────────────────────────────────────

  Widget _chip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: const Color(0xFFE9F6EA),
      labelStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w500,
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
  // FINAL FIXED CLEAR METHOD (KEY + NAME)
  // ───────────────────────────────────────────────

  void _confirmClear(
      BuildContext context,
      String displayName,
      String hiveKey,
      ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: Text(
          "Remove $displayName?",
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          "Are you sure you want to remove the saved preferences for \"$displayName\"?",
          style:
          const TextStyle(color: Colors.black54, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(false),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(true),
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
  // RULE DETAIL
  // ───────────────────────────────────────────────

  void _showRuleDetail(BuildContext context, String ruleId) {
    final def = restrictionDefinitions[ruleId];
    if (def == null) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
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
            Text(def.title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text(
              "Ingredients often appear like this:",
              style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF444444),
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: def.examples
                  .map(
                    (e) => Chip(
                  label: Text(e),
                  backgroundColor: const Color(0xFFE9F6EA),
                  side: const BorderSide(color: Color(0xFFCCE8D0)),
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────
// COLLAPSIBLE CHIP WRAP
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

class _CollapsibleChipWrapState
    extends State<_CollapsibleChipWrap> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.chips.length;
    final visible = expanded
        ? widget.chips
        : widget.chips.take(widget.maxVisible).toList();

    final items = [...visible];

    if (total > widget.maxVisible) {
      items.add(
        ActionChip(
          label: Text(
              expanded ? "Show less" : "+${total - widget.maxVisible} more"),
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
