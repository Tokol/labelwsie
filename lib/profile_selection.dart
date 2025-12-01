import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as box;
import 'package:material_symbols_icons/symbols.dart';

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  final Map<String, bool> selected = {
    "religion": false,
    "ethical": false,
    "allergy": false,
    "medical": false,
    "fitness": false,
  };

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // 🔥 Responsive grid rules
    int columns = 2;
    double aspect = 0.9;

    if (width < 350) {
      columns = 1;   // small phones
      aspect = 2.0;  // tall cards
    } else if (width > 600) {
      columns = 3;   // tablets
      aspect = 1.2;
    }


    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Text(
          "LabelWise",
          style: TextStyle(
            fontFamily: "Inter",
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
                "Customize Your Dietary Rules",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Choose the categories that matter to you.\nYour preferences stay on this device. 🔒",
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Color(0xFF666666),
                ),
              ),

              const SizedBox(height: 20),

              // ---- GRID ----
              Expanded(
                child: GridView.builder(
                  itemCount: 5,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,     // auto 1 → 2 → 3 → 4 columns
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.85,      // balanced height
                  ),
                  itemBuilder: (context, index) {
                    return _buildItemFromIndex(index);
                  },
                ),
              ),

              const SizedBox(height: 10),

              // ---- CONTINUE BUTTON ----
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    final hasSelection = selected.containsValue(true);
                    final box = await Hive.openBox("app_data");

                    if (!hasSelection) {
                      // User skipped everything
                     // await box.put("hasSetPreferences", true);

                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        "/home",
                            (route) => false,
                      );
                      return;
                    }

                    else {
                      // User selected categories → go to dynamic wizard
                      Navigator.pushReplacementNamed(
                        context,
                        "/preferencesWizard",
                        arguments: selected,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected.containsValue(true)
                        ? const Color(0xFF4CAF50)   // green
                        : Colors.black87,            // active dark skip button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    selected.containsValue(true)
                        ? "Continue to Home"
                        : "Skip for Now",
                    style: const TextStyle(
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

  // ⭐ Premium, animated, responsive tile
  Widget buildTile({
    required String keyName,
    required String icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = selected[keyName] ?? false;
    final width = MediaQuery.of(context).size.width;
    final double iconSize = width < 350 ? 28 : 32;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.green.withOpacity(0.1),
      highlightColor: Colors.green.withOpacity(0.05),

      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          selected[keyName] = !isSelected;
        });
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
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
              blurRadius: isSelected ? 14 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFF3F5F4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForCategory(keyName),
                  size: width < 350 ? 22 : 26,
                  color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),

              AutoSizeText(
                title,
                maxLines: 2,
                minFontSize: 11,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),

              const SizedBox(height: 6),

              AutoSizeText(
                subtitle,
                maxLines: 2,
                minFontSize: 10,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String key) {
    switch (key) {
      case "religion":
        return Symbols.volunteer_activism_rounded;
      case "ethical":
        return Symbols.eco_rounded;
      case "allergy":
        return Symbols.health_and_safety_rounded;
      case "medical":
        return Symbols.medical_services_rounded;
      case "fitness":
        return Symbols.fitness_center_rounded;
      default:
        return Symbols.info_rounded;
    }
  }

  Widget _buildItemFromIndex(int index) {
    switch (index) {
      case 0:
        return buildTile(
          keyName: "religion",
          icon: "🛐",
          title: "Religious & Cultural Dietary Rules",
          subtitle: "Halal, Kosher, etc.",
        );
      case 1:
        return buildTile(
          keyName: "ethical",
          icon: "🌱",
          title: "Ethical & Personal Choices",
          subtitle: "Vegan, Eco-friendly",
        );
      case 2:
        return buildTile(
          keyName: "allergy",
          icon: "🥜",
          title: "Allergies & Intolerances",
          subtitle: "Nuts, dairy & more",
        );
      case 3:
        return buildTile(
          keyName: "medical",
          icon: "⚕️",
          title: "Medical Dietary Needs",
          subtitle: "Diabetes, thyroid",
        );
      case 4:
        return buildTile(
          keyName: "fitness",
          icon: "🏋️",
          title: "Lifestyle & Fitness Goals",
          subtitle: "Keto, low-carb",
        );
      default:
        return const SizedBox.shrink();
    }
  }


}
