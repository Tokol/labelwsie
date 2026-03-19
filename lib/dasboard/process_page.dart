import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/pref_store.dart';
import 'product_photo_page.dart';
import 'result_page.dart';
import 'services/food_analysis_processor.dart';
import 'services/market_country_service.dart';
import 'services/open_food_product_extractor.dart';
import 'widgets/process_loading_view.dart';
import 'widgets/processing_fallback_sheet.dart';
import '../utlis/open_food_service.dart';

class ProcessPage extends StatefulWidget {
  final String barcode;
  final Map<String, dynamic>? product;

  const ProcessPage({
    super.key,
    required this.barcode,
    this.product,
  });

  @override
  State<ProcessPage> createState() => _ProcessPageState();
}

class _ProcessPageState extends State<ProcessPage> {
  late final PreferenceStore _store;

  bool _prefsReady = false;
  bool _running = false;
  bool _started = false;

  String _status = "Preparing analysis…";

  @override
  void initState() {
    super.initState();
    _store = context.read<PreferenceStore>();
    _store.addListener(_onPrefsChanged);

    if (!_store.isLoading) {
      _prefsReady = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startIfReady();
      });
    }
  }

  void _onPrefsChanged() {
    if (!_store.isLoading && !_prefsReady) {
      setState(() {
        _prefsReady = true;
      });
      _startIfReady();
    }
  }

  void _startIfReady() {
    if (!_prefsReady || _started || !mounted) return;
    _started = true;
    _runProcessing();
  }

  @override
  void dispose() {
    _store.removeListener(_onPrefsChanged);
    super.dispose();
  }

  Future<void> _runProcessing() async {
    if (_running || !_prefsReady) return;

    setState(() {
      _running = true;
      _status = "Preparing product details…";
    });

    try {
      setState(() {
        _status = "Checking product database…";
      });

      final fetchedProduct = widget.product ?? await OpenFoodFactsService.fetchProduct(widget.barcode);
      if (!mounted) return;

      if (fetchedProduct == null) {
        setState(() {
          _running = false;
        });
        await _showProcessingFallbackSheet(
          title: "Product not found",
          message:
              "We could not find barcode ${widget.barcode} in the product database. You can continue by taking a photo of the product and ingredients.",
          primaryActionLabel: "Take Photo Instead",
          secondaryActionLabel: "Back to Scan",
        );
        return;
      }

      final product = Map<String, dynamic>.from(fetchedProduct);

      setState(() {
        _status = "Extracting ingredients and nutrition…";
      });

      final extraction = await OpenFoodProductExtractor.extract(product);
      final ingredients = extraction.ingredients;
      final additives = extraction.additives;
      final productAllergens = extraction.productAllergens;
      final nutriments = extraction.nutriments;
      final nutrientLevels = extraction.nutrientLevels;
      final nutriScore = extraction.nutriScore;
      final novaGroup = extraction.novaGroup;

      if (ingredients == null || ingredients.isEmpty) {
        setState(() {
          _running = false;
        });
        await _showProcessingFallbackSheet(
          title: "Ingredients not available",
          message:
              "This product was found, but ingredient details are missing. You can continue by taking a photo of the label.",
        );
        return;
      }

      setState(() {
        _status = "Running preference evaluations…";
      });

      final analysis = await FoodAnalysisProcessor.process(
        input: FoodAnalysisInput(
          product: product,
          ingredients: ingredients,
          additives: additives,
          productAllergens: productAllergens,
          nutriments: nutriments,
          nutrientLevels: nutrientLevels,
          nutriScore: nutriScore,
          novaGroup: novaGroup,
        ),
        prefs: _store.prefs,
      );

      setState(() {
        _status = "Preparing result…";
      });

      final marketCountry = await MarketCountryService.resolve(product: product);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            product: product,
            ingredients: ingredients,
            additives: additives,
            allergens: productAllergens,
            nutriments: nutriments,
            nutrientLevels: nutrientLevels,
            nutriScore: nutriScore,
            novaGroup: novaGroup,
            ranEvaluations: analysis.ranEvaluations,
            evaluationResults: analysis.evaluationResults,
            userMarketCountry: marketCountry.country,
            userMarketCountrySource: marketCountry.source,
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint(stack.toString());
      if (!mounted) return;
      setState(() {
        _running = false;
      });
      await _showProcessingFallbackSheet(
        title: "We couldn't process this product",
        message:
            "Something went wrong while preparing the analysis. You can try again with a product photo instead.\n\n$e",
      );
    }
  }

  Future<void> _showProcessingFallbackSheet({
    required String title,
    required String message,
    String primaryActionLabel = "Take Photo",
    String secondaryActionLabel = "Back to Scan",
  }) async {
    if (!mounted) return;

    final goToPhoto = await showProcessingFallbackSheet(
      context: context,
      title: title,
      message: message,
      primaryActionLabel: primaryActionLabel,
      secondaryActionLabel: secondaryActionLabel,
    );

    if (!mounted) return;

    if (goToPhoto) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProductPhotoPage(barcode: widget.barcode),
        ),
      );
      return;
    }

    Navigator.pop(context);
  }

  int _currentStepIndex() {
    if (_status.contains("Preparing result")) return 3;
    if (_status.contains("Running preference evaluations")) return 2;
    if (_status.contains("Extracting ingredients and nutrition")) return 1;
    return 0;
  }

  String _productLabel() {
    final product = widget.product;
    final name = product?["product_name"]?.toString().trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final brand = product?["brands"]?.toString().trim();
    if (brand != null && brand.isNotEmpty) {
      return brand;
    }

    return "your scanned product";
  }

  @override
  Widget build(BuildContext context) {
    return ProcessLoadingView(
      productLabel: _productLabel(),
      status: _status,
      currentStep: _currentStepIndex(),
    );
  }
}
