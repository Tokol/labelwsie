import 'package:flutter/material.dart';
import 'package:label_wise/diet_pref/restriction_definitions.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Disease → list of restriction IDs.
/// ⚠️ Make sure all IDs exist in `restrictionDefinitions`.
const Map<String, List<String>> kDiseaseRestrictionMap = {
  // Metabolic
  "diabetes_type_2": [
    "contains_refined_sugar",
    "contains_added_sugars",
    "contains_artificial_sweeteners",
    "contains_fructose",
    "contains_high_saturated_fat",
    "contains_high_sodium",
  ],

  "prediabetes": [
    "contains_refined_sugar",
    "contains_added_sugars",
    "contains_artificial_sweeteners",
    "contains_fructose",
  ],

  "insulin_resistance": [
    "contains_refined_sugar",
    "contains_added_sugars",
    "contains_artificial_sweeteners",
    "contains_fructose",
  ],

  // Thyroid / hormonal
  "hypothyroid": [
    "contains_gluten",
  ],

  "hyperthyroid": [
    "contains_caffeine",
  ],

  "pcos": [
    "contains_added_sugars",
    "contains_high_saturated_fat",
  ],
  // Digestive
  // DIGESTIVE & GUT HEALTH — medically accurate
  "ibs": [
    "contains_fodmap_triggers",
  ],

  "fodmap_sensitivity": [
    "contains_fodmap_triggers",
  ],

  "acid_reflux": [
    "contains_acid_reflux_triggers",
    "contains_caffeine",
  ],

  // Kidney / urinary
  // KIDNEY & URINARY HEALTH — medically accurate
  "kidney_stones": [
    "contains_oxalate_risk",
    "contains_high_sodium",
    "contains_added_sugars",
  ],

  "low_oxalate_needed": [
    "contains_oxalate_risk",
  ],

  "low_sodium_needed": [
    "contains_high_sodium",
  ],


  // Heart / blood pressure
  // HEART & BLOOD PRESSURE — medically accurate
  "hypertension": [
    "contains_high_sodium",
  ],

  "heart_disease_fat_control": [
    "contains_high_saturated_fat",
  ],


  // Pregnancy
  // PREGNANCY / PRENATAL — medically correct globally
  "avoid_raw": [
    "contains_raw_or_undercooked_risk",
    "contains_unpasteurized_dairy",
  ],

  "avoid_high_mercury": [
    "contains_high_mercury_fish",
  ],

  "pregnancy_general": [
    "contains_raw_or_undercooked_risk",
    "contains_high_mercury_fish",
    "contains_unpasteurized_dairy",
    "contains_alcohol",
  ],

};

class ConditionDetailSheet extends StatefulWidget {
  final String diseaseId;
  final String diseaseLabel;

  /// Global restriction state from parent: restrictionId → bool.
  final Map<String, Map<String, bool>> selectedRestrictions;



  const ConditionDetailSheet({
    super.key,
    required this.diseaseId,
    required this.diseaseLabel,
    required this.selectedRestrictions,
  });

  @override
  State<ConditionDetailSheet> createState() => _ConditionDetailSheetState();
}

class _ConditionDetailSheetState extends State<ConditionDetailSheet> {
  late Map<String, Map<String, bool>> _localRestrictions;

  @override
  void initState() {
    super.initState();

    // deep clone
    _localRestrictions = {
      for (final e in widget.selectedRestrictions.entries)
        e.key: Map<String, bool>.from(e.value)
    };

    // ensure disease key exists
    _localRestrictions.putIfAbsent(widget.diseaseId, () => {});
  }


  @override
  Widget build(BuildContext context) {
    final restrictionIds = kDiseaseRestrictionMap[widget.diseaseId] ?? const [];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.62,
      maxChildSize: 0.95,
      builder: (_, controller) {
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              Text(
                widget.diseaseLabel,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "These are the typical ingredient risks associated with this condition.",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF777777),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: restrictionIds.length,
                  itemBuilder: (_, i) {
                    final id = restrictionIds[i];

                    final def = restrictionDefinitions[id];
                    if (def == null) {
                      // safety guard – missing definition
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_outlined,
                                size: 18, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "$id – Missing definition. Configure later.",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF777777),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final checked = _localRestrictions[widget.diseaseId]?[id] == true;


                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: checked,
                              onChanged: (v) {
                                setState(() {
                                  _localRestrictions[widget.diseaseId]![id] = v == true;

                                });
                              },
                              activeColor: const Color(0xFF4CAF50),
                              checkColor: Colors.white,
                              side: BorderSide(
                                color: checked
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFB5B5B5),
                                width: 1.8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                def.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline, size: 18),
                              color: Colors.grey.shade600,
                              onPressed: () {
                                _showRestrictionInfo(def.title, def.description);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 52),
                          child: Text(
                            def.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 12),
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
                    Future.microtask(() {
                      Navigator.pop(context, {
                        widget.diseaseId: Map<String, bool>.from(
                          _localRestrictions[widget.diseaseId]!,
                        )
                      });
                    });
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Save",
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

  void _showRestrictionInfo(String title, String description) {
    showDialog(
      context: context,
      builder: (_) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              brightness: Brightness.light,
              surface: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            content: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Color(0xFF4CAF50)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
