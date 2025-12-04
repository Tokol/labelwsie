import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

enum LifestyleGoalType {
  restriction,
  awareness,
}

class LifestyleGoal {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String>? restrictionIds;
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
// LIST OF GOALS
// ---------------------------------------------------------------------------
const List<LifestyleGoal> kLifestyleGoals = [
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
      'contains_high_saturated_fat',
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

  // Awareness only
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
// PREF LIFESTYLE SCREEN (Wizard version)
// ---------------------------------------------------------------------------
class PrefLifestyleScreen extends StatefulWidget {
  final void Function(List<Map<String, dynamic>>) onChanged;
  final Set<String>? initialSelectedIds;

  const PrefLifestyleScreen({
    super.key,
    required this.onChanged,
    this.initialSelectedIds,
  });

  @override
  State<PrefLifestyleScreen> createState() => _PrefLifestyleScreenState();
}

class _PrefLifestyleScreenState extends State<PrefLifestyleScreen> {
  final Set<String> _selectedGoalIds = {};



  List<Map<String, dynamic>> _buildSelectedGoalsJson() {
    return _selectedGoalIds.map((goalId) {
      final goal = kLifestyleGoals.firstWhere((g) => g.id == goalId);
      return {
        'id': goal.id,
        'title': goal.title,
        'subtitle': goal.subtitle,
        'type': goal.type.toString().split('.').last,
        'restrictions': goal.restrictionIds,
        'scoringProfile': goal.scoringProfile,
      };
    }).toList();
  }

  int _getColumnCount(double width) {
    if (width < 340) return 2;
    if (width < 700) return 3;
    return 4;
  }



  @override
  void initState() {
    super.initState();

    if (widget.initialSelectedIds != null) {
      _selectedGoalIds.addAll(widget.initialSelectedIds!);
    }

    // notify wizard that page is valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged(_buildSelectedGoalsJson());
    });
  }


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: SingleChildScrollView(        // <-- FIX 1: wrap entire content
          padding: const EdgeInsets.only(bottom: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // TITLE
                const Text(
                  'Lifestyle & Fitness Goals',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),

                const SizedBox(height: 6),
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

                const SizedBox(height: 10),

                // 🔴 Legend
                Row(
                  children: [
                    Row(
                      children: const [
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
                    const SizedBox(width: 16),
                    Row(
                      children: const [
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

                // GRID (scroll disabled)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: kLifestyleGoals.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getColumnCount(width),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (_, index) {
                    final goal = kLifestyleGoals[index];
                    final selected = _selectedGoalIds.contains(goal.id);
                    return _buildGoalCard(goal, selected, width);
                  },
                ),

                const SizedBox(height: 40), // extra space for wizard bottom bar
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ---------------------------------------------------------------------------
  // CARD
  // ---------------------------------------------------------------------------
  Widget _buildGoalCard(LifestyleGoal goal, bool isSelected, double width) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            _selectedGoalIds.remove(goal.id);
          } else {
            _selectedGoalIds.add(goal.id);
          }
        });

        widget.onChanged(_buildSelectedGoalsJson());
      },
      onLongPress: () => _showDetails(goal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? const Color(0xFFEBF8EE) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFE5E5E5),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // left icon
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFF3F5F4),
                  ),
                  child: Icon(
                    goal.icon,
                    size: 20,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),

                const Spacer(),

                // ONLY COLORED DOT (NO TEXT)
                Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: goal.type == LifestyleGoalType.restriction
                        ? Colors.red
                        : Colors.orange,
                  ),
                ),

                const SizedBox(width: 4),

                if (isSelected)
                  const Icon(Icons.check_circle,
                      size: 17, color: Color(0xFF4CAF50)),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              goal.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              goal.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF777777),
                height: 1.3,
              ),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.type == LifestyleGoalType.restriction
                        ? 'Ingredient rules'
                        : 'Affects suggestions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _showDetails(goal),
                  child: const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFF2E7D32)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DETAILS SHEET
  // ---------------------------------------------------------------------------
  void _showDetails(LifestyleGoal goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
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
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEBF8EE),
                      ),
                      child: Icon(goal.icon, color: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Text(
                  goal.subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "How LabelWise uses this",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                ..._bulletsFor(goal).map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    "• $b",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF444444),
                      height: 1.35,
                    ),
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _bulletsFor(LifestyleGoal goal) {
    switch (goal.id) {
      case 'keto':
        return [
          'Flags sugars and starch-heavy ingredients.',
          'Prefers fats and proteins.',
        ];
      case 'low_carb':
        return [
          'Flags sugars and high-carb sources.',
        ];
      case 'low_fat':
        return [
          'Flags saturated & trans fats.',
        ];
      case 'clean_eating':
        return [
          'Flags artificial additives & ultra-processed items.',
        ];
      case 'weight_loss':
        return [
          'Flags high-sugar & high-fat foods.',
        ];
      case 'high_protein':
        return ['Highlights protein-rich foods.'];
      case 'high_fiber':
        return ['Favours fiber-rich ingredients.'];
      case 'muscle_gain':
        return ['Highlights calorie-dense, protein-rich foods.'];
      case 'balanced_macros':
        return ['Prefers balanced macronutrient profiles.'];
      default:
        return ['Adjusts scoring.'];
    }
  }
}
