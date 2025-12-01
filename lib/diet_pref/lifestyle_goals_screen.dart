import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

enum LifestyleGoalType {
  restriction, // adds ingredient-based restrictions
  awareness,   // only used for scoring / recommendations
}


class LifestyleGoal {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  /// restriction → maps to restrictionDefinitions (for backend / LLM)
  final List<String>? restrictionIds;

  /// awareness → used by scoring engine (for backend / LLM)
  final String? scoringProfile;

  final LifestyleGoalType type;

  const LifestyleGoal({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    this.restrictionIds,
    this.scoringProfile,
  });
}

// ---------------------------------------------------------------------------
//  LIFESTYLE & FITNESS GOALS (9 items, 3×3 grid)
// ---------------------------------------------------------------------------

const List<LifestyleGoal> kLifestyleGoals = [
  // 🔴 RESTRICTION-BASED GOALS
  LifestyleGoal(
    id: 'keto',
    title: 'Keto',
    subtitle: 'Very low-carb, high fat',
    icon: Symbols.local_fire_department_rounded,
    type: LifestyleGoalType.restriction,
    restrictionIds: [
      'contains_sugar',
      'contains_wheat',
      'contains_grains_general',
      'contains_high_carbohydrate_sources',
      'contains_starch',
    ],
  ),
  LifestyleGoal(
    id: 'low_carb',
    title: 'Low-Carb',
    subtitle: 'Reduced sugar & starches',
    icon: Symbols.bloodtype_rounded,
    type: LifestyleGoalType.restriction,
    restrictionIds: [
      'contains_sugar',
      'contains_high_carbohydrate_sources',
      'contains_grains_general',
    ],
  ),
  LifestyleGoal(
    id: 'low_fat',
    title: 'Low-Fat',
    subtitle: 'Avoids fatty & oily foods',
    icon: Symbols.oil_barrel_rounded,
    type: LifestyleGoalType.restriction,
    restrictionIds: [
      'contains_saturated_fat',
      'contains_trans_fats',
      'contains_seed_oils',
    ],
  ),
  LifestyleGoal(
    id: 'clean_eating',
    title: 'Clean Eating',
    subtitle: 'Avoids processed additives',
    icon: Symbols.eco_rounded,
    type: LifestyleGoalType.restriction,
    restrictionIds: [
      'contains_artificial_additives_general',
      'contains_refined_sugar',
      'contains_ultra_processed',
      'contains_preservatives_general',
    ],
  ),
  LifestyleGoal(
    id: 'weight_loss',
    title: 'Weight Loss',
    subtitle: 'Lower sugar & fat intake',
    icon: Symbols.monitor_weight_rounded,
    type: LifestyleGoalType.restriction,
    restrictionIds: [
      'contains_sugar',
      'contains_high_fat',
      'contains_high_calorie_density',
    ],
  ),

  // 🟢 AWARENESS-BASED GOALS (SCORING ONLY)
  LifestyleGoal(
    id: 'high_protein',
    title: 'High-Protein',
    subtitle: 'Good for muscle building',
    icon: Symbols.fitness_center_rounded,
    type: LifestyleGoalType.awareness,
    scoringProfile: 'high_protein',
  ),
  LifestyleGoal(
    id: 'high_fiber',
    title: 'High-Fiber',
    subtitle: 'Digestive health focused',
    icon: Symbols.energy_savings_leaf_rounded,
    type: LifestyleGoalType.awareness,
    scoringProfile: 'high_fiber',
  ),
  LifestyleGoal(
    id: 'muscle_gain',
    title: 'Muscle Gain',
    subtitle: 'High protein + calories',
    icon: Symbols.sports_gymnastics_rounded,
    type: LifestyleGoalType.awareness,
    scoringProfile: 'muscle_gain',
  ),
  LifestyleGoal(
    id: 'balanced_macros',
    title: 'Balanced Macros',
    subtitle: 'Moderate carb–fat–protein',
    icon: Symbols.pie_chart_rounded,
    type: LifestyleGoalType.awareness,
    scoringProfile: 'balanced_macros',
  ),
];

// ---------------------------------------------------------------------------
//  SCREEN
// ---------------------------------------------------------------------------

class LifestyleGoalsScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialSelectedGoals;

  const LifestyleGoalsScreen({
    super.key,
    this.initialSelectedGoals,
  });


  @override
  State<LifestyleGoalsScreen> createState() => _LifestyleGoalsScreenState();
}

class _LifestyleGoalsScreenState extends State<LifestyleGoalsScreen> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.initialSelectedGoals != null) {
      for (final goal in widget.initialSelectedGoals!) {
        final id = goal['id'];
        if (id != null) {
          _selectedGoalIds.add(id);
        }
      }
    }
  }


  final Set<String> _selectedGoalIds = {};
  late final List<LifestyleGoal> _goals = kLifestyleGoals;

  List<Map<String, dynamic>> _buildSelectedGoalsJson() {
    final List<Map<String, dynamic>> selected = [];

    for (final goalId in _selectedGoalIds) {
      final goal = _goals.firstWhere((g) => g.id == goalId);

      selected.add({
        'id': goal.id,
        'title': goal.title,
        'subtitle': goal.subtitle,
        'type': goal.type.toString().split('.').last, // restriction or awareness
        'restrictions': goal.restrictionIds,
      });
    }

    return selected;
  }


  int _getColumnCount(double width) {
    if (width < 340) return 2; // very small phones
    if (width < 700) return 3; // normal phones
    return 4;                  // tablets / web
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool hasAnySelection = _selectedGoalIds.isNotEmpty;

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
          'Lifestyle & Fitness Goals',
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
              // scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'Tell us your goals',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'These choices help LabelWise personalise your food-label scanning.\n'
                            '• Restrict goals add ingredient rules.\n'
                            '• Aware goals adjust scoring only.\n'
                            'You can change these anytime. 🔄',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Color(0xFF666666),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          // 🔴 Restrict
                          Row(
                            children: [
                              Icon(Icons.circle, size: 10, color: Colors.red),
                              SizedBox(width: 4),
                              Text(
                                "Restrict",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF444444),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(width: 16),

                          // 🟡 Aware
                          Row(
                            children: [
                              Icon(Icons.circle, size: 10, color: Colors.orange),
                              SizedBox(width: 4),
                              Text(
                                "Aware",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF444444),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),


                      const SizedBox(height: 20),

                      const Text(
                        'Select all goals that apply to you',
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
                        itemCount: kLifestyleGoals.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getColumnCount(width),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: _aspectRatioForWidth(width),
                        ),
                        itemBuilder: (context, index) {
                          final goal = kLifestyleGoals[index];
                          final isSelected =
                          _selectedGoalIds.contains(goal.id);
                          return _buildGoalCard(goal, isSelected, _getColumnCount(width));

                        },
                      ),
                    ],
                  ),
                ),
              ),

              // fixed bottom button
              if (hasAnySelection)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();

                      final jsonResult = _buildSelectedGoalsJson();
                      print(jsonResult);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      elevation: 2,
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

  // -------------------------------------------------------------------------
  //  GOAL CARD
  // -------------------------------------------------------------------------

  Widget _buildGoalCard(LifestyleGoal goal, bool isSelected, int crossAxisCount) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width / crossAxisCount - 28; // more relaxed padding
    final bool compact = cardWidth < 135; // triggers compact UI

    final double padding = compact ? 10 : 14;
    final double iconSize = compact ? 18 : 22;
    final double titleSize = compact ? 12.5 : 14;
    final double subtitleSize = compact ? 10.5 : 12;

    final bool isRestriction = goal.type == LifestyleGoalType.restriction;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            _selectedGoalIds.remove(goal.id);
          } else {
            _selectedGoalIds.add(goal.id);
          }
        });
      },
      onLongPress: () => _showGoalDetails(goal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? const Color(0xFFEBF8EE) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFE5E5E5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.08 : 0.04),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------------
            // TOP ROW FIXED — NO OVERFLOW EVER
            // ---------------------------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left icon
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFF3F5F4),
                  ),
                  child: Icon(
                    goal.icon,
                    size: iconSize,
                    color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),

                const SizedBox(width: 6),

                // Badge + checkmark inside a flexible row
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: _buildTypeBadge(
                            goal.type,
                          
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Color(0xFF4CAF50),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: compact ? 8 : 10),

            // ---------------------------------------------------------
            // TITLE
            // ---------------------------------------------------------
            Text(
              goal.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),

            SizedBox(height: compact ? 3 : 4),

            // ---------------------------------------------------------
            // SUBTITLE — auto compact into 1 line when needed
            // ---------------------------------------------------------
            Text(
              goal.subtitle,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: subtitleSize,
                height: 1.3,
                color: const Color(0xFF777777),
              ),
            ),

            // ---------------------------------------------------------
            // BOTTOM ROW — adaptive compact layout
            // ---------------------------------------------------------
            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: Text(
                    isRestriction ? "Ingredient rules" : "Affects suggestions",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 9.5 : 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                InkWell(
                  onTap: () => _showGoalDetails(goal),
                  child: const Icon(
                    Icons.info_outline,
                    size: 17,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  double _aspectRatioForWidth(double width) {
    if (width < 340) return 0.70;   // very tiny phones → taller cards
    if (width < 380) return 0.78;   // normal Android 360px → slightly taller
    if (width < 430) return 0.85;   // large phones
    return 0.92;                    // tablets & web
  }
  // -------------------------------------------------------------------------
  //  BOTTOM SHEET
  // -------------------------------------------------------------------------

  void _showGoalDetails(LifestyleGoal goal) {
    final bool isRestriction = goal.type == LifestyleGoalType.restriction;
    final List<String> bullets = _buildGoalBullets(goal);

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
                // header
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
                        goal.icon,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        goal.title,
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
                  goal.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  isRestriction
                      ? 'How LabelWise uses this goal'
                      : 'How LabelWise adjusts suggestions',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 10),

                ...bullets.map((b) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF444444),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            b,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF444444),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeBadge(LifestyleGoalType type) {
    final isRestriction = type == LifestyleGoalType.restriction;

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRestriction ? Icons.circle : Icons.circle,
            size: 6,
            color: isRestriction ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              isRestriction ? "Restrict" : "Aware",
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showSnack(LifestyleGoalType type) {
    final msg = type == LifestyleGoalType.restriction
        ? "Restriction: This goal adds ingredient rules during scanning."
        : "Awareness: This goal influences suggestions but does not restrict ingredients.";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      //  backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }






  List<String> _buildGoalBullets(LifestyleGoal goal) {
    switch (goal.id) {
      case 'keto':
        return [
          'Flags products high in sugars, starches or grain-based carbs.',
          'Prefers products with fats and proteins over carbs.',
          'Does not verify macros exactly, but focuses on obvious carb sources.',
        ];
      case 'low_carb':
        return [
          'Flags products with added sugars and obvious high-carb ingredients.',
          'Prefers options with fewer refined carbs.',
        ];
      case 'low_fat':
        return [
          'Flags products with saturated or trans fats when clearly indicated.',
          'Prefers items that use lower-fat or unsaturated fat sources.',
        ];
      case 'clean_eating':
        return [
          'Flags products with artificial colours, sweeteners or heavy additives.',
          'Flags ultra-processed ingredient lists when clearly visible.',
          'Prefers simpler ingredient lists with fewer processed components.',
        ];
      case 'weight_loss':
        return [
          'Flags products that are high in added sugars or obvious high-fat content.',
          'Prefers lower-calorie-density snacks and meals when possible.',
        ];
      case 'high_protein':
        return [
          'Does not block ingredients, but highlights foods with higher protein content.',
          'Uses protein information (when available) to mark better options.',
        ];
      case 'high_fiber':
        return [
          'Does not block ingredients, but prefers foods containing whole grains, seeds, and fiber-rich ingredients.',
          'Highlights options that may support digestion and satiety.',
        ];
      case 'muscle_gain':
        return [
          'Does not block ingredients, but favours foods high in protein and energy.',
          'May highlight calorie-dense options that support bulking phases.',
        ];
      case 'balanced_macros':
        return [
          'Does not block any ingredient.',
          'Prefers foods with a more balanced carb–fat–protein profile when information is available.',
        ];
      default:
        return [
          'LabelWise will use this goal to slightly adjust how products are evaluated and explained.',
        ];
    }
  }
}
