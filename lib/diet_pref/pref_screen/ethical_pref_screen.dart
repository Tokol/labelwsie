import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../restriction_definitions.dart';
import '../rules/ethical_rules.dart';
import 'helper/ehical_choices.dart';



class EthicalChoicesScreen extends StatefulWidget {
  final Function(Set<String>) onChanged;
  final Set<String>? initialSelectedIds;


  const EthicalChoicesScreen({
    super.key,
    required this.onChanged,
    this.initialSelectedIds,
  });

  @override
  State<EthicalChoicesScreen> createState() => _EthicalChoicesScreenState();
}

class _EthicalChoicesScreenState extends State<EthicalChoicesScreen> {
  final Set<String> _selectedIds = {};

   List<EthicalChoice> _choices = choices;


  @override
  void initState() {
    super.initState();

    if (widget.initialSelectedIds != null) {
      _selectedIds.addAll(widget.initialSelectedIds!);
    }

    // notify wizard of initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged(_selectedIds);
    });
  }



  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ethical & Personal Food Choices",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Choose all that apply. These rules will be added to your religion or medical restrictions.",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 20),

          // GRID
          GridView.builder(
            itemCount: _choices.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (_, index) {
              final choice = _choices[index];
              final isSelected = _selectedIds.contains(choice.id);

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    isSelected
                        ? _selectedIds.remove(choice.id)
                        : _selectedIds.add(choice.id);
                  });
                  widget.onChanged(_selectedIds);
                },
                onLongPress: () => _showRestrictionsSheet(choice),
                child: _buildTile(choice, isSelected),
              );
            },
          ),
        ],
      ),
    );
  }

  // ----------
  Widget _buildTile(EthicalChoice choice, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
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
          // TOP
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFF3F5F4),
                ),
                child: Icon(
                  choice.icon,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            choice.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),

          Text(
            choice.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF777777),
            ),
          ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "View details",
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showRestrictionsSheet(choice),
                icon: const Icon(Icons.info_outline, size: 18, color: Color(0xFF2E7D32)),
              ),
            ],
          )
        ],
      ),
    );
  }

  // -------------- BOTTOM SHEETS ---------------
  void _showRestrictionsSheet(EthicalChoice choice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _bottomSheetBody(choice),
      ),
    );
  }

  Widget _bottomSheetBody(EthicalChoice choice) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(choice.icon, color: const Color(0xFF4CAF50)),
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

          const SizedBox(height: 12),
          Text(
            choice.subtitle,
            style: const TextStyle(fontSize: 14, color: Color(0xFF777777)),
          ),

          const SizedBox(height: 20),
          const Text(
            "Typical ingredient forms:",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _restrictionChips(choice.rules),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<Widget> _restrictionChips(List<String> ruleIds) {
    final List<Widget> widgets = [];

    for (var id in ruleIds) {
      final rule = restrictionDefinitions[id];
      if (rule == null) continue;

      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(rule.icon, size: 18, color: const Color(0xFF4CAF50)),
                const SizedBox(width: 6),
                Text(
                  rule.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: rule.examples.map((ex) {
                return Chip(
                  backgroundColor: const Color(0xFFEFF7F1),
                  label: Text(
                    ex,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    return widgets;
  }
}
