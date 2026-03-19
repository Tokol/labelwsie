import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'process_page.dart';
import 'product_photo_page.dart';
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
  String _statusText = "Align barcode inside the frame";

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

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstWhere(
      (item) => item.rawValue != null && item.rawValue!.trim().isNotEmpty,
      orElse: () => Barcode(rawValue: null, format: BarcodeFormat.unknown),
    );

    final code = barcode.rawValue?.trim();
    if (code == null || code.isEmpty) return;

    setState(() {
      _hasScanned = true;
      _statusText = "Checking product database…";
    });

    await controller.stop();
    if (!mounted) return;

    Map<String, dynamic>? product;
    try {
      product = await OpenFoodFactsService.fetchProduct(code);
    } catch (_) {
      product = null;
    }
    if (!mounted) return;

    if (product == null) {
      final goToPhoto = await _showProductNotFoundSheet(code);
      if (!mounted) return;
      if (goToPhoto) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductPhotoPage(barcode: code),
          ),
        );
      }
    } else {
      final resolvedProduct = Map<String, dynamic>.from(product);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProcessPage(
            barcode: code,
            product: resolvedProduct,
          ),
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _hasScanned = false;
      _statusText = "Align barcode inside the frame";
    });
    await controller.start();
  }

  Future<bool> _showProductNotFoundSheet(String barcode) async {
    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (sheetContext) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Product not found",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF224D35),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "We could not find barcode $barcode in the product database. You can continue by taking a photo of the product and ingredients.",
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Color(0xFF6A7C6F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F7A4B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text("Take Photo Instead"),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: const Text("Scan Again"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          const _TopHeaderOverlay(),
          const _ScannerOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Scan",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Point the camera at a product barcode to start analysis.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFFDDE6E0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        _hasScanned ? _statusText : "Align barcode inside the frame",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 270,
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF8DE0A8),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8DE0A8).withOpacity(0.18),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeaderOverlay extends StatelessWidget {
  const _TopHeaderOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 190,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC0E1612),
                Color(0x8A0E1612),
                Color(0x000E1612),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
