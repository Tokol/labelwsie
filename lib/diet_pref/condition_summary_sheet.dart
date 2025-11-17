import 'package:flutter/material.dart';
import 'package:label_wise/diet_pref/restriction_definitions.dart';

import 'condition_detail_sheet.dart'; // kDiseaseRestrictionMap
import 'condition_list_sheet.dart';   // kDiseaseMap, DiseaseEntry

class ConditionSummarySheet extends StatelessWidget {
  final String categoryId;

  /// Example structure:
  /// {
  ///   "diabetes_type_2": { "contains_added_sugars": true, "contains_refined_sugar": true },
  ///   "pcos": { "contains_high_saturated_fat": true }
  /// }
  final Map<String, Map<String, bool>> selectedRestrictions;

  final Set<String> selectedConditions;

  const ConditionSummarySheet({
    super.key,
    required this.categoryId,
    required this.selectedRestrictions,
    required this.selectedConditions,
  });

  @override
  Widget build(BuildContext context) {
    final diseases = kDiseaseMap[categoryId] ?? const <DiseaseEntry>[];

    // We show only diseases that have at least ONE restriction toggled ON
    final activeDiseases = diseases.where((d) {
      final list = _selectedRestrictionsForDisease(d.id);
      return list.isNotEmpty;
    }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  height: 5,
                  width: 60,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const Text(
                "Active checks in this category",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "These are the ingredient-level checks LabelWise will apply "
                    "based on your selected medical conditions.",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF777777),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: activeDiseases.isEmpty
                    ? const Center(
                  child: Text(
                    "No checks configured yet.\nTap the card to add conditions and checks.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF777777),
                    ),
                  ),
                )
                    : ListView.builder(
                  controller: controller,
                  itemCount: activeDiseases.length,
                  itemBuilder: (_, index) {
                    final disease = activeDiseases[index];
                    final list =
                    _selectedRestrictionsForDisease(disease.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildDiseaseCard(disease.label, list),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Return only the restrictionIds that are:
  /// 1. allowed for this disease
  /// 2. toggled ON inside selectedRestrictions[diseaseId]
  List<String> _selectedRestrictionsForDisease(String diseaseId) {
    final diseaseMap = selectedRestrictions[diseaseId] ?? {};

    final allowedList = kDiseaseRestrictionMap[diseaseId] ?? const <String>[];

    return allowedList
        .where((rid) => diseaseMap[rid] == true)
        .toList(growable: false);
  }

  Widget _buildDiseaseCard(String diseaseLabel, List<String> ids) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF7FBF8),
        border: Border.all(
          color: const Color(0xFFCDEED4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main disease title
          Text(
            diseaseLabel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          // Bullet list
          ...ids.map((rid) {
            final def = restrictionDefinitions[rid];
            final title = def?.title ?? rid;

            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF333333),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
