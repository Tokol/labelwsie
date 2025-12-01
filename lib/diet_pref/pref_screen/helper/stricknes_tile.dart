import 'package:flutter/material.dart';

import '../../strickness.dart';
import '../../restriction_definitions.dart';

class StrictnessTile extends StatelessWidget {
  final StrictnessLevel level;
  final bool selected;
  final bool expanded;

  const StrictnessTile({
    super.key,
    required this.level,
    required this.selected,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF4CAF50) : Colors.grey;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: selected ? const Color(0xFFEBF8EE) : Colors.white,
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                selected ? const Color(0xFF4CAF50) : const Color(0xFFF3F5F4),
                child: Icon(
                  level.icon,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 12),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey,
              )
            ],
          ),

          // Expanded Rules
          if (expanded) ...[
            const SizedBox(height: 14),
            Text(
              level.overrideLabel ?? "Restricted items:",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: level.rules.map((ruleId) {
                final rule = restrictionDefinitions[ruleId];
                if (rule == null) return const SizedBox.shrink();

                return Chip(
                  backgroundColor: const Color(0xFFEFF7F1),
                  label: Text(
                    rule.title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
