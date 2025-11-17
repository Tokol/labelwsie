import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'condition_list_sheet.dart';
import 'condition_summary_sheet.dart';
import 'condition_detail_sheet.dart'; // for kDiseaseRestrictionMap

class MedicalNeedsScreen extends StatefulWidget {
   final List<Map<String, dynamic>>? initialData; // 👈 optional

   const MedicalNeedsScreen({
    super.key,
    this.initialData,
  });

  @override
  State<MedicalNeedsScreen> createState() => _MedicalNeedsScreenState();
}

class _MedicalNeedsScreenState extends State<MedicalNeedsScreen> {
  // global state
  final Set<String> _selectedConditions = {}; // disease IDs
  final Map<String, Map<String, bool>> _selectedRestrictions = {};

  @override
  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      _restoreFromJson(widget.initialData!);
    }
  }


  final List<_Category> _categories = const [
    _Category(
      id: 'metabolic',
      label: 'Metabolic & Blood Sugar',
      icon: Symbols.health_and_safety_rounded,
      subtitle: 'Diabetes, insulin, glucose needs',
      diseaseIds: [
        "diabetes_type_2",
        "prediabetes",
        "insulin_resistance",
      ],
    ),
    _Category(
      id: 'thyroid',
      label: 'Thyroid & Hormonal',
      icon: Symbols.brightness_auto_rounded,
      subtitle: 'Hypothyroid, PCOS, metabolism',
      diseaseIds: [
        "hypothyroid",
        "hyperthyroid",
        "pcos",
      ],
    ),
    _Category(
      id: 'digestive',
      label: 'Digestive & Gut Health',
      icon: Symbols.medical_information_rounded,
      subtitle: 'IBS, FODMAP, reflux triggers',
      diseaseIds: [
        "ibs",
        "fodmap_sensitivity",
        "acid_reflux",
      ],
    ),
    _Category(
      id: 'kidney',
      label: 'Kidney & Urinary Health',
      icon: Symbols.water_rounded,
      subtitle: 'Oxalate & sodium needs',
      diseaseIds: [
        "kidney_stones",
        "low_oxalate_needed",
        "low_sodium_needed",
      ],
    ),
    _Category(
      id: 'heart',
      label: 'Heart & Blood Pressure',
      icon: Symbols.favorite_rounded,
      subtitle: 'Sodium & fat restrictions',
      diseaseIds: [
        "hypertension",
        "heart_disease_fat_control",
      ],
    ),
    _Category(
      id: 'pregnancy',
      label: 'Pregnancy / Prenatal',
      icon: Symbols.family_restroom_rounded,
      subtitle: 'Avoid high-risk ingredients',
      diseaseIds: [
        "avoid_raw",
        "avoid_high_mercury",
      ],
    ),
  ];

  List<Map<String, dynamic>> _buildFinalMedicalArray() {
    final List<Map<String, dynamic>> list = [];

    for (final cat in _categories) {
      final activeDiseaseIds =
      _selectedConditions.intersection(cat.diseaseIds.toSet());

      if (activeDiseaseIds.isEmpty) continue;

      for (final diseaseId in activeDiseaseIds) {
        final restrictionIds =
            kDiseaseRestrictionMap[diseaseId] ?? const <String>[];

        final diseaseMap = _selectedRestrictions[diseaseId] ?? {};
        final selected = restrictionIds
            .where((rid) => diseaseMap[rid] == true)
            .toList();

        list.add({
          "category_id": cat.id,
          "category_label": cat.label,
          "disease_id": diseaseId,
          "disease_label": _lookupDiseaseLabel(diseaseId),
          "restrictions": selected,
        });
      }
    }

    return list;
  }

// helper → get disease label from any category
  String _lookupDiseaseLabel(String diseaseId) {
    for (final entry in kDiseaseMap.entries) {
      for (final d in entry.value) {
        if (d.id == diseaseId) return d.label;
      }
    }
    return diseaseId;
  }



  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;

    int columns;
    if (width < 360) {
      columns = 2;      // iPhone SE / very small android
    } else if (width < 500) {
      columns = 2;      // normal phones
    } else {
      columns = 3;      // tablets or wide phones
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Medical Dietary Needs",
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              const Text(
                "Support your health needs",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "LabelWise will highlight risky ingredients based on your medical profile. Your data stays on device. 🔒",
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 18),

              if (_selectedConditions.isNotEmpty) _buildSelectedCategoryChips(),
              if (_selectedConditions.isNotEmpty) const SizedBox(height: 20),

              Expanded(
                child: GridView.builder(
                  itemCount: _categories.length,
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: width < 360 ? 160 : 190,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: width < 360 ? 0.78 : 0.85,
                  ),

                  itemBuilder: (_, index) {
                    final cat = _categories[index];
                    final isActive = _selectedConditions
                        .intersection(cat.diseaseIds.toSet())
                        .isNotEmpty;

                    return _buildCategoryTile(cat, isActive);
                  },
                ),
              ),

              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedConditions.isEmpty
                      ? null
                      : () {
                    final arr = _buildFinalMedicalArray();

                    final prettyJson = const JsonEncoder.withIndent("  ").convert(arr);

                    debugPrint("FINAL MEDICAL ARRAY:\n$prettyJson");
                   // Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    disabledBackgroundColor: const Color(0xFFD5D5D5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Save Preferences",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Category tile
  Widget _buildCategoryTile(_Category cat, bool highlight) {
    final width = MediaQuery.of(context).size.width;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openCategory(cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.all(width < 360 ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: highlight ? const Color(0xFFEBF8EE) : Colors.white,
          border: Border.all(
            color: highlight ? const Color(0xFF4CAF50) : const Color(0xFFE5E5E5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(highlight ? 0.10 : 0.04),
              blurRadius: highlight ? 14 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // 👈 KEY FIX
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ICON
                  Container(
                    height: width < 360 ? 34 : 40,
                    width: width < 360 ? 34 : 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: highlight ? const Color(0xFF4CAF50) : const Color(0xFFF3F5F4),
                    ),
                    child: Icon(
                      cat.icon,
                      size: width < 360 ? 20 : 24,
                      color: highlight ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // TITLE
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: width < 360 ? 14 : 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),

                  SizedBox(height: width < 360 ? 4 : 6),

                  // SUBTITLE — SAFE
                  Flexible(
                    child: Text(
                      cat.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        height: 1.1,
                        fontSize: width < 360 ? 10 : 11.5,
                        color: const Color(0xFF777777),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }



  // Selected category chips
  Widget _buildSelectedCategoryChips() {
    final activeCategoryIds = <String>{};

    for (final cat in _categories) {
      if (_selectedConditions.intersection(cat.diseaseIds.toSet()).isNotEmpty) {
        activeCategoryIds.add(cat.id);
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: activeCategoryIds.map((id) {
        final cat = _categories.firstWhere((c) => c.id == id);
        return  Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F7EF),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: const Color(0xFF4CAF50), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cat.label,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: 6),

              // 👇 This is your INFO icon and WILL trigger
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  print("INFO tapped");
                  _openConditionSummary(cat.id);
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),

              const SizedBox(width: 6),


              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  print("DELETE tapped");
                  _removeCategoryCompletely(cat);
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        );

      }).toList(),
    );
  }

  // Completely clear one category (A + reset tile)
  void _removeCategoryCompletely(_Category cat) {
    setState(() {
      for (final diseaseId in cat.diseaseIds) {
        // Remove disease from selected conditions
        _selectedConditions.remove(diseaseId);

        // Remove nested restriction map for this disease
        _selectedRestrictions.remove(diseaseId);
      }
    });
  }


  void _openConditionSummary(String categoryId) {
    print('ok');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ConditionSummarySheet(
        categoryId: categoryId,
        selectedConditions: _selectedConditions,
        selectedRestrictions: _selectedRestrictions,
      ),
    );
  }

  Future<void> _openCategory(_Category cat) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return ConditionListSheet(
          categoryId: cat.id,
          categoryLabel: cat.label,
          selectedConditions: _selectedConditions,
          selectedRestrictions: _selectedRestrictions,
        );
      },
    );

    if (result == null) return;

    setState(() {
      _selectedConditions
        ..clear()
        ..addAll(result["conditions"] as Set<String>);

      _selectedRestrictions
        ..clear()
        ..addAll(result["restrictions"] as Map<String, Map<String, bool>>
        );
    });
  }



  void _restoreFromJson(List<Map<String, dynamic>> arr) {
    _selectedConditions.clear();
    _selectedRestrictions.clear();

    for (final row in arr) {
      final diseaseId = row["disease_id"];
      final restrictions = row["restrictions"] as List<dynamic>;

      _selectedConditions.add(diseaseId);

      _selectedRestrictions[diseaseId] = {};
      for (final rid in restrictions) {
        _selectedRestrictions[diseaseId]![rid] = true;
      }
    }

    setState(() {});
  }



}


// helper → get disease label from any category
String _lookupDiseaseLabel(String diseaseId) {
  for (final entry in kDiseaseMap.entries) {
    for (final d in entry.value) {
      if (d.id == diseaseId) return d.label;
    }
  }
  return diseaseId;
}


class _Category {
  final String id;
  final String label;
  final IconData icon;
  final String subtitle;
  final List<String> diseaseIds;

  const _Category({
    required this.id,
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.diseaseIds,
  });
}
