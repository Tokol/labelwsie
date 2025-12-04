import 'package:flutter/material.dart';

import '../strickness.dart';
import 'helper/stricknes_tile.dart';
import 'helper/strictness_loader.dart';

class ReligionStrictnessPage extends StatefulWidget {
  final String Function() getReligion;
  final Function(String) onSelected;
  final Function(bool) onStateChanged;
  final String? initialStrictness;


  const ReligionStrictnessPage({
    super.key,
    required this.getReligion,
    required this.onSelected,
    required this.onStateChanged,
    this.initialStrictness,
  });

  @override
  State<ReligionStrictnessPage> createState() =>
      _ReligionStrictnessPageState();
}

class _ReligionStrictnessPageState extends State<ReligionStrictnessPage> {
  late List<StrictnessLevel> _levels;
  String? _selected;
  String? _expanded;

  @override
  void initState() {
    super.initState();

    // Disable next button at start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStateChanged(false);
    });

    // Load strictness list dynamically
    _levels = loadStrictness(widget.getReligion());

    _selected = widget.initialStrictness;
    _expanded = widget.initialStrictness;

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
            "How closely do you follow these rules?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            "Choose a level that matches your daily habits.",
            style: TextStyle(color: Color(0xFF777777)),
          ),

          const SizedBox(height: 20),

          // Strictness Tiles
          ..._levels.map((lvl) {
            bool sel = _selected == lvl.id;
            bool exp = _expanded == lvl.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  // First tap selects
                  if (_selected != lvl.id) {
                    setState(() {
                      _selected = lvl.id;
                      _expanded = lvl.id; // auto expand on first pick
                    });
                    widget.onSelected(lvl.id);
                    widget.onStateChanged(true);
                    return;
                  }

                  // Second tap expands/collapses
                  setState(() {
                    _expanded = exp ? null : lvl.id;
                  });
                },
                child: StrictnessTile(
                  level: lvl,
                  selected: sel,
                  expanded: exp,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
