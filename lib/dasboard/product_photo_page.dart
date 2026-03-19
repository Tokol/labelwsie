import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

import '../state/pref_store.dart';
import 'result_page.dart';
import 'services/food_analysis_processor.dart';
import 'services/market_country_service.dart';
import 'services/photo_extraction_service.dart';
import 'services/photo_validation_service.dart';
import 'widgets/photo_capture_intro_card.dart';
import 'widgets/photo_capture_viewport.dart';

class ProductPhotoPage extends StatefulWidget {
  final String barcode;

  const ProductPhotoPage({
    super.key,
    required this.barcode,
  });

  @override
  State<ProductPhotoPage> createState() => _ProductPhotoPageState();
}

class _ProductPhotoPageState extends State<ProductPhotoPage> {
  CameraController? _controller;
  CameraDescription? _selectedCamera;
  Future<void>? _cameraFuture;
  Uint8List? _capturedBytes;
  String? _capturedPath;
  bool _analyzing = false;
  String? _error;
  PhotoValidationResult? _validationResult;

  @override
  void initState() {
    super.initState();
    _cameraFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = "No camera is available on this device.";
        });
        return;
      }

      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _selectedCamera = camera;
        _controller = controller;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Camera could not be opened.\n$e";
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _resetCameraPreview() async {
    final oldController = _controller;
    _controller = null;
    _cameraFuture = null;
    if (mounted) {
      setState(() {});
    }
    await oldController?.dispose();
    if (!mounted) return;
    _cameraFuture = _initializeCamera();
    setState(() {});
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      final file = await controller.takePicture();
      var bytes = await file.readAsBytes();
      bytes = _normalizeCapturedBytes(bytes);
      if (!mounted) return;
      setState(() {
        _capturedBytes = bytes;
        _capturedPath = file.path;
        _validationResult = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Photo capture failed.\n$e";
      });
    }
  }

  Uint8List _normalizeCapturedBytes(Uint8List bytes) {
    final selectedCamera = _selectedCamera;
    final shouldFlip =
        kIsWeb && selectedCamera?.lensDirection == CameraLensDirection.front;

    if (!shouldFlip) {
      return bytes;
    }

    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      final flipped = img.flipHorizontal(decoded);
      final encoded = img.encodeJpg(flipped, quality: 92);
      return Uint8List.fromList(encoded);
    } catch (_) {
      return bytes;
    }
  }

  Future<void> _analyzePhoto() async {
    final bytes = _capturedBytes;
    if (bytes == null || _analyzing) return;

    setState(() {
      _analyzing = true;
      _validationResult = null;
      _error = null;
    });

    try {
      final dataUrl = PhotoValidationService.toDataUrl(bytes);
      final result = await PhotoValidationService.validateImage(
        imageDataUrl: dataUrl,
      );

      if (!mounted) return;
      setState(() {
        _validationResult = result;
        _analyzing = false;
      });

      await _showValidationSheet(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _analyzing = false;
        _error = "Photo validation failed.\n$e";
      });
    }
  }

  Future<void> _showValidationSheet(PhotoValidationResult result) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final canProceed = result.canProceed;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canProceed ? "Photo validated" : "Retake photo",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF224D35),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  result.reason,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF6A7C6F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildMetaChip("Type", result.imageType),
                    _buildMetaChip("Confidence", "${result.confidence}%"),
                    _buildMetaChip(
                      "Decision",
                      canProceed ? "Proceed" : "Retake",
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      if (canProceed) {
                        await _extractAndContinue();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F7A4B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      canProceed
                          ? "Continue"
                          : "Retake Photo",
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _extractAndContinue() async {
    final bytes = _capturedBytes;
    if (bytes == null || _analyzing) return;

    setState(() {
      _analyzing = true;
      _error = null;
    });

    try {
      final store = context.read<PreferenceStore>();
      if (store.isLoading) {
        await store.loadPrefs();
      }

      final dataUrl = PhotoValidationService.toDataUrl(bytes);
      final extracted = await PhotoExtractionService.extract(
        imageDataUrl: dataUrl,
        barcode: widget.barcode,
        localImagePath: _capturedPath,
      );

      if (!mounted) return;
      if (extracted == null || extracted.ingredients.isEmpty) {
        setState(() {
          _analyzing = false;
          _error =
              "We could not extract enough food details from this photo. Please retake a clearer ingredient/package image.";
        });
        return;
      }

      final analysis = await FoodAnalysisProcessor.process(
        input: FoodAnalysisInput(
          product: extracted.product,
          ingredients: extracted.ingredients,
          additives: extracted.additives,
          productAllergens: extracted.productAllergens,
          nutriments: extracted.nutriments,
          nutrientLevels: extracted.nutrientLevels,
          nutriScore: extracted.nutriScore,
          novaGroup: extracted.novaGroup,
        ),
        prefs: store.prefs,
      );

      final marketCountry = await MarketCountryService.resolve(
        product: extracted.product,
      );

      if (!mounted) return;
      setState(() {
        _analyzing = false;
      });

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            product: extracted.product,
            ingredients: extracted.ingredients,
            additives: extracted.additives,
            allergens: extracted.productAllergens,
            nutriments: extracted.nutriments,
            nutrientLevels: extracted.nutrientLevels,
            nutriScore: extracted.nutriScore,
            novaGroup: extracted.novaGroup,
            ranEvaluations: analysis.ranEvaluations,
            evaluationResults: analysis.evaluationResults,
            userMarketCountry: marketCountry.country,
            userMarketCountrySource: marketCountry.source,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _analyzing = false;
        _error = "Photo extraction failed.\n$e";
      });
    }
  }

  Widget _buildMetaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE7DD)),
      ),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF31523F),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewBytes = _capturedBytes;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D5E3A),
        elevation: 0,
        title: const Text("Take Product Photos"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhotoCaptureIntroCard(barcode: widget.barcode),
            const SizedBox(height: 18),
            Expanded(
              child: PhotoCaptureViewport(
                previewBytes: previewBytes,
                analyzing: _analyzing,
                error: _error,
                cameraFuture: _cameraFuture,
                controller: _controller,
              ),
            ),
            const SizedBox(height: 16),
            if (_validationResult != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _validationResult!.reason,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: _validationResult!.canProceed
                        ? const Color(0xFF2F7A4B)
                        : const Color(0xFF8A5A46),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Row(
              children: [
                if (previewBytes != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _analyzing
                          ? null
                          : () async {
                              setState(() {
                                _capturedBytes = null;
                                _capturedPath = null;
                                _validationResult = null;
                                _error = null;
                              });
                              await _resetCameraPreview();
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFBED0C1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text("Retake"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _analyzing ? null : _analyzePhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F7A4B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(_analyzing ? "Analyzing…" : "Analyze"),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _takePhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F7A4B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text("Capture Photo"),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
