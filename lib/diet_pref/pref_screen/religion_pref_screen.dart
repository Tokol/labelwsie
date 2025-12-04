import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'helper/religion_tile.dart';
import '../religion.dart';

class ReligionSelectionPage extends StatefulWidget {
  final Function(String) onSelected;
  final Function(bool) onStateChanged;
  final String? initialSelectedReligion;


  const ReligionSelectionPage({
    super.key,
    required this.onSelected,
    required this.onStateChanged,
    this.initialSelectedReligion,
  });

  @override
  State<ReligionSelectionPage> createState() => _ReligionSelectionPageState();
}

class _ReligionSelectionPageState extends State<ReligionSelectionPage> {
  String? _selected;

  @override
  void initState() {
    super.initState();

    // Pre-select religion if editing
    _selected = widget.initialSelectedReligion;

    if (_selected != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSelected(_selected!);
        widget.onStateChanged(true);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Religious & Cultural Food Rules",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            "Choose your tradition.",
            style: TextStyle(color: Color(0xFF777777)),
          ),
          const SizedBox(height: 20),

          ...religionOptions.map((opt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ReligionTile(
                label: opt.label,
                subtitle: opt.subtitle,
                icon: opt.icon,
                selected: _selected == opt.id,
                onTap: () {
                  setState(() => _selected = opt.id);
                  widget.onSelected(opt.id);
                  widget.onStateChanged(true);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}



class ReligionOption {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;

  const ReligionOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

const List<ReligionOption> religionOptions = [
  ReligionOption(
    id: 'muslim',
    label: 'Muslim',
    subtitle: 'Halal dietary rules.',
    icon: Symbols.verified_rounded,
  ),
  ReligionOption(
    id: 'hindu',
    label: 'Hindu',
    subtitle: 'No beef; vegetarian for many.',
    icon: Symbols.spa_rounded,
  ),
  ReligionOption(
    id: 'buddhist',
    label: 'Buddhist',
    subtitle: 'Vegetarian/vegan variations.',
    icon: Symbols.self_improvement_rounded,
  ),
  ReligionOption(
    id: 'jewish',
    label: 'Jewish (Kosher)',
    subtitle: 'Kosher dietary law.',
    icon: Symbols.verified_user_rounded,
  ),
  // ReligionOption(
  //   id: 'sikh',
  //   label: 'Sikh',
  //   subtitle: 'Community dietary norms.',
  //   icon: Symbols.group_rounded,
  // ),
  ReligionOption(
    id: 'jain',
    label: 'Jain',
    subtitle: 'Strict vegetarian lifestyle.',
    icon: Symbols.compost_rounded,
  ),
  ReligionOption(
    id: 'christian',
    label: 'Christian',
    subtitle: 'Lent-based seasonal patterns.',
    icon: Symbols.volunteer_activism_rounded,
  ),
];

