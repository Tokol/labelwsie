import 'package:flutter/material.dart';
import 'package:label_wise/diet_pref/pref_screen/helper/ehical_choices.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:label_wise/diet_pref/restriction_definitions.dart';
import 'package:label_wise/diet_pref/rules/ethical_rules.dart';
// ^ create this file to hold veganRules, vegetarianRules, etc.


class EthicalChoicesScreen extends StatefulWidget {
  const EthicalChoicesScreen({super.key});

  @override
  State<EthicalChoicesScreen> createState() => _EthicalChoicesScreenState();
}

class _EthicalChoicesScreenState extends State<EthicalChoicesScreen> {
  final Set<String> _selectedIds = {};

  late final List<EthicalChoice> _choices = choices.cast<EthicalChoice>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
          "Ethical & Personal Choices",
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
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Select all that apply to you",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "These choices will be combined with your medical or religious rules.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // -------- GRID 2x2 STYLE ----------
              Expanded(
                child: GridView.builder(
                  itemCount: _choices.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 210,     // reduced from 260 → more columns on big screens
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),

                  itemBuilder: (context, index) {
                      final choice = _choices[index];
                      final isSelected = _selectedIds.contains(choice.id);

                      final width = MediaQuery.of(context).size.width;

                      final bool isSmall = width < 360;
                      final double iconSize = isSmall ? 18 : 22;
                      final double titleSize = isSmall ? 14 : 15;
                      final double subtitleSize = isSmall ? 11 : 12;
                      final double padding = isSmall ? 10 : 14;

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            isSelected
                                ? _selectedIds.remove(choice.id)
                                : _selectedIds.add(choice.id);
                          });
                        },
                        onLongPress: () => _showRestrictionsSheet(choice),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
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
                                color: Colors.black.withOpacity(isSelected ? 0.10 : 0.04),
                                blurRadius: isSelected ? 10 : 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),

                          // <- This avoids overflow by letting column size naturally fit
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // -------------------- TOP ICON + CHECK --------------------
                              Row(
                                children: [
                                  Container(
                                    height: isSmall ? 32 : 38,
                                    width: isSmall ? 32 : 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFF3F5F4),
                                    ),
                                    child: Icon(
                                      choice.icon,
                                      size: iconSize,
                                      color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: Color(0xFF4CAF50),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // -------------------- TITLE --------------------
                              Text(
                                choice.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),

                              const SizedBox(height: 4),

                              // -------------------- SUBTITLE --------------------
                              Text(
                                choice.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: subtitleSize,
                                  color: const Color(0xFF777777),
                                  height: 1.3,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // -------------------- VIEW DETAILS --------------------
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "View details",
                                    style: TextStyle(
                                      fontSize: isSmall ? 10 : 11,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: Color(0xFF2E7D32),
                                    ),
                                    onPressed: () => _showRestrictionsSheet(choice),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },

                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedIds.isEmpty ? null : () {
                    // TODO: merge all rules from _selectedIds and proceed
                    // final combinedRules = _computeCombinedRules();
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

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- BOTTOM SHEET: restrictions for one ethical choice -------------
  void _showRestrictionsSheet(EthicalChoice choice) {
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
                        choice.icon,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        choice.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text(
                  choice.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),

                const SizedBox(height: 18),
                const Text(
                  "These are the ingredient categories this choice will flag:",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF444444),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 14),

                ..._buildRestrictionChips(choice.rules),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- same style as religion screen: title + 5 example chips + "+X more" ---
  List<Widget> _buildRestrictionChips(List<String> ruleIds) {
    final List<Widget> widgets = [];

    for (final ruleId in ruleIds) {
      final rule = restrictionDefinitions[ruleId];
      if (rule == null) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(rule.icon, size: 18, color: const Color(0xFF4CAF50)),
                  const SizedBox(width: 6),
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
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...rule.examples.take(5).map((ex) {
                    return Chip(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
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

                  if (rule.examples.length > 5) _buildMoreChip(rule),
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
      isScrollControlled: true, // IMPORTANT
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
