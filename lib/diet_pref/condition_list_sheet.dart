import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'condition_detail_sheet.dart'; // for kDiseaseRestrictionMap

class ConditionListSheet extends StatefulWidget {
  final String categoryId;
  final String categoryLabel;

  /// Global state passed down from MedicalNeedsScreen
  final Set<String> selectedConditions; // disease IDs
 // final Map<String, dynamic> selectedRestrictions; // restrictionId → bool
  final Map<String, Map<String, bool>> selectedRestrictions;

  const ConditionListSheet({
    super.key,
    required this.categoryId,
    required this.categoryLabel,
    required this.selectedConditions,
    required this.selectedRestrictions,
  });

  @override
  State<ConditionListSheet> createState() => _ConditionListSheetState();
}

/// Public disease model so other files (summary) can reuse it.
class DiseaseEntry {
  final String id;
  final String label;

  const DiseaseEntry({required this.id, required this.label});
}

/// Category → list of diseases
const Map<String, List<DiseaseEntry>> kDiseaseMap = {
  "metabolic": [
    DiseaseEntry(id: "diabetes_type_2", label: "Type 2 Diabetes"),
    DiseaseEntry(id: "prediabetes", label: "Prediabetes"),
    DiseaseEntry(id: "insulin_resistance", label: "Insulin Resistance"),
  ],
  "thyroid": [
    DiseaseEntry(id: "hypothyroid", label: "Hypothyroidism"),
    DiseaseEntry(id: "hyperthyroid", label: "Hyperthyroidism"),
    DiseaseEntry(id: "pcos", label: "PCOS (Hormonal)"),
  ],
  "digestive": [
    DiseaseEntry(id: "ibs", label: "IBS"),
    DiseaseEntry(id: "fodmap_sensitivity", label: "FODMAP Sensitivity"),
    DiseaseEntry(id: "acid_reflux", label: "Acid Reflux / GERD"),
  ],
  "kidney": [
    DiseaseEntry(id: "kidney_stones", label: "Kidney Stone History"),
    DiseaseEntry(id: "low_oxalate_needed", label: "Low-Oxalate Required"),
    DiseaseEntry(id: "low_sodium_needed", label: "Low-Sodium Required"),
  ],
  "heart": [
    DiseaseEntry(id: "hypertension", label: "High Blood Pressure"),
    DiseaseEntry(
      id: "heart_disease_fat_control",
      label: "Heart Disease / Fat Control",
    ),
  ],
  "pregnancy": [
    DiseaseEntry(id: "avoid_raw", label: "Avoid Raw Ingredients"),
    DiseaseEntry(id: "avoid_high_mercury", label: "Avoid High-Mercury Fish"),
  ],
};

class _ConditionListSheetState extends State<ConditionListSheet> {
  late Set<String> _localSelectedConditions; // disease IDs
  late Map<String, Map<String, bool>> _localSelectedRestrictions;
  late final List<DiseaseEntry> _diseases;


  @override
  void initState() {
    super.initState();
    _localSelectedConditions = {...widget.selectedConditions};

    final diseases = kDiseaseMap[widget.categoryId] ?? const <DiseaseEntry>[];

    // 1) Initialize local maps for each disease
    _localSelectedRestrictions = {
      for (final entry in widget.selectedRestrictions.entries)
        entry.key: Map<String, bool>.from(entry.value)
    };

    // 2) Ensure all diseases in this category have a map
    for (final d in diseases) {
      _localSelectedRestrictions.putIfAbsent(d.id, () => {});
    }

    // 3) Recalculate which diseases are active
    _recalculateSelectedConditionsForThisCategory();
  }



  @override
  Widget build(BuildContext context) {
    final diseases = kDiseaseMap[widget.categoryId] ?? const <DiseaseEntry>[];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.60,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
              Center(
                child: Container(
                  height: 5,
                  width: 60,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              Text(
                widget.categoryLabel,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select the medical conditions that apply to you.",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF777777),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: diseases.length,
                  itemBuilder: (_, i) {
                    final item = diseases[i];
                    final selectedCount = _selectedCountFor(item.id);
                    final subtitle = selectedCount == 0
                        ? "No checks selected"
                        : selectedCount == 1
                        ? "1 check selected"
                        : "$selectedCount checks selected";

                    final isActive =
                    _localSelectedConditions.contains(item.id);

                    return Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            await _openDetail(item.id, item.label);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 2),
                            child: Row(
                              children: [
                                Icon(
                                  isActive
                                      ? Symbols.check_circle_rounded
                                      : Symbols
                                      .radio_button_unchecked_rounded,
                                  size: 22,
                                  color: isActive
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFB5B5B5),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.label,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF777777),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.shade500,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 16),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      "conditions": _localSelectedConditions,
                      "restrictions": _localSelectedRestrictions,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Done",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // open detail sheet and merge restrictions
  Future<void> _openDetail(String diseaseId, String diseaseLabel) async {
    final result = await showModalBottomSheet<Map<String, Map<String, bool>>>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return ConditionDetailSheet(
          diseaseId: diseaseId,
          diseaseLabel: diseaseLabel,
          selectedRestrictions: _localSelectedRestrictions,
        );
      },
    );

    if (result != null) {
      setState(() {
        // Overwrite only the map for this disease
        _localSelectedRestrictions[diseaseId] =
        Map<String, bool>.from(result[diseaseId] ?? {});

        // Update active diseases
        _recalculateSelectedConditionsForThisCategory();
      });
    }
  }


  // how many checks are selected for this disease?
  int _selectedCountFor(String diseaseId) {
    final map = _localSelectedRestrictions[diseaseId];
    if (map == null) return 0;
    return map.values.where((v) => v == true).length;
  }


  // derive which diseases in THIS category are active from restriction map
  void _recalculateSelectedConditionsForThisCategory() {
    final diseases = kDiseaseMap[widget.categoryId] ?? const <DiseaseEntry>[];

    // Clear old
    final idsInThisCategory = diseases.map((d) => d.id).toSet();
    _localSelectedConditions.removeWhere(idsInThisCategory.contains);

    // Re-add based on nested restrictions
    for (final d in diseases) {
      final map = _localSelectedRestrictions[d.id];
      if (map == null) continue;

      final anyChecked = map.values.any((v) => v == true);

      if (anyChecked) {
        _localSelectedConditions.add(d.id);
      }
    }
  }

}
