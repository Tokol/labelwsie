import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:label_wise/diet_pref/restriction_definitions.dart';
import 'package:material_symbols_icons/symbols.dart';

class AllergenOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String restrictionId;

  const AllergenOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.restrictionId,
  });
}

// -------------------------------------------------------------
// Common allergens
// -------------------------------------------------------------
const List<AllergenOption> kAllergens = [
  AllergenOption(
    id: 'milk',
    title: 'Dairy',
    subtitle: 'Milk, whey, lactose',
    icon: Symbols.local_drink_rounded,
    restrictionId: 'contains_dairy',
  ),
  AllergenOption(
    id: 'eggs',
    title: 'Eggs',
    subtitle: 'Egg whites, albumin',
    icon: Symbols.egg_alt_rounded,
    restrictionId: 'contains_eggs',
  ),
  AllergenOption(
    id: 'peanut',
    title: 'Peanuts',
    subtitle: 'Peanut flour, oil',
    icon: Symbols.nutrition_rounded,
    restrictionId: 'contains_peanuts',
  ),

  AllergenOption(
    id: 'tree_nuts',
    title: 'Tree Nuts',
    subtitle: 'Almond, cashew, walnut',
    icon: Symbols.yard_rounded,
    restrictionId: 'contains_treenuts',
  ),

  AllergenOption(
    id: 'gluten',
    title: 'Gluten',
    subtitle: 'Gluten grains',
    icon: Symbols.grain_rounded,
    restrictionId: 'contains_gluten',
  ),

  AllergenOption(
    id: 'soy',
    title: 'Soy',
    subtitle: 'Soy protein, lecithin',
    icon: Symbols.eco_rounded,
    restrictionId: 'contains_soy',
  ),

  AllergenOption(
    id: 'fish',
    title: 'Fish',
    subtitle: 'All fish species',
    icon: Symbols.set_meal_rounded,
    restrictionId: 'contains_fish_or_seafood',
  ),

  AllergenOption(
    id: 'shellfish',
    title: 'Shellfish',
    subtitle: 'Shrimp, crab, etc.',
    icon: Symbols.kayaking_rounded,
    restrictionId: 'contains_shellfish_crustaceans',
  ),

  AllergenOption(
    id: 'sesame',
    title: 'Sesame',
    subtitle: 'Seeds & oils',
    icon: Symbols.circle_rounded,
    restrictionId: 'contains_sesame',
  ),

  AllergenOption(
    id: 'mustard',
    title: 'Mustard',
    subtitle: 'Seeds, powder, paste',
    icon: Symbols.dinner_dining_rounded,
    restrictionId: 'contains_mustard',
  ),

  AllergenOption(
    id: 'sulfites',
    title: 'Sulfites',
    subtitle: 'E220–E228',
    icon: Symbols.science_rounded,
    restrictionId: 'contains_sulfites',
  ),

  AllergenOption(
    id: 'celery',
    title: 'Celery',
    subtitle: 'Stalk, root, seeds',
    icon: Symbols.ramen_dining_rounded,
    restrictionId: 'contains_celery',
  ),

  AllergenOption(
    id: 'lupin',
    title: 'Lupin',
    subtitle: 'Bakery flour & protein',
    icon: Symbols.local_florist_rounded,
    restrictionId: 'contains_lupin',
  ),

  AllergenOption(
    id: 'molluscs',
    title: 'Molluscs',
    subtitle: 'Clams, mussels, squid',
    icon: Symbols.directions_boat_filled_rounded,
    restrictionId: 'contains_molluscs',
  ),

  AllergenOption(
    id: 'corn',
    title: 'Corn / Maize',
    subtitle: 'Starch & sweeteners',
    icon: Symbols.grass_rounded,
    restrictionId: 'contains_corn',
  ),

  AllergenOption(
    id: 'mango',
    title: 'Mango',
    subtitle: 'Fruit allergy (rare)',
    icon: Symbols.restaurant_rounded,
    restrictionId: 'contains_mango',
  ),
];


// -------------------------------------------------------------
// Sensitivities
// -------------------------------------------------------------
const List<String> kSensitivityOptions = [
  'Lactose intolerance',
  'Gluten sensitivity',
  'MSG sensitivity',
  'Artificial sweeteners',
  'Food colorings',
  'Preservatives',
];


// -------------------------------------------------------------
// PRE-ALLERGY SCREEN (for wizard)
// -------------------------------------------------------------
class PreAllergiesScreen extends StatefulWidget {

  final Set<String>? initialAllergens;
  final Set<String>? initialSensitivities;
  final List<String>? initialCustom;

  final Function({
  required Set<String> allergens,
  required Set<String> sensitivities,
  required List<String> custom,


  }) onChanged;

  const PreAllergiesScreen({
    super.key,
    required this.onChanged,
    this.initialAllergens,
    this.initialSensitivities,
    this.initialCustom,
  });

  @override
  State<PreAllergiesScreen> createState() => _PreAllergiesScreenState();
}

class _PreAllergiesScreenState extends State<PreAllergiesScreen> {
  final Set<String> _selectedAllergenIds = {};
  final Set<String> _selectedSensitivities = {};
  final List<String> _customAllergens = [];

  final TextEditingController _customController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initialAllergens != null) {
      _selectedAllergenIds.addAll(widget.initialAllergens!);
    }
    if (widget.initialSensitivities != null) {
      _selectedSensitivities.addAll(widget.initialSensitivities!);
    }
    if (widget.initialCustom != null) {
      _customAllergens.addAll(widget.initialCustom!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerCallback(); // so NEXT button activates automatically
    });
  }




  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  // determine number of columns
  int _getColumnCount(double width) {
    if (width < 340) return 2;
    if (width < 600) return 3;
    if (width < 900) return 4;
    return 5;
  }

  void _triggerCallback() {
    widget.onChanged(
      allergens: _selectedAllergenIds,
      sensitivities: _selectedSensitivities,
      custom: _customAllergens,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Select all allergens that apply',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'These preferences help LabelWise flag risky ingredients.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  "Common food allergens",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: kAllergens.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getColumnCount(width),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, i) {
                    final item = kAllergens[i];
                    final isSelected =
                    _selectedAllergenIds.contains(item.id);

                    return _buildAllergenCard(item, isSelected);
                  },
                ),

                const SizedBox(height: 26),
                const Text(
                  "Other food sensitivities (optional)",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kSensitivityOptions.map((label) {
                    final sel = _selectedSensitivities.contains(label);

                    return ChoiceChip(
                      selected: sel,
                      label: Text(
                        label,
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                      selectedColor: const Color(0xFF4CAF50),
                      backgroundColor: const Color(0xFFE9ECEB),
                      onSelected: (_) {
                        setState(() {
                          sel
                              ? _selectedSensitivities.remove(label)
                              : _selectedSensitivities.add(label);
                        });
                        _triggerCallback();
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 26),
                const Text(
                  "Add your own allergen",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addCustomAllergen(),
                        decoration: InputDecoration(
                          hintText: "e.g., kiwi, cinnamon, E621…",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        elevation: 1,
                        shadowColor: Colors.black.withOpacity(0.10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _addCustomAllergen,
                      child: const Text("Add",style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                if (_customAllergens.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _customAllergens.map((item) {
                      return Chip(
                        backgroundColor: const Color(0xFFE6F4EA),
                        label: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFFD32F2F)),
                        onDeleted: () {
                          setState(() => _customAllergens.remove(item));
                          _triggerCallback();
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFB7DEC0)),
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

  // --------------------------------------------------------------------------
  // UI CARD
  // --------------------------------------------------------------------------
  Widget _buildAllergenCard(AllergenOption a, bool isSelected) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          isSelected
              ? _selectedAllergenIds.remove(a.id)
              : _selectedAllergenIds.add(a.id);
        });
        _triggerCallback();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? const Color(0xFFEBF8EE) : Colors.white,
          border: Border.all(
            width: 2,
            color: isSelected
                ? const Color(0xFF4CAF50)
                : const Color(0xFFE5E5E5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.10 : 0.04),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFF3F5F4),
                  ),
                  child: Icon(
                    a.icon,
                    size: 20,
                    color:
                    isSelected ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _showAllergenDetails(a),
                  child: const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xFF4CAF50),
                  ),
                )
              ],
            ),

            const SizedBox(height: 12),
            Text(
              a.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BOTTOM SHEET
  // --------------------------------------------------------------------------
  void _showAllergenDetails(AllergenOption allergen) {
    final rule = restrictionDefinitions[allergen.restrictionId];
    final examples = rule?.examples ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEBF8EE),
                      ),
                      child: Icon(allergen.icon, color: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        allergen.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Text(
                  allergen.subtitle,
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 16),
                const Text(
                  "Common label appearances:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: examples.map((e) {
                    return Chip(
                      label: Text(e),
                      backgroundColor: const Color(0xFFEFF7F1),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // Add custom
  // --------------------------------------------------------------------------
  void _addCustomAllergen() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      if (!_customAllergens.contains(text)) {
        _customAllergens.add(text);
      }
    });

    _customController.clear();
    _triggerCallback();
  }
}
