import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:label_wise/dasboard/result_page.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:label_wise/result_screen.dart';

import '../ai/services.dart';
import '../utlis/open_food_service.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    autoStart: true,
    detectionSpeed: DetectionSpeed.unrestricted,
  );

  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      controller.stop();
      controller.start();

    }
  }


  // -------------------------------------------------------------------------
  // BARCODE DETECTION
  // -------------------------------------------------------------------------
  void _onDetect(BarcodeCapture capture) async {
    print("detected");
   // if (_hasScanned) return;

    final b = capture.barcodes.firstWhere(
          (barcode) => barcode.rawValue != null && barcode.rawValue!.trim().isNotEmpty,
      orElse: () => Barcode(rawValue: null, format: BarcodeFormat.unknown),
    );

    final code = b.rawValue?.trim();
    if (code == null) return;
    print("SCANNED BARCODE: $code");

    setState(() => _hasScanned = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    final data = await OpenFoodFactsService.fetchProduct(code);

// ALWAYS close loader
    if (mounted) Navigator.pop(context);

    if (data == null) {
      _showProductNotInDatabaseSheet(code);
      return;
    }

    print("=== PRODUCT JSON FOUND ===");
    print(jsonEncode(data));

    final ingredients = await extractIngredients(data);

    if (ingredients == null || ingredients.isEmpty) {
      _showMissingIngredientsDialog();
      return;
    }

    data["ingredients_final"] = ingredients;

// Allow scanning again AFTER returning from result page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultPage(product: data)),
    ).then((_) {
      setState(() => _hasScanned = false);
    });



  }

  Future<List<String>?> extractIngredients(Map p) async {
    // 1. English direct from OFF (string)
    final eng = p["ingredients_text_en"]?.toString().trim();
    if (eng != null && eng.isNotEmpty) {
      final list = eng.split(",").map((e) => e.trim()).toList();
      p["ingredients_final"] = list;
      return list;
    }

    // 2. Raw ingredients text
    String? raw = p["ingredients_text"]?.toString().trim();

    // 3. OFF ingredients array
    if ((raw == null || raw.isEmpty) && p["ingredients"] != null) {
      final list = p["ingredients"] as List;
      raw = list.map((e) => e["text"]).whereType<String>().join(", ");
    }

    if (raw == null || raw.isEmpty) return null;

    raw = normalizeIngredients(raw);

    // 4. Translate → returns List<String>
    final translatedList = await translateToEnglish(raw);

    p["ingredients_english"] = translatedList;
    p["ingredients_final"] = translatedList;

    return translatedList;
  }


  String normalizeIngredients(String raw) {
    var text = raw.toLowerCase();

    // Remove common OFF noise
    text = text.replaceAll(RegExp(r"lot.*"), "");
    text = text.replaceAll(RegExp(r"see.*packaging"), "");
    text = text.replaceAll(RegExp(r"\bpreferably consumed before\b"), "");

    // Remove double punctuation
    text = text.replaceAll(RegExp(r"[\/;]"), ", ");
    text = text.replaceAll(RegExp(r",\s*,+"), ", ");
    text = text.replaceAll(RegExp(r"\s+"), " ");

    return text.trim();
  }



  Future<List<String>> translateToEnglish(String text) async {
    final prompt = """
Translate the following ingredient list into English.
Return ONLY a JSON array of ingredients. 
No comments. No explanations.

Example:
["wheat flour", "water", "salt"]

$text
""";


    final result = await OpenAIService.instance.callModel(prompt);

    try {
      final decoded = jsonDecode(result);
      return (decoded as List).map((e) => e.toString().trim()).toList();
    } catch (e) {
      print("JSON parse failed. Returning fallback text list.");
      return text.split(",").map((e) => e.trim()).toList();
    }
  }





  void _showMissingIngredientsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,  // ← FORCE WHITE
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Ingredients Not Available",
          style: TextStyle(
            color: Colors.black,        // ← Title color
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "This product does not have ingredient information saved in OpenFoodFacts.\n\n"
              "Would you like to take a photo of the ingredients?",
          style: TextStyle(
            color: Colors.black87,      // ← Content color
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: Color(0xFF00A86B),  // your green theme
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {

              Navigator.pop(context);
              setState(() => _hasScanned = false);

              // Navigate to ingredient camera
            },
            child: const Text(
              "Take Photo",
              style: TextStyle(
                color: Color(0xFF00A86B),  // your green theme
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }




  void _showProductNotInDatabaseSheet(String code) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _sheet(
        title: "Product Not Found",
        message: "We couldn’t locate this barcode online.\nYou can capture ingredients manually.",
        primary: "Take Photo of Ingredients",
        onPrimary: () {
          Navigator.pop(context);
          // TODO: Navigate to ingredient capture
          _showNotFoundSheet(code);
        },
        secondary: "Scan Again",
        onSecondary: () {
          Navigator.pop(context);
          setState(() => _hasScanned = false);
          controller.start();
        },
      ),
    );
  }
  Widget _sheet({
    required String title,
    required String message,
    required String primary,
    required VoidCallback onPrimary,
    String? secondary,
    VoidCallback? onSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onPrimary,
            child: Text(primary),
          ),
          if (secondary != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onSecondary, child: Text(secondary)),
          ]
        ],
      ),
    );
  }


  // -------------------------------------------------------------------------
  // PRODUCT NOT FOUND SHEET
  // -------------------------------------------------------------------------
  void _showNotFoundSheet(String code) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "No barcode?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: navigate to ingredient capture page
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Take Photo of Ingredients"),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _hasScanned = false);
                controller.start();
              },
              child: const Text("Try scanning again"),
            )
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // UI BUILD (FULLY DYNAMIC)
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Behind everything: Camera
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          // Overlay UI
          Column(
            children: [
              const SizedBox(height: 60),

              // TITLE
              const Text(
                "Scan barcode",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 40),

              // CENTERED FRAME
              Expanded(
                child: Center(
                  child: const _LargeScanFrame(),
                ),
              ),

              const SizedBox(height: 30),

              // BOTTOM BUTTON + TEXT
              Column(
                children: [
                  const Text(
                    "No barcode detected?",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: const Text("Take Photo of Ingredients"),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// RESPONSIVE SCAN FRAME (DYNAMIC HEIGHT + WIDTH)
// -----------------------------------------------------------------------------
class _LargeScanFrame extends StatelessWidget {
  const _LargeScanFrame();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final frameWidth = size.width * 0.90;
    final frameHeight = size.height * 0.35; // Dynamic and balanced

    return Container(
      width: frameWidth,
      height: frameHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 3),
      ),
    );
  }
}
