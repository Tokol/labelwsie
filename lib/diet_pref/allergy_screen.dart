import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:label_wise/diet_pref/restriction_definitions.dart';
import 'package:material_symbols_icons/symbols.dart';

class AllergenOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  /// ID in restrictionDefinitions
  final String restrictionId;

  const AllergenOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.restrictionId,
  });
}

// Common allergens (can tweak later)
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


// Simple list for sensitivities
const List<String> kSensitivityOptions = [
  'Lactose intolerance',
  'Gluten sensitivity',
  'MSG sensitivity',
  'Artificial sweeteners',
  'Food colorings',
  'Preservatives',
];

class AllergiesScreen extends StatefulWidget {
  const AllergiesScreen({super.key});

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  final Set<String> _selectedAllergenIds = {};
  final Set<String> _selectedSensitivities = {};

  final TextEditingController _customController = TextEditingController();
  final List<String> _customAllergens = [];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  int _getColumnCount(double width) {
    if (width < 340) return 2;     // very small phones
    if (width < 600) return 3;     // normal phones
    if (width < 900) return 4;     // tablets
    return 5;                      // desktop/web
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 360;



    final bool hasAnySelection =
        _selectedAllergenIds.isNotEmpty ||
            _selectedSensitivities.isNotEmpty ||
            _customAllergens.isNotEmpty;

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
          'Allergies & Intolerances',
          style: TextStyle(
            fontSize: 18,
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
    children: [
    // 🔹 Everything scrolls inside here
    Expanded(
    child: SingleChildScrollView(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

    const SizedBox(height: 12),
    const Text(
    'Select all allergens that apply to you',
    style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1A1A1A),
    ),
    ),
    const SizedBox(height: 8),
    const Text(
    'These choices help LabelWise flag risky ingredients during scanning. '
    'Your profile stays on this device. 🔒',
    style: TextStyle(
    fontSize: 14,
    height: 1.4,
    color: Color(0xFF666666),
    ),
    ),
    const SizedBox(height: 20),

    // 🔹 COMMON ALLERGENS section
    const Text(
    'Common food allergens',
    style: TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Color(0xFF222222),
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
        itemBuilder: (context, index) {
          final allergen = kAllergens[index];
          final isSelected = _selectedAllergenIds.contains(allergen.id);
          return _buildAllergenCard(allergen, isSelected);
        },
      ),

    const SizedBox(height: 26),

    // 🔹 SENSITIVITIES section
    const Text(
    'Other food sensitivities (optional)',
    style: TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Color(0xFF222222),
    ),
    ),
    const SizedBox(height: 10),

    Wrap(
    spacing: 8,
    runSpacing: 8,
    children: kSensitivityOptions.map((label) {
    final selected =
    _selectedSensitivities.contains(label);
    return ChoiceChip(
    label: Text(
    label,
    style: TextStyle(
    fontSize: 12,
    color: selected
    ? Colors.white
        : const Color(0xFF444444),
    ),
    ),
    selected: selected,
    selectedColor: const Color(0xFF4CAF50),
    backgroundColor: const Color(0xFFE9ECEB),
    onSelected: (_) {
    setState(() {
    if (selected) {
    _selectedSensitivities.remove(label);
    } else {
    _selectedSensitivities.add(label);
    }
    });
    },
    );
    }).toList(),
    ),

    const SizedBox(height: 26),

    // 🔹 CUSTOM ALLERGENS
    const Text(
    'Add your own allergen',
    style: TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Color(0xFF222222),
    ),
    ),
    const SizedBox(height: 6),
    const Text(
    'For example: kiwi, cinnamon, beef protein, a specific E-number…',
    style: TextStyle(
    fontSize: 12,
    color: Color(0xFF777777),
    ),
    ),
    const SizedBox(height: 10),

    Row(
    children: [
    Expanded(
    child: TextField(
    controller: _customController,
    textInputAction: TextInputAction.done,
    onSubmitted: (_) => _addCustomAllergen(),
    decoration: InputDecoration(
    hintText: 'Type an ingredient and tap Add',
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    ),
    ),
    ),
    const SizedBox(width: 10),
      SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: _addCustomAllergen,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Add',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),

    ],
    ),

    const SizedBox(height: 12),

    if (_customAllergens.isNotEmpty)
    Wrap(
    spacing: 8,
    runSpacing: 8,
    children: _customAllergens.map((item) {
    return  Chip(
      backgroundColor: const Color(0xFFE2F4E6), // slightly darker soft green
      label: Text(
        item,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF1A1A1A), // dark text
          fontWeight: FontWeight.w500,
        ),
      ),
      deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF388E3C)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFBFE7C7)), // soft border
      ),
    );

    }).toList(),
    ),
    ],
    ),
    ),
    ),

    // 🔹 fixed button
    SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
    onPressed: hasAnySelection ? () {} : null,
    style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF4CAF50),
    disabledBackgroundColor: const Color(0xFFD5D5D5),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    ),
    ),
    child: const Text(
    'Save & Continue',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    ),
    ),
    ),
    ),
    const SizedBox(height: 16),
    ],
    ),
    ),
    ),

    );
  }

  Widget _buildAllergenCard(AllergenOption allergen, bool isSelected) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          isSelected
              ? _selectedAllergenIds.remove(allergen.id)
              : _selectedAllergenIds.add(allergen.id);
        });
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? const Color(0xFFEBF8EE) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFE5E5E5),
            width: 2,
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
                // Big circular icon
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
                    allergen.icon,
                    size: 20,
                    color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),

                const Spacer(),

                // Info icon for details
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showAllergenDetails(allergen);
                  },
                  child: const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Title only (clean)
            Text(
              allergen.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }


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
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------ HEADER -------------
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEBF8EE),
                      ),
                      child: Icon(
                        allergen.icon,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        allergen.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  allergen.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),

                const SizedBox(height: 22),

                // ------------ DESCRIPTION (optional) -------------
                if (rule != null) ...[
                  Text(
                    rule.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rule.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ------------ EXAMPLES -------------
                const Text(
                  'Common label appearances:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: examples.map((ex) {
                    return Chip(
                      backgroundColor: const Color(0xFFEFF7F1),
                      label: Text(
                        ex,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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


  void _addCustomAllergen() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;

    if (!_customAllergens.contains(text)) {
      setState(() {
        _customAllergens.add(text);
      });
    }
    _customController.clear();
    HapticFeedback.selectionClick();
  }
  void _showAllExamplesBottomSheet(String title, List<String> examples) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$title – Full List",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: examples.map((ex) {
                        return Chip(
                          backgroundColor: const Color(0xFFEFF7F1),
                          label: Text(
                            ex,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



}
