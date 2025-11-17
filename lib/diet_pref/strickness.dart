import 'package:flutter/material.dart';
import 'package:label_wise/diet_pref/restriction_definitions.dart';
import 'package:label_wise/diet_pref/rules/buddhist_rule.dart';
import 'package:label_wise/diet_pref/rules/christian_rule.dart';
import 'package:label_wise/diet_pref/rules/hindu_rules.dart';
import 'package:label_wise/diet_pref/rules/jains_rules.dart';
import 'package:label_wise/diet_pref/rules/jew_kosher_rule.dart';
import 'package:label_wise/diet_pref/rules/muslim_rules.dart';
import 'package:label_wise/diet_pref/rules/sikh_rules.dart';
import 'package:material_symbols_icons/symbols.dart';

class StrictnessLevel {
  final String id;
  final String title;
  final String subtitle;
  final bool isRecommended;
  final IconData icon;
  final List<String> rules;
  final String? overrideLabel;

  const StrictnessLevel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isRecommended,
    required this.icon,
    required this.rules,
    this.overrideLabel
  });
}

class ReligionStrictnessScreen extends StatefulWidget {
  final String religionId;
  final String religionLabel;

  const ReligionStrictnessScreen({
    super.key,
    required this.religionId,
    required this.religionLabel,
  });

  @override
  State<ReligionStrictnessScreen> createState() =>
      _ReligionStrictnessScreenState();
}

class _ReligionStrictnessScreenState extends State<ReligionStrictnessScreen> {
  late final List<StrictnessLevel> _levels;
  String? _selectedLevelId;
  String? _expandedLevelId;

  @override
  void initState() {
    super.initState();

    if (widget.religionId == 'muslim') {
      _levels = [
        StrictnessLevel(
          id: 'basic',
          title: 'Basic guidelines',
          subtitle: 'Avoids pork, alcohol, and blood products.',
          isRecommended: false,
          icon: Symbols.sentiment_satisfied_rounded,
          rules: muslimBasic,
        ),
        StrictnessLevel(
          id: 'standard',
          title: 'Standard',
          subtitle: 'Most commonly followed halal requirements.',
          isRecommended: true,
          icon: Symbols.recommend_rounded,
          rules: muslimStandard,
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Strict (Zabiha only)',
          subtitle: 'Full halal rules with Zabiha requirement.',
          isRecommended: false,
          icon: Symbols.shield_rounded,
          rules: muslimStrict,
        ),
      ];
    }

    else if (widget.religionId == 'hindu') {

      _levels = [
        StrictnessLevel(
          id: 'basic',
          title: 'Basic guidelines',
          subtitle: 'Avoids beef and blood products.',
          isRecommended: true,
          icon: Symbols.sentiment_satisfied_rounded,
          rules: hinduBasic, // <-- using generated array
        ),
        StrictnessLevel(
          id: 'standard',
          title: 'Standard',
          subtitle: 'Hindu vegetarian-style rules.',
          isRecommended: false,
          icon: Symbols.recommend_rounded,
          rules: hinduStandard, // <-- generated array
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Strict (Sattvic)',
          subtitle: 'Strict vegetarian + no onion & garlic (Sattvic).',
          isRecommended: false,
          icon: Symbols.shield_rounded,
          rules: hinduStrict, // <-- generated array
        ),
      ];
    }

    else if (widget.religionId == 'buddhist') {
      _levels = [
        StrictnessLevel(
          id: 'basic',
          title: 'Basic',
          subtitle: 'No restrictions, eat normally with general awareness.',
          isRecommended: true, // ⭐ BASIC = RECOMMENDED
          icon: Symbols.sentiment_satisfied_rounded,
          rules: buddhistBasic,
          overrideLabel: "Awareness notes (not restrictions)",
        ),
        StrictnessLevel(
          id: 'standard',
          title: 'Standard',
          subtitle: 'Avoids meat, seafood, and strong alliums.',
          isRecommended: false,
          icon: Symbols.recommend_rounded,
          rules: buddhistStandard,
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Strict',
          subtitle: 'Fully vegetarian + avoids allium (onion, garlic).',
          isRecommended: false,
          icon: Symbols.shield_rounded,
          rules: buddhistStrict,
        ),
      ];
    }

    else if (widget.religionId == 'sikh') {
      _levels = [
        StrictnessLevel(
          id: 'basic',
          title: 'Basic',
          subtitle: 'Avoids only kutha (ritually slaughtered) meat.',
          isRecommended: true, // ⭐ BASIC is recommended for Sikhs
          icon: Symbols.sentiment_satisfied_rounded,
          rules: sikhBasic,
        ),
        StrictnessLevel(
          id: 'standard',
          title: 'Standard',
          subtitle: 'Mostly vegetarian, avoids meat and seafood.',
          isRecommended: false,
          icon: Symbols.recommend_rounded,
          rules: sikhStandard,
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Strict',
          subtitle: 'Fully vegetarian (Langar style) + no eggs.',
          isRecommended: false,
          icon: Symbols.shield_rounded,
          rules: sikhStrict,
        ),
      ];
    }

    else if (widget.religionId == 'jain') {
      _levels = [
        StrictnessLevel(
          id: 'basic',
          title: 'Basic Jain',
          subtitle: 'No meat, eggs, fish, onion or garlic.',
          isRecommended: false,
          icon: Symbols.sentiment_satisfied_rounded,
          rules: jainBasic,
        ),
        StrictnessLevel(
          id: 'standard',
          title: 'Standard Jain',
          subtitle: 'Traditional Jain diet. No root vegetables or honey.',
          isRecommended: true,
          icon: Symbols.recommend_rounded,
          rules: jainStandard,
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Strict Jain',
          subtitle: 'Avoids fermentation, mushrooms, and microbe-rich foods.',
          isRecommended: false,
          icon: Symbols.shield_rounded,
          rules: jainStrict,
        ),
      ];
    }
    else if (widget.religionId == 'jewish') {
      _levels = [
        StrictnessLevel(
          id: 'basic',
          title: 'Basic Kosher',
          subtitle: 'Avoids pork, shellfish, and non-kosher seafood.',
          isRecommended: false,
          icon: Symbols.sentiment_satisfied_rounded,
          rules: kosherBasic,
        ),
        StrictnessLevel(
          id: 'standard',
          title: 'Standard Kosher',
          subtitle: 'Everyday kosher rules. No meat+dairy and requires kosher certification.',
          isRecommended: true,
          icon: Symbols.recommend_rounded,
          rules: kosherStandard,
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Strict Kosher',
          subtitle: 'Only certified kosher products. Avoids ambiguous additives.',
          isRecommended: false,
          icon: Symbols.shield_rounded,
          rules: kosherStrict,
        ),
      ];
    }

    else if (widget.religionId == 'christian') {
      _levels = [
        StrictnessLevel(
          id: 'basic',
          title: 'Basic Christian',
          subtitle: 'Everyday diet. No religious food restrictions.',
          isRecommended: true,
          icon: Symbols.sentiment_satisfied_rounded,
          rules: christianBasic,
        ),
        StrictnessLevel(
          id: 'standard',
          title: 'Lent Mode',
          subtitle: 'Avoids meat and alcohol during Lent.',
          isRecommended: false,
          icon: Symbols.recommend_rounded,
          rules: christianStandard,
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Orthodox Fasting',
          subtitle: 'Vegan-style fasting. No meat, dairy, eggs, fish, or alcohol.',
          isRecommended: false,
          icon: Symbols.shield_rounded,
          rules: christianStrict,
        ),
      ];
    }



    // 💡 Dummy content for now. Later you can vary by widget.religionId.
   else {
      _levels = [
        StrictnessLevel(
          id: 'basic',
          title: 'Basic guidelines',
          subtitle: 'Light restrictions for everyday eating.',
          isRecommended: false,
          icon: Symbols.sentiment_satisfied_rounded,
          rules:  [
            'Avoids a few core ingredients.',
            'Good for casual everyday use.',
          ],
        ),
        StrictnessLevel(
          id: 'standard',
          title: 'Standard',
          subtitle: 'The most commonly followed rules.',
          isRecommended: true,
          icon: Symbols.recommend_rounded,
          rules:  [
            'Covers typical religious/cultural restrictions.',
            'Flags ingredients that might not fully align.',
            'Balanced between safety and flexibility.',
          ],
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Strict',
          subtitle: 'Full dietary rules with detailed checks.',
          isRecommended: false,
          icon: Symbols.shield_rounded,
          rules:  [
            'Applies all available restrictions.',
            'Flags doubtful or ambiguous ingredients.',
            'Best for users who follow rules very carefully.',
          ],
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

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
        title: Text(
          widget.religionLabel,
          style: const TextStyle(
            fontFamily: 'Inter',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'How closely do you follow these rules?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a level that best matches your daily eating habits. You can always change this later.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView.separated(
                  itemCount: _levels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final level = _levels[index];
                    final isSelected = level.id == _selectedLevelId;
                    final isExpanded = level.id == _expandedLevelId;

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _selectedLevelId = level.id;
                          _expandedLevelId =
                          isExpanded ? null : level.id;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isSelected
                              ? const Color(0xFFEBF8EE)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFE5E5E5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                  isSelected ? 0.10 : 0.04),
                              blurRadius: isSelected ? 12 : 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFF3F5F4),
                                  ),
                                  child: Icon(
                                    level.icon,
                                    size: width < 350 ? 20 : 24,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              level.title,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                          ),
                                          if (level.isRecommended) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                    0xFF4CAF50),
                                                borderRadius:
                                                BorderRadius.circular(999),
                                              ),
                                              child: const Text(
                                                'Recommended',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                  FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        level.subtitle,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF777777),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: const Color(0xFF777777),
                                ),
                              ],
                            ),

                            // Expanded rules
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Padding(
                                padding: const EdgeInsets.only(top: 10, left: 2, right: 2),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                level.overrideLabel ?? "Restricted items:",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF444444),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Chip categories
                                    ..._buildRestrictionChips(level.rules),
                                  ],
                                ),
                              ),

                              crossFadeState: isExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 160),
                            )

                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedLevelId == null
                      ? null
                      : () {
                    // TODO: Save selection and go to next step
                    // e.g. allergies setup or a summary screen.
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    disabledBackgroundColor: const Color(0xFFD5D5D5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continue',
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

  List<Widget> _buildRestrictionChips(List<String> ruleIds) {
    List<Widget> widgets = [];

    for (final ruleId in ruleIds) {
      final rule = restrictionDefinitions[ruleId];
      if (rule == null) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------- TITLE ROW (PATCHED TO AVOID OVERFLOW) ----------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(rule.icon, size: 18, color: const Color(0xFF4CAF50)),
                  const SizedBox(width: 6),

                  // Expanded → WRAPS long text safely on small screens
                  Expanded(
                    child: Text(
                      rule.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // ------------------ CHIPS ----------------------
              // Chips for examples
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // show first 5
                  ...rule.examples.take(5).map((ex) {
                    return Chip(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
                  }),

                  // ADD “+X more” chip if more examples exist
                  if (rule.examples.length > 5)
                    _buildMoreChip(rule),
                ],
              ),

            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildMoreChip(RestrictionDefinition rule) {
    final extraCount = rule.examples.length - 5;

    return InkWell(
      onTap: () => _showAllExamplesSheet(rule),
      child: Chip(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        backgroundColor: const Color(0xFFDFF3E0),
        label: Text(
          "+$extraCount more",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }




  void _showAllExamplesSheet(RestrictionDefinition rule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // <-- IMPORTANT
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85, // <-- bottom sheet uses 85% of screen height
          child: SingleChildScrollView(   // <-- SCROLL FIX
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(rule.icon, color: const Color(0xFF4CAF50)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rule.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                const Text(
                  "These are the typical forms this ingredient appears in.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555555),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: rule.examples.map((ex) {
                    return Chip(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      backgroundColor: const Color(0xFFEFF7F1),
                      label: Text(
                        ex,
                        style: const TextStyle(
                          fontSize: 13,
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




}
