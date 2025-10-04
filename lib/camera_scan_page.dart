import 'dart:async'; // Add this import for Timer
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart'; // Add for consistent fonts
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart'; // New: Tesseract
import 'package:image/image.dart' as imglib; // New: For image conversion
import 'dart:ui' as ui; // For potential transforms

class CameraScanPage extends StatefulWidget {
  @override
  _CameraScanPageState createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> with TickerProviderStateMixin {
  List<CameraDescription> _cameras = [];
  late CameraController _cameraController;
  late int _cameraIndex;
  late TextRecognizer _textRecognizer;
  late LanguageIdentifier _languageIdentifier;
  late OnDeviceTranslatorModelManager _modelManager;
  Map<String, OnDeviceTranslator> _translators = {};

  bool _ingredientsDetected = false;
  String _detectedIngredients = "";
  String _translatedIngredients = "";
  bool _isAnalyzing = false;

  List<TextBlock> _detectedBlocks = [];
  Size? _imageSize;
  InputImageRotation? _rotation;

  // New variables for hint
  bool _showHint = false;
  Timer? _hintTimer;
  Timer? _pulseTimer;
  bool _pulseVisible = true;

  // Animation controllers for enhanced UI
  late AnimationController _fadeController;
  late AnimationController _scanController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scanAnimation;

  // Flags
  bool _cameraReady = false;
  bool _useTesseract = false;
  bool _mlReady = false;
  String? _errorMessage;

  Map<String, List<String>> keywordsByLanguage = {
    "en": ["ingredients", "contains", "nutrition"],
    "fi": ["ainesosat", "sisältää", "ravinto"],
    "sv": ["ingredienser", "innehåller", "näring"]
  };

  final Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _useTesseract = kIsWeb || (!kIsWeb && !(Platform.isAndroid || Platform.isIOS));
    _initializeAnimations();
    if (!_useTesseract) {
      _initializeML();
    } else {
      _mlReady = false; // Not needed for Tesseract
    }
    _initializeCamera();
  }

  void _initializeAnimations() {
    // Fade-in for overlays
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Scan line animation (loops)
    _scanController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );
  }

  void _initializeML() {
    try {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
      _modelManager = OnDeviceTranslatorModelManager();
      Future.microtask(_initializeTranslators);
    } catch (e) {
      debugPrint('ML init error: $e');
      _mlReady = false; // Fall back to online only
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scanController.dispose();
    _hintTimer?.cancel();
    _pulseTimer?.cancel();
    if (_cameraReady) {  // Guard dispose too
      _cameraController.stopImageStream();
      _cameraController.dispose();
    }
    if (!_useTesseract) {
      _textRecognizer.close();
      _languageIdentifier.close();
      _translators.values.forEach((t) => t.close());
    }
    super.dispose();
  }

  Future<void> _initializeTranslators() async {
    if (_useTesseract) return;

    try {
      final langCodes = ['en', 'fi', 'sv'];
      final langMap = {
        'en': TranslateLanguage.english,
        'fi': TranslateLanguage.finnish,
        'sv': TranslateLanguage.swedish,
      };

      // Download models for all relevant languages
      for (var code in langCodes) {
        final lang = langMap[code]!;
        final isDownloaded = await _modelManager.isModelDownloaded(lang.bcpCode);
        if (!isDownloaded) {
          await _modelManager.downloadModel(lang.bcpCode);
        }
      }

      // Create translators
      for (var entry in langMap.entries) {
        final translator = OnDeviceTranslator(
          sourceLanguage: entry.value,
          targetLanguage: TranslateLanguage.english,
        );
        _translators[entry.key] = translator;
      }

      if (mounted) {
        setState(() {
          _mlReady = true;
        });
      }
    } catch (e) {
      debugPrint('Translator init error: $e');
      if (mounted) {
        setState(() {
          _mlReady = false;
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        // Handle no cameras (common on web if permissions denied)
        if (mounted) {
          setState(() {
            _errorMessage = 'No cameras available. Check permissions.';
            _cameraReady = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available. Check permissions.')),
          );
        }
        return;
      }
      _cameraIndex = 0;

      final camera = _cameras[_cameraIndex];

      // Platform-specific image format (safe for web)
      ImageFormatGroup? imageFormatGroup;
      if (!kIsWeb && Platform.isAndroid) {
        imageFormatGroup = ImageFormatGroup.nv21;
      } else if (!kIsWeb && Platform.isIOS) {
        imageFormatGroup = ImageFormatGroup.bgra8888;
      } else {
        imageFormatGroup = ImageFormatGroup.jpeg; // Web/Desktop
      }

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: imageFormatGroup,
      );

      await _cameraController.initialize();
      if (!mounted) return;

      // Start image stream for live OCR (Tesseract ready immediately, ML after init)
      _cameraController.startImageStream(_processCameraImage);

      // Trigger fade-in
      _fadeController.forward();

      // Set flag and update UI
      if (mounted) {
        setState(() {
          _cameraReady = true;
        });
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera error: $e';
          _cameraReady = true; // Allow UI to show error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  bool hasIngredients(String ocrText) {
    String textLower = ocrText.toLowerCase();
    for (var langKeywords in keywordsByLanguage.values) {
      for (var word in langKeywords) {
        if (textLower.contains(word)) return true;
      }
    }
    return false;
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isAnalyzing) return; // prevent overlap
    _isAnalyzing = true;

    try {
      String ocrText = '';
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      if (_useTesseract) {
        // Tesseract for web/desktop: Convert to JPEG base64 and extract text
        String? dataUrl = await _cameraImageToBase64Jpeg(image);
        if (dataUrl == null) {
          _isAnalyzing = false;
          return;
        }
        ocrText = await FlutterTesseractOcr.extractText(
          dataUrl,
          language: 'eng+fin+swe', // Multi-lang support
          args: {
            "psm": "6", // Assume uniform block of text
            "preserve_interword_spaces": "1",
          },
        );
        // No blocks/bounding boxes; treat full text as detected
        _detectedBlocks = []; // Skip AR overlay
        _imageSize = imageSize;
        _rotation = InputImageRotation.rotation0deg; // Default
      } else if (_mlReady) {
        // Mobile: Use ML Kit
        final inputImage = _getInputImageFromCamera(image);
        if (inputImage == null) {
          _isAnalyzing = false;
          return;
        }
        final recognizedText = await _textRecognizer.processImage(inputImage);

        ocrText = recognizedText.text;

        _detectedBlocks = recognizedText.blocks.where((block) {
          final lower = block.text.toLowerCase();
          return keywordsByLanguage.values.any((keywords) =>
              keywords.any((kw) => lower.contains(kw)));
        }).toList();

        _imageSize = imageSize;
        _rotation = inputImage.metadata?.rotation;
      } else {
        // ML not ready on mobile
        _isAnalyzing = false;
        return;
      }

      if (hasIngredients(ocrText)) {
        setState(() {
          _ingredientsDetected = true;
          _detectedIngredients = ocrText;
          _showHint = false; // Hide hint immediately
        });
        _hintTimer?.cancel(); // Cancel hint timer
        _pulseTimer?.cancel(); // Cancel pulse timer
        await _translateIngredients(_detectedIngredients);
      } else {
        setState(() {
          _ingredientsDetected = false;
          _detectedIngredients = "";
          _translatedIngredients = "";
          _detectedBlocks = [];
        });
        // Start hint timer if not already running
        if (_hintTimer == null || !_hintTimer!.isActive) {
          _hintTimer?.cancel();
          _hintTimer = Timer(Duration(seconds: 5), () {
            if (mounted && !_ingredientsDetected) {
              setState(() {
                _showHint = true;
              });
              // Start pulse timer
              _startPulse();
            }
          });
        }
      }
    } catch (e) {
      // handle errors silently for demo
      debugPrint('OCR error: $e');
    }

    // Small delay to throttle for performance (adjust as needed; increase for Tesseract)
    await Future.delayed(Duration(milliseconds: _useTesseract ? 1000 : 500));
    _isAnalyzing = false;
  }

  // Convert CameraImage to base64 JPEG data URL (for Tesseract on web/desktop)
  Future<String?> _cameraImageToBase64Jpeg(CameraImage image) async {
    try {
      Uint8List bytes;
      if (!kIsWeb && Platform.isAndroid) {
        // NV21: Y plane + VU plane (simplified; full YUV->RGB needed for accuracy)
        final yPlane = image.planes[0].bytes;
        final uvPlane = image.planes[1].bytes;
        bytes = Uint8List(yPlane.length + uvPlane.length);
        bytes.setRange(0, yPlane.length, yPlane);
        bytes.setRange(yPlane.length, bytes.length, uvPlane);
        // For NV21, imglib can't directly handle; skip or use simple conversion (placeholder)
        // In production, implement YUV to RGB: https://pub.dev/packages/image_yuv
        debugPrint('NV21 conversion simplified; using raw for demo');
        bytes = yPlane; // Fallback to Y only (grayscale-ish)
      } else {
        // BGRA8888 or JPEG: single plane
        bytes = image.planes[0].bytes;
      }

      // Use imglib to create image (assume BGRA for non-NV21)
      final img = imglib.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: bytes.buffer,
        order: imglib.ChannelOrder.bgra,
      );

      // Encode to JPEG
      final jpegEncoder = imglib.JpegEncoder(quality: 85);
      final jpegBytes = jpegEncoder.encode(img);

      // Base64 encode
      final base64Str = base64Encode(jpegBytes);

      // Return data URL
      return 'data:image/jpeg;base64,$base64Str';
    } catch (e) {
      debugPrint('Image conversion error: $e');
      return null;
    }
  }

  void _startPulse() {
    _pulseTimer?.cancel();
    _pulseVisible = true;
    _pulseTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted && _showHint) {
        setState(() {
          _pulseVisible = !_pulseVisible;
        });
      } else {
        timer.cancel();
      }
    });
  }

  InputImage? _getInputImageFromCamera(CameraImage image) {
    if (_useTesseract) return null; // Handled separately

    // get image rotation (safe for mobile)
    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (!kIsWeb && Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (!kIsWeb && Platform.isAndroid) {
      var rotationCompensation = _orientations[_cameraController.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    if (format == null ||
        (!kIsWeb && Platform.isAndroid && format != InputImageFormat.nv21) ||
        (!kIsWeb && Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    // Removed: if (image.planes.length != 1) return null;  // NV21 has 2 planes, but ML Kit uses first
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  Future<void> _translateIngredients(String text) async {
    bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    // Primary: On-device ML Kit Translation (mobile only if ready)
    if (isMobile && _mlReady) {
      try {
        final identifiedLang = await _languageIdentifier.identifyLanguage(text);
        String sourceCode = 'en';
        if (identifiedLang == 'fi') {
          sourceCode = 'fi';
        } else if (identifiedLang == 'sv') {
          sourceCode = 'sv';
        }
        final translator = _translators[sourceCode];
        if (translator != null) {
          final result = await translator.translateText(text);
          setState(() {
            _translatedIngredients = result;
          });
          return;
        }
      } catch (e) {
        debugPrint('On-device translation error: $e');
      }
    }

    // Secondary: HF Translate API (web only or if ML not working)
    if (kIsWeb || !isMobile || !_mlReady) {
      try {
        final client = http.Client();
        try {
          final response = await client.post(
            Uri.parse('https://indradthor-helsinki-translate.hf.space/api/translate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "text": text,
            }),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            setState(() {
              _translatedIngredients = data['translated_text'] ?? text;
            });
            return;
          }
        } finally {
          client.close();
        }
      } catch (e) {
        debugPrint('HF Translate error: $e');
      }
    }

    // Final fallback
    setState(() {
      _translatedIngredients = text;
    });
  }

  void _analyzeIngredients() async {
    if (_translatedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No ingredients to analyze")),
      );
      return;
    }

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Analyzing ingredients...")),
    );

    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('https://IndraDThor-ingredient-analyzer.hf.space/api/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"text": _translatedIngredients}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Dismiss loading
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show results in bottom sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AnalysisResultsBottomSheet(data: data),
        );
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Analysis failed: $e"),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _analyzeIngredients,
          ),
        ),
      );
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guard with the new flag first
    if (!_cameraReady) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.greenAccent),
              const SizedBox(height: 16),
              Text(
                'Initializing camera...',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    // Show error if any
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  _initializeCamera(); // Retry
                },
                child: Text('Retry', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      );
    }

    // Now safe to access _cameraController.value
    if (!_cameraController.value.isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        body: const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    double buttonSize = 80;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Stack(
          children: [
            // Background Gradient (consistent with landing)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF0A0E21), const Color(0xFF1C1F38)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Subtle Scan-Line Animation Overlay
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: ScanLinePainter(_scanAnimation.value),
                );
              },
            ),
            // Vignette Overlay (darkens edges for focus)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.5, -0.5),
                    radius: 1.5,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),
            // Camera Preview
            Center(
              child: ClipRect(
                child: Transform.scale(
                  scale: 1.0, // Adjust if needed for full coverage
                  child: AspectRatio(
                    aspectRatio: _cameraController.value.aspectRatio,
                    child: CameraPreview(_cameraController),
                  ),
                ),
              ),
            ),
            // AR Overlay for Bounding Boxes (mobile only)
            if (_ingredientsDetected && !_useTesseract)
              Positioned.fill(
                child: CustomPaint(
                  painter: OcrPainter(
                    blocks: _detectedBlocks,
                    imageSize: _imageSize!,
                    rotation: _rotation!,
                    widgetSize: screenSize,
                  ),
                ),
              ),
            // Top Overlay for Translated Ingredients with Fade-In
            if (_ingredientsDetected)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Positioned(
                  top: 80,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            "Ingredients Detected & Translated: ${_useTesseract ? '(Tesseract OCR)' : ''}",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.greenAccent,
                              shadows: [
                                Shadow(
                                  color: Colors.greenAccent.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_translatedIngredients.isNotEmpty)
                          Flexible(
                            child: SingleChildScrollView(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                                ),
                                child: Text(
                                  _translatedIngredients,
                                  style: GoogleFonts.poppins(
                                    color: Colors.amberAccent,
                                    fontSize: 16,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _analyzeIngredients,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: Colors.greenAccent.withOpacity(0.4),
                          ),
                          child: Text(
                            "Analyze Ingredients",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Hint Overlay with Pulse and Enhanced Styling
            if (!_ingredientsDetected && _showHint)
              Positioned(
                bottom: 140, // Above scan button
                left: 20,
                right: 20,
                child: AnimatedOpacity(
                  opacity: _pulseVisible ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 300),
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.95),
                    shadowColor: Colors.orange.withOpacity(0.4),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search,
                            color: Colors.orange[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Scan the ingredients label—right on the package!",
                              style: GoogleFonts.poppins(
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Consistent Scan Button with Animation
            Positioned(
              bottom: 40,
              left: screenSize.width / 2 - buttonSize / 2,
              child: GestureDetector(
                onTapDown: (_) {
                  setState(() {}); // Trigger rebuild for animation
                },
                onTapUp: (_) {
                  setState(() {}); // Scale back
                },
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Live camera is scanning automatically!${_useTesseract ? ' (Using Tesseract OCR)' : ''}"),
                      backgroundColor: Colors.greenAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.greenAccent, Colors.lightGreenAccent],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Scan Line Animation (consistent with landing)
class ScanLinePainter extends CustomPainter {
  final double progress;

  ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final y = size.height * progress;
    path.moveTo(0, y);
    path.lineTo(size.width, y);

    // Add subtle wave for interest
    final wavePaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    final wavePath = Path();
    wavePath.moveTo(0, y - 5);
    wavePath.quadraticBezierTo(size.width / 2, y - 15, size.width, y - 5);
    wavePath.lineTo(size.width, y + 5);
    wavePath.lineTo(0, y + 5);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class OcrPainter extends CustomPainter {
  final List<TextBlock> blocks;
  final Size imageSize;
  final InputImageRotation rotation;
  final Size widgetSize;

  OcrPainter({
    required this.blocks,
    required this.imageSize,
    required this.rotation,
    required this.widgetSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rectPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final block in blocks) {
      final rect = _translateRect(block.boundingBox, rotation, imageSize, widgetSize);
      canvas.drawRect(rect, rectPaint);

      // Draw text inside the box with enhanced style
      textPainter.text = TextSpan(
        text: block.text,
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 14,
          shadows: [Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black)],
        ),
      );
      textPainter.layout(minWidth: rect.width);
      final textOffset = Offset(
        rect.left + (rect.width - textPainter.width) / 2,
        rect.top + (rect.height - textPainter.height) / 2,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  Rect _translateRect(
      Rect rect,
      InputImageRotation rotation,
      Size imageSize,
      Size absoluteImageSize,
      ) {
    double transLeft = 0, transTop = 0, transWidth = 0, transHeight = 0;

    switch (rotation) {
      case InputImageRotation.rotation0deg:
        transLeft = _translateX(rect.left, imageSize, absoluteImageSize);
        transTop = _translateY(rect.top, imageSize, absoluteImageSize);
        transWidth = rect.width * absoluteImageSize.width / imageSize.width;
        transHeight = rect.height * absoluteImageSize.height / imageSize.height;
        break;
      case InputImageRotation.rotation90deg:
        transLeft = _translateX(rect.top, imageSize, absoluteImageSize);
        transTop = _translateY(imageSize.width - rect.left, imageSize, absoluteImageSize);
        transWidth = rect.height * absoluteImageSize.width / imageSize.height;
        transHeight = rect.width * absoluteImageSize.height / imageSize.width;
        break;
      case InputImageRotation.rotation180deg:
        transLeft = _translateX(imageSize.width - rect.right, imageSize, absoluteImageSize);
        transTop = _translateY(imageSize.height - rect.bottom, imageSize, absoluteImageSize);
        transWidth = rect.width * absoluteImageSize.width / imageSize.width;
        transHeight = rect.height * absoluteImageSize.height / imageSize.height;
        break;
      case InputImageRotation.rotation270deg:
        transLeft = _translateX(imageSize.height - rect.bottom, imageSize, absoluteImageSize);
        transTop = _translateY(rect.left, imageSize, absoluteImageSize);
        transWidth = rect.height * absoluteImageSize.width / imageSize.height;
        transHeight = rect.width * absoluteImageSize.height / imageSize.width;
        break;
    }

    return Rect.fromLTWH(transLeft, transTop, transWidth, transHeight);
  }

  double _translateX(double x, Size imageSize, Size absoluteImageSize) {
    return (x * absoluteImageSize.width) / imageSize.width;
  }

  double _translateY(double y, Size imageSize, Size absoluteImageSize) {
    return (y * absoluteImageSize.height) / imageSize.height;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// New widget for displaying results
class AnalysisResultsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> data;

  const AnalysisResultsBottomSheet({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entities = (data['extracted_entities'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final summary = data['summary'] ?? '';
    final benefits = (data['benefits'] as List?)?.cast<String>() ?? [];
    final avoidances = (data['avoidances'] as List?)?.cast<String>() ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,  // Fixed height
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E21),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Analysis Results',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.greenAccent,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(  // Simple scroll, no Draggable needed
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input Text
                  Text(
                    'Input: ${data['input_text'] ?? 'N/A'}',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  // Extracted Entities
                  if (entities.isNotEmpty) ...[
                    Text(
                      'Extracted Entities:',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.amberAccent),
                    ),
                    const SizedBox(height: 8),
                    ...entities.map((entity) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entity['word'] ?? '',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          Text(
                            '${entity['entity_type'] ?? ''} (${(entity['confidence'] * 100).toStringAsFixed(1)}%)',
                            style: GoogleFonts.poppins(color: Colors.greenAccent),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                  // Summary
                  Text(
                    'Summary:',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.amberAccent),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      summary,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Benefits
                  if (benefits.isNotEmpty) ...[
                    Text(
                      'Benefits:',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.greenAccent),
                    ),
                    const SizedBox(height: 8),
                    ...benefits.map((benefit) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              benefit,
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                  // Avoidances
                  if (avoidances.isNotEmpty) ...[
                    Text(
                      'Avoid if:',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 8),
                    ...avoidances.map((avoidance) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              avoidance,
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}