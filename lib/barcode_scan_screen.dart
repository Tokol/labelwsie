// barcode_scanner_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:label_wise/result_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  final void Function(String barcode)? onBarcodeDetected;

  const BarcodeScannerPage({super.key, this.onBarcodeDetected});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    formats: [
      BarcodeFormat.ean8,
      BarcodeFormat.ean13,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.code128,
      BarcodeFormat.itf,
      BarcodeFormat.codabar,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: true,
  );

  bool _hasScanned = false;
  String? scannedBarcode; // ← To show on screen

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
    if (!controller.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.resumed:
        controller.start();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        controller.stop();
        break;
      default:
        break;
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstWhere(
          (b) => b.rawValue != null && b.rawValue!.trim().isNotEmpty,
      orElse: () => Barcode(rawValue: null, format: BarcodeFormat.unknown),
    );

    final String? code = barcode.rawValue?.trim();
    if (code == null || code.isEmpty) return;

    print('SCANNED BARCODE: $code');

    setState(() {
      _hasScanned = true;
      scannedBarcode = code;
    });

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    // --- REQUEST OPENFOODFACTS ---
    final url =
        "https://world.openfoodfacts.org/api/v0/product/$code.json";

    Map<String, dynamic>? productData;

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json["status"] == 1) {
          productData = json["product"];
        }
      }
    } catch (e) {
      print("Error fetching OFF data: $e");
    }

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    // --- CASE A: PRODUCT FOUND ---
    if (productData != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(product: productData),
        ),
      );
      return;
    }

    // --- CASE B: PRODUCT NOT FOUND ---
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                "Product Not Found",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "We couldn’t find data for this barcode.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Capture ingredients photo
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Capture Ingredients"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // go to ingredient capture page
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => IngredientCaptureScreen(barcode: code),
                  //   ),
                  // );
                },
              ),
              const SizedBox(height: 12),

              // Scan again
              TextButton(
                child: const Text("Scan Again"),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _hasScanned = false;
                    scannedBarcode = null;
                  });
                  controller.start();
                },
              ),
            ],
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Scan Barcode'),
        actions: [
          // Torch button
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, child) {
              final bool torchOn = state.torchState == TorchState.on;
              return IconButton(
                color: torchOn ? Colors.yellow : Colors.white,
                icon: Icon(torchOn ? Icons.flash_on : Icons.flash_off),
                onPressed: () => controller.toggleTorch(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          const _BarcodeOverlay(),

          // Hint text
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 80),
              child: _HintText(),
            ),
          ),

          // Show scanned barcode on screen
          if (scannedBarcode != null)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 140),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: SelectableText(
                  scannedBarcode!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Rescan button (only if you want manual control)
          if (_hasScanned)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasScanned = false;
                      scannedBarcode = null;
                    });
                    controller.start();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────── UI Widgets (unchanged) ─────────────────────

class _HintText extends StatelessWidget {
  const _HintText();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
      child: const Text('Point camera at a barcode', style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}

class _BarcodeOverlay extends StatelessWidget {
  const _BarcodeOverlay();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.black.withOpacity(0.5)),
        Center(
          child: Container(width: 300, height: 160, decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(16))),
        ),
        ..._cornerBrackets(context),
        const _ScanningLine(),
      ],
    );
  }

  List<Widget> _cornerBrackets(BuildContext context) {
    const double s = 32;
    final double top = (MediaQuery.of(context).size.height - 160) / 2 - s / 2;
    final double left = (MediaQuery.of(context).size.width - 300) / 2;
    final c = Colors.redAccent;
    return [
      Positioned(top: top, left: left, child: _bracket(c, true, true)),
      Positioned(top: top, right: left, child: _bracket(c, false, true)),
      Positioned(bottom: top, left: left, child: _bracket(c, true, false)),
      Positioned(bottom: top, right: left, child: _bracket(c, false, false)),
    ];
  }

  Widget _bracket(Color c, bool left, bool top) => SizedBox(width: 32, height: 32, child: CustomPaint(painter: _CornerPainter(color: c, left: left, top: top)));
}

class _CornerPainter extends CustomPainter {
  final Color color; final bool left; final bool top;
  _CornerPainter({required this.color, required this.left, required this.top});
  @override void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 5..strokeCap = StrokeCap.round;
    final len = 20.0;
    if (left) canvas.drawLine(const Offset(0, 0), Offset(len, 0), p);
    if (!left) canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), p);
    if (top) canvas.drawLine(const Offset(0, 0), Offset(0, len), p);
    if (!top) canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), p);
  }
  @override bool shouldRepaint(_) => false;
}

class _ScanningLine extends StatefulWidget {
  const _ScanningLine();
  @override State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final offset = -180 + _ctrl.value * 360;
        return Align(
          alignment: const Alignment(0, -0.5),
          child: Transform.translate(
            offset: Offset(0, offset),
            child: Container(width: 300, height: 2, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.redAccent.withOpacity(0.9), Colors.transparent]))),
          ),
        );
      },
    );
  }
}