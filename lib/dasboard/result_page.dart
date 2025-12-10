import 'package:flutter/material.dart';

class ResultPage extends StatefulWidget {
  final Map<String, dynamic> product;


  const ResultPage({super.key, required this.product});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  String? imageUrl;
  late final List<String> ingredients;


  @override
  void initState() {
    super.initState();
    imageUrl = getBestImage(widget.product);
    ingredients = (widget.product["ingredients_final"] as List?)?.cast<String>() ?? [];

  }

  // ----------------------------------------------------------------------
  // BEST IMAGE EXTRACTOR
  // ----------------------------------------------------------------------
  String? getBestImage(Map<String, dynamic> product) {
    try {
      // 1️⃣ Modern OFF structure
      final selectedImages = product["selected_images"];
      if (selectedImages != null &&
          selectedImages["front"] != null &&
          selectedImages["front"]["display"] != null) {
        final displayMap = selectedImages["front"]["display"];
        if (displayMap is Map && displayMap.isNotEmpty) {
          return displayMap.values.first;
        }
      }

      // 2️⃣ Older field
      if (product["image_front_url"] != null &&
          product["image_front_url"].toString().isNotEmpty) {
        return product["image_front_url"];
      }

      // 3️⃣ Generic
      if (product["image_url"] != null &&
          product["image_url"].toString().isNotEmpty) {
        return product["image_url"];
      }

      // 4️⃣ Small fallback
      if (product["image_small_url"] != null &&
          product["image_small_url"].toString().isNotEmpty) {
        return product["image_small_url"];
      }
    } catch (_) {}

    return null;
  }

  // ----------------------------------------------------------------------
  // UI BUILD
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Product Result"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ----------------------------------------------------------
            // SECTION 1 — PRODUCT HEADER
            // ----------------------------------------------------------
            Center(
              child: Column(
                children: [
                  Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: imageUrl == null
                        ? const Icon(Icons.image, size: 80, color: Colors.grey)
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // TODO: Dynamic Product Name
                  Text(
                    widget.product["product_name"] ?? "Unknown Product",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),


                  const SizedBox(height: 4),

                  Text(
                    buildSubtitle(widget.product),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),


                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMiniTag("NutriScore B", Colors.green.shade600),
                      const SizedBox(width: 8),
                      _buildMiniTag("NOVA 4", Colors.orange.shade600),
                      const SizedBox(width: 8),
                      _buildMiniTag("EcoScore A", Colors.blue.shade600),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ----------------------------------------------------------
            // SECTION 2 — OVERALL FIT SCORE
            // ----------------------------------------------------------
            _sectionTitle("Overall Fit Score"),

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "⭐ 82% (Good)",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Based on your personal rules and health goals.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip("High Fiber", Colors.green.shade600),
                      _chip("Halal Safe", Colors.green.shade600),
                      _chip("Moderate Salt", Colors.orange.shade600),
                      _chip("Additives Uncertain", Colors.orange.shade600),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ----------------------------------------------------------
            // SECTION 3 — RULE EVALUATION
            // ----------------------------------------------------------
            _sectionTitle("Rule Evaluation"),
            _infoCard("Religion & Cultural Fit",
                "✓ Halal-safe\n⚠ E471 source uncertain"),
            _infoCard("Allergens", "✖ Contains gluten\n✓ No nuts"),
            _infoCard("Medical Fit", "⚠ Medium salt\n✓ Suitable for diabetes"),
            _infoCard("Fitness Goals", "✖ Not low-carb\n✓ High in fiber"),
            _infoCard("Ethical & Personal",
                "⚠ May contain palm oil\n✓ Vegetarian-friendly"),

            const SizedBox(height: 24),

            // ----------------------------------------------------------
            // SECTION 4 — INGREDIENTS OVERVIEW
            // ----------------------------------------------------------
            _sectionTitle("Ingredients Overview"),

            _card(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip("Whole Grain", Colors.green.shade700),
                  _chip("Added Sugar", Colors.orange.shade700),
                  _chip("Emulsifier", Colors.orange.shade700),
                  _chip("Thickener", Colors.orange.shade700),
                  _chip("Salt", Colors.orange.shade700),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ----------------------------------------------------------
            // SECTION 5 — NUTRITION HIGHLIGHTS
            // ----------------------------------------------------------
            _sectionTitle("Nutrition Highlights"),

            _card(
              child: Column(
                children: [
                  _nutriRow("Fiber", "High", Colors.green),
                  _nutriRow("Sugar", "Moderate", Colors.orange),
                  _nutriRow("Salt", "Medium", Colors.orange),
                  _nutriRow("Protein", "Good", Colors.green),
                  _nutriRow("Calories", "Moderate", Colors.blue),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ----------------------------------------------------------
            // SECTION 6 — ADDITIVES INFO
            // ----------------------------------------------------------
            _sectionTitle("Additives"),

            _infoCard("E471 — Emulsifier", "Origin uncertain"),
            _infoCard("E472e — Emulsifier", "Origin uncertain"),
            _infoCard("E415 — Thickener", "Safe"),

            const SizedBox(height: 24),

            // ----------------------------------------------------------
            // SECTION 7 — ENVIRONMENTAL IMPACT
            // ----------------------------------------------------------
            _sectionTitle("Environmental Impact"),

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _envRow("Eco Score", "B (Good)"),
                  _envRow("Carbon Footprint", "0.67 kg CO₂e"),
                  _envRow("Ingredient Origins", "Unknown"),
                  _envRow("Packaging", "Data missing"),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ----------------------------------------------------------
            // SECTION 8 — ALTERNATIVES
            // ----------------------------------------------------------
            _sectionTitle("Healthier Alternatives"),
            _infoCard("Oululainen 100% Ruis", "No emulsifiers, higher fiber"),
            _infoCard("Fazer Real Ruis", "Cleaner ingredients"),
            _infoCard("Gluten-Free Rye Style Bread", "Allergen replacement"),

            const SizedBox(height: 24),

            // ----------------------------------------------------------
            // SECTION 9 — HOW TO ENJOY
            // ----------------------------------------------------------
            _sectionTitle("How to Enjoy"),

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("• Toast lightly with avocado & lemon."),
                  SizedBox(height: 6),
                  Text("• Pair with hummus for a balanced vegan meal."),
                  SizedBox(height: 6),
                  Text("• Avoid salty cheese spreads if reducing sodium."),
                ],
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // REUSABLE WIDGETS
  // ----------------------------------------------------------------------

  static Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  static Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, spreadRadius: 1),
        ],
      ),
      child: child,
    );
  }

  static Widget _chip(String label, Color color) {
    return Chip(
      label: Text(label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  static Widget _infoCard(String title, String description) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description),
        ],
      ),
    );
  }

  static Widget _nutriRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  static Widget _envRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  static Widget _buildMiniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
      BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  // for subtitle
  String buildSubtitle(Map<String, dynamic> p) {
    final category = getCategory(p) ?? "Food Product";
    final countries = p["countries"]?.toString();

    String country = "Unknown";
    if (countries != null && countries.isNotEmpty) {
      country = countries.split(",").first.trim();
    }

    return "$category • $country";
  }
  String? getCategory(Map<String, dynamic> p) {
    final cats = p["categories"]?.toString();
    if (cats == null || cats.isEmpty) return null;

    final parts = cats.split(",");
    return parts.isNotEmpty ? parts.last.trim() : null;
  }




}
