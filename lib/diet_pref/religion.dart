import 'package:flutter/material.dart';
import 'package:label_wise/diet_pref/strickness.dart';
import 'package:material_symbols_icons/symbols.dart';

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

class ReligionCultureSelectionScreen extends StatefulWidget {
  const ReligionCultureSelectionScreen({super.key});

  @override
  State<ReligionCultureSelectionScreen> createState() =>
      _ReligionCultureSelectionScreenState();
}

class _ReligionCultureSelectionScreenState
    extends State<ReligionCultureSelectionScreen> {
  final List<ReligionOption> _options = const [
    ReligionOption(
      id: 'muslim',
      label: 'Muslim',
      subtitle: 'Halal dietary guidelines.',
      icon: Symbols.verified_rounded,
    ),
    ReligionOption(
      id: 'hindu',
      label: 'Hindu',
      subtitle: 'no beef/ Hindu diet preferences.',
      icon: Symbols.spa_rounded,
    ),
    ReligionOption(
      id: 'buddhist',
      label: 'Buddhist',
      subtitle: 'Vegetarian or vegan, depending on tradition.',
      icon: Symbols.self_improvement_rounded,
    ),

    ReligionOption(
      id: 'jewish',
      label: 'Jewish (Kosher)',
      subtitle: 'Kosher dietary rules (Kashrut).',
      icon: Symbols.verified_user_rounded,
    ),
    ReligionOption(
      id: 'sikh',
      label: 'Sikh',
      subtitle: 'Community-based dietary norms.',
      icon: Symbols.group_rounded,
    ),

    ReligionOption(
      id: 'jain',
      label: 'Jain',
      subtitle: 'Strict vegetarian lifestyle.',
      icon: Symbols.compost_rounded,
    ),

    ReligionOption(
      id: 'christian',
      label: 'Christian',
      subtitle: 'Fasting / Lent-based dietary patterns.',
      icon: Symbols.volunteer_activism_rounded,
    ),

  ];

  String? _selectedId;

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
        title: const Text(
          'LabelWise',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
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
                'Religious & Cultural Food Rules',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose the tradition or cultural preference that guides your food choices. You can always skip or change this later.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 20),

              // list of options
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    final isSelected = option.id == _selectedId;

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _selectedId = option.id;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
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
                        child: Row(
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
                                option.icon,
                                size: width < 350 ? 20 : 24,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.label,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    option.subtitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF777777),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Radio<String>(
                              value: option.id,
                              groupValue: _selectedId,
                              onChanged: (value) {
                                setState(() {
                                  _selectedId = value;
                                });
                              },
                              activeColor: const Color(0xFF4CAF50),
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
                  onPressed: _selectedId == null
                      ? null
                      : () {
                    // TODO: hook into your flow.
                    // Example: navigate to strictness screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReligionStrictnessScreen(
                          religionId: _selectedId!,
                          religionLabel: _options
                              .firstWhere(
                                  (o) => o.id == _selectedId)
                              .label,
                        ),
                      ),
                    );
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
}
