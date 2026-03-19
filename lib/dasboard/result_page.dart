import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show File;
import '../diet_pref/restriction_definitions.dart';
import 'dashboard.dart';
import 'services/alternative_suggestions_service.dart';
import 'services/enjoy_suggestions_service.dart';
import 'services/scan_history_service.dart';

class ResultPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final List<String> ingredients;
  final List<String> additives;
  final List<String> allergens;
  final Map<String, double> nutriments;
  final Map<String, String> nutrientLevels;
  final String? nutriScore;
  final int? novaGroup;
  final List<String> ranEvaluations;
  final Map<String, dynamic> evaluationResults;
  final String? userMarketCountry;
  final String userMarketCountrySource;
  final int? historyEpochMillis;
  final bool isHistoryEntry;
  final List<String> initialTips;
  final int? initialTipsConfidencePercent;
  final List<Map<String, dynamic>> initialAlternatives;
  final int? initialAlternativesConfidencePercent;

  const ResultPage({
    super.key,
    required this.product,
    this.ingredients = const [],
    this.additives = const [],
    this.allergens = const [],
    this.nutriments = const {},
    this.nutrientLevels = const {},
    this.nutriScore,
    this.novaGroup,
    this.ranEvaluations = const [],
    this.evaluationResults = const {},
    this.userMarketCountry,
    this.userMarketCountrySource = "unavailable",
    this.historyEpochMillis,
    this.isHistoryEntry = false,
    this.initialTips = const [],
    this.initialTipsConfidencePercent,
    this.initialAlternatives = const [],
    this.initialAlternativesConfidencePercent,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late final String? imageUrl;
  late final Map<String, Map<String, dynamic>> ingredientAnnotations;
  late final Map<String, Map<String, dynamic>> additiveAnnotations;
  bool _tipsLoading = true;
  List<String> _tips = const [];
  int? _tipsConfidencePercent;
  bool _alternativesLoading = true;
  List<AlternativeSuggestion> _alternatives = const [];
  int? _alternativesConfidencePercent;
  late final int _historyEpochMillis;
  bool _historySaved = false;

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(initialIndex: 0),
      ),
      (route) => false,
    );
  }

  @override
  void initState() {

    super.initState();
    imageUrl = _getBestImage(widget.product);
    _historyEpochMillis =
        widget.historyEpochMillis ?? DateTime.now().millisecondsSinceEpoch;
    final normalized = _buildNormalizedAnnotations();
    ingredientAnnotations = normalized.$1;
    additiveAnnotations = normalized.$2;
    _tips = List<String>.from(widget.initialTips);
    _tipsConfidencePercent = widget.initialTipsConfidencePercent;
    _alternatives = widget.initialAlternatives
        .map(
          (item) => AlternativeSuggestion(
            type: item["type"]?.toString() ?? "best_match",
            title: item["title"]?.toString() ?? "",
            reason: item["reason"]?.toString() ?? "",
            fitTags: (item["fitTags"] as List?)
                    ?.map((tag) => tag?.toString() ?? "")
                    .where((tag) => tag.isNotEmpty)
                    .toList() ??
                const [],
            localExamples: (item["localExamples"] as List?)
                    ?.map((tag) => tag?.toString() ?? "")
                    .where((tag) => tag.isNotEmpty)
                    .toList() ??
                const [],
          ),
        )
        .toList();
    _alternativesConfidencePercent = widget.initialAlternativesConfidencePercent;
    _tipsLoading = !widget.isHistoryEntry;
    _alternativesLoading = !widget.isHistoryEntry;

    print("MYDEBUG allergy evaluation status: ${_extractDomainStatus("allergy")}");
    print("MYDEBUG allergy evaluation message: ${_extractDomainMessage("allergy")}");
    print("MYDEBUG allergy ingredient annotations: ${ingredientAnnotations.entries.where((e) => (e.value["domains"] as List).contains("allergy")).map((e) => e.key).toList()}");
    print("MYDEBUG allergy additive annotations: ${additiveAnnotations.entries.where((e) => (e.value["domains"] as List).contains("allergy")).map((e) => e.key).toList()}");

    if (widget.isHistoryEntry) {
      _tipsLoading = false;
      _alternativesLoading = false;
    } else {
      _loadSupplementarySection();
    }
  }

  @override
  Widget build(BuildContext context) {
   

    final productName = _productName(widget.product);
    final subtitle = _buildSubtitle(widget.product);
    final originCountry = _originCountry(widget.product);
    final geoCountry =
        widget.userMarketCountrySource == "geoip" ? widget.userMarketCountry : null;
    final origin = _displayOriginLabel(
      originCountry: originCountry,
      geoCountry: geoCountry,
    );
    final scanFrom = _displayScanFromLabel(
      originCountry: originCountry,
      geoCountry: geoCountry,
    );
    final summary = _buildStaticHeaderSummary();
    final analysisConfidencePercent = _overallAnalysisConfidencePercent();
    final overallTone = _overallDecisionTone();
    final overallStatus = _overallDecisionStatusLabel();
    final overallLine = _overallDecisionLine();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goToHome();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8F3),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _goToHome,
          ),
          title: const Text("Result"),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1D5E3A),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(
                productName: productName,
                subtitle: subtitle,
                origin: origin,
                scanFrom: scanFrom,
                summary: summary,
                analysisConfidencePercent: analysisConfidencePercent,
                overallTone: overallTone,
                overallStatus: overallStatus,
                overallLine: overallLine,
              ),
              const SizedBox(height: 24),
              _buildEvaluationSection(),
              if (_shouldShowSuggestionsSection()) ...[
                const SizedBox(height: 28),
                _buildEnjoySection(),
              ] else if (_shouldShowAlternativesSection()) ...[
                const SizedBox(height: 28),
                _buildAlternativesSection(),
              ],
              const SizedBox(height: 28),
              _buildIngredientsSection(),
              const SizedBox(height: 28),
              _buildAdditivesSection(),
              const SizedBox(height: 28),
              _buildNutritionSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard({
    required String productName,
    required String subtitle,
    required String? origin,
    required String? scanFrom,
    required String summary,
    required int? analysisConfidencePercent,
    required String overallTone,
    required String overallStatus,
    required String overallLine,
  }) {
    final overallColors = _bottomSheetColors(overallTone);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductImage(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F5A38),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6E8572),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (origin != null && origin.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: "Origin: ",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF3B6647),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: origin,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5F7465),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (scanFrom != null && scanFrom.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: "Scan from: ",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF3B6647),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: scanFrom,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5F7465),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: overallColors.$1,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: overallColors.$2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Overall Result",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: overallColors.$3,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              overallStatus,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: overallColors.$3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        overallLine,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: overallColors.$4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildScorePill(
                      label: "Nutri-Score",
                      value: widget.nutriScore ?? "-",
                      fillColor: _nutriScoreColor(widget.nutriScore),
                      helpText:
                          "Nutri-Score summarizes overall nutrition quality from A to E.",
                    ),
                    _buildScorePill(
                      label: "NOVA Group",
                      value: widget.novaGroup?.toString() ?? "-",
                      fillColor: _novaColor(widget.novaGroup),
                      helpText:
                          "NOVA describes how processed the product is. Lower is usually simpler.",
                    ),
                    if (analysisConfidencePercent != null)
                      _buildScorePill(
                        label: "Analysis Confidence",
                        value: "$analysisConfidencePercent%",
                        fillColor: const Color(0xFF456B9B),
                        helpText:
                            "This summarizes how confident the app is in its overall evaluation, based on the preference checks that ran.",
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    summary,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF3F5D49),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return _buildAnnotatedItemsSection(
      title: "Ingredients",
      items: widget.ingredients,
      annotations: ingredientAnnotations,
      emptyTitle: "Ingredient list",
      emptyMessage: "Ingredients not available.",
      countLabel: "${widget.ingredients.length} ingredients",
    );
  }

  Widget _buildAnnotatedItemsSection({
    required String title,
    required List<String> items,
    required Map<String, Map<String, dynamic>> annotations,
    required String emptyTitle,
    required String emptyMessage,
    required String countLabel,
  }) {
    final hasItems = items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 10),
        const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFD6E2D8),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFBFDF9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCE9DE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasItems ? countLabel : emptyTitle,
                style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.3,
                  color: Color(0xFF6A7F70),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (!hasItems)
                Text(
                  emptyMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.7,
                    color: Color(0xFF375245),
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _buildAnnotatedItemChip(
                        label: items[i],
                        annotation: annotations[_normalizeKey(items[i])],
                        trailingComma: i != items.length - 1,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdditivesSection() {
    return _buildAnnotatedItemsSection(
      title: "Additives",
      items: widget.additives,
      annotations: additiveAnnotations,
      emptyTitle: "Additive status",
      emptyMessage: "No additives detected.",
      countLabel: "${widget.additives.length} additives",
    );
  }

  Widget _buildNutritionSection() {
    final rows = _nutritionRows();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Nutrition Facts"),
        const SizedBox(height: 10),
        const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFD6E2D8),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD8E6DA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5EC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  "Per 100g",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2A6A45),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.4),
                    1: FlexColumnWidth(1),
                  },
                  border: TableBorder.all(
                    color: const Color(0xFFDDE8DF),
                    width: 1,
                  ),
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(
                        color: Color(0xFFF4FAF5),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Text(
                            "Nutrient",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2B5C3D),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Text(
                            "Value",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2B5C3D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (final row in rows)
                      TableRow(
                        decoration: BoxDecoration(
                          color: row.$3,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            child: Text(
                              row.$1,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF486252),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            child: Text(
                              row.$2,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF224F35),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (widget.nutrientLevels.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  "Nutrient Levels",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5F7465),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.nutrientLevels.entries
                      .map(
                        (entry) => _buildLevelChip(
                          _formatLevelLabel(entry.key),
                          entry.value,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluationSection() {
    final cards = _evaluationCards();

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Evaluation"),
        const SizedBox(height: 6),
        const Text(
          "Your preference checks, with verdicts and supporting evidence",
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6A7C6F),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFD6E2D8),
        ),
        const SizedBox(height: 14),
        Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i != cards.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEnjoySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle("How to Enjoy"),
            const SizedBox(width: 10),
            if (_tipsConfidencePercent != null)
              _buildConfidenceBadge(
                _tipsConfidencePercent!,
                subtle: true,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          widget.ranEvaluations.isEmpty
              ? "Simple serving ideas for first-time or everyday use"
              : "Serving suggestions with your preferences in mind",
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6A7C6F),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFD6E2D8),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCE7DD)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _tipsLoading ? _buildTipsSkeleton() : _buildTipsList(),
        ),
      ],
    );
  }

  Widget _buildAlternativesSection() {
    final alternatives = _alternatives;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle("Better Alternatives"),
            const SizedBox(width: 10),
            if (_alternativesConfidencePercent != null)
              _buildConfidenceBadge(
                _alternativesConfidencePercent!,
                subtle: true,
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          "Safer replacement ideas based on the product and your preferences",
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6A7C6F),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFD6E2D8),
        ),
        const SizedBox(height: 14),
        if (_alternativesLoading) _buildAlternativesSkeleton() else ...[
          for (var i = 0; i < alternatives.length; i++) ...[
            _buildAlternativeCard(
              suggestion: alternatives[i],
              featured: i == 0,
            ),
            if (i != alternatives.length - 1) const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  Widget _buildAlternativesSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
          padding: EdgeInsets.all(index == 0 ? 18 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCE7DD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 110,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4EF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4EF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F6F3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativeCard({
    required AlternativeSuggestion suggestion,
    required bool featured,
  }) {
    final colors = _alternativeColors(suggestion.type);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(featured ? 18 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.$2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: featured ? 84 : 72,
            decoration: BoxDecoration(
              color: colors.$1,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.$3,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _alternativeLabel(suggestion.type),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: colors.$1,
                        ),
                      ),
                    ),
                    if (featured) ...[
                      const SizedBox(width: 8),
                      const Text(
                        "Recommended",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF58705F),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  suggestion.title,
                  style: TextStyle(
                    fontSize: featured ? 18 : 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF234B34),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  suggestion.reason,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF4F6456),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (suggestion.localExamples.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    "Examples you may find locally: ${suggestion.localExamples.join(", ")}",
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Color(0xFF6A7C6F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (suggestion.fitTags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestion.fitTags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: colors.$4,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colors.$1,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFCFE3D3),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4EF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsList() {
    final tips = _tips.isEmpty
        ? const ["No serving suggestions available right now."]
        : _tips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < tips.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == tips.length - 1 ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2B6B45),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tips[i],
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: Color(0xFF496053),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProductImage() {
    final source = imageUrl;
    final isNetworkLike = source != null &&
        (source.startsWith("http://") ||
            source.startsWith("https://") ||
            source.startsWith("blob:") ||
            source.startsWith("data:"));

    return Container(
      width: 86,
      height: 112,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: source == null
          ? const Icon(
              Icons.image_outlined,
              color: Color(0xFF9AA7B5),
              size: 38,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isNetworkLike || kIsWeb
                  ? Image.network(
                      source,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF9AA7B5),
                        size: 38,
                      ),
                    )
                  : Image.file(
                      File(source),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF9AA7B5),
                        size: 38,
                      ),
                    ),
            ),
    );
  }

  Widget _buildScorePill({
    required String label,
    required String value,
    required Color fillColor,
    required String helpText,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showInfoBottomSheet(
        title: label,
        summary: value,
        details: [helpText],
        tone: "info",
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDCE2E8)),
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFF8FAFC),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF556476),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnotatedItemChip({
    required String label,
    required Map<String, dynamic>? annotation,
    required bool trailingComma,
  }) {
    final severity = annotation?["severity"]?.toString();
    final colors = _itemSeverityColors(severity);
    final text = trailingComma ? "$label," : label;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.$2),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.2,
          color: colors.$3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (annotation == null) return chip;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _showAnnotationBottomSheet(
        itemName: label,
        annotation: annotation,
      ),
      child: chip,
    );
  }

  void _showAnnotationBottomSheet({
    required String itemName,
    required Map<String, dynamic>? annotation,
  }) {
    final summary = _annotationSummary(annotation);
    final details = _annotationDetails(annotation);

    _showInfoBottomSheet(
      title: itemName,
      summary: summary,
      details: details,
      tone: annotation?["severity"]?.toString() ?? "info",
    );
  }

  void _showInfoBottomSheet({
    required String title,
    required String summary,
    required List<String> details,
    String tone = "info",
  }) {
    final colors = _bottomSheetColors(tone);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.$2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.$3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.$1,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    summary,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.$3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...details.map(
                  (detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      detail,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: colors.$4,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E6A43),
      ),
    );
  }

  Widget _buildEvaluationCard({
    required String title,
    required String domain,
    required String status,
    required String message,
    String? evidenceLine,
    int? confidencePercent,
  }) {
    final colors = _statusColors(status);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showEvaluationDomainBottomSheet(
        domain: domain,
        title: title,
        status: status,
        message: message,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE7DD)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 56,
              decoration: BoxDecoration(
                color: colors.$1,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF234B34),
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.$2,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: colors.$3),
                            ),
                            child: Text(
                              _displayStatus(status),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: colors.$1,
                              ),
                            ),
                          ),
                          if (confidencePercent != null)
                            _buildConfidenceBadge(confidencePercent),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF4F6456),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (evidenceLine != null && evidenceLine.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      evidenceLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF75877B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _evaluationCards() {
    final cards = <Widget>[];

    for (final domain in widget.ranEvaluations) {
      final raw = widget.evaluationResults[domain];
      if (raw is! Map) continue;

      final result = raw["result"];
      if (result is! Map) continue;

      String status = "unknown";
      String fallbackMessage = "No summary available.";

      if (domain == "allergy") {
        final summary = result["summary"];
        if (summary is Map) {
          status = summary["status"]?.toString() ?? status;
        }

        final ruleBased = result["rule_based"];
        if (ruleBased is Map && ruleBased["message"] != null) {
          fallbackMessage = ruleBased["message"].toString();
        } else if (result["message"] != null) {
          fallbackMessage = result["message"].toString();
        }
      } else {
        status = result["status"]?.toString() ?? status;
        fallbackMessage = result["message"]?.toString() ?? fallbackMessage;
      }

      final message = _buildEvaluationCardMessage(
        domain: domain,
        result: result,
        fallbackMessage: fallbackMessage,
      );
      final confidencePercent = _extractDomainConfidencePercent(
        domain: domain,
        result: result,
      );
      final evidenceLine = _evaluationEvidenceLine(domain);

      cards.add(
        _buildEvaluationCard(
          title: _domainTitle(domain),
          domain: domain,
          status: status,
          message: message,
          evidenceLine: evidenceLine,
          confidencePercent: confidencePercent,
        ),
      );
    }

    return cards;
  }

  Widget _buildConfidenceBadge(int percent, {bool subtle = false}) {
    final background = subtle
        ? const Color(0xFFF1F4F2)
        : const Color(0xFFF6F8FA);
    final border = subtle
        ? const Color(0xFFD5DED8)
        : const Color(0xFFD8E1E9);
    final textColor = subtle
        ? const Color(0xFF506357)
        : const Color(0xFF546575);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        "$percent% confidence",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  String _buildEvaluationCardMessage({
    required String domain,
    required Map result,
    required String fallbackMessage,
  }) {
    switch (domain) {
      case "religion":
        return _buildReligionEvaluationMessage(result, fallbackMessage);
      case "ethical":
        return _buildEthicalEvaluationMessage(result, fallbackMessage);
      case "allergy":
        return _buildAllergyEvaluationMessage(result, fallbackMessage);
      default:
        return fallbackMessage;
    }
  }

  String _buildReligionEvaluationMessage(Map result, String fallbackMessage) {
    final religion = result["religion"];
    final religionId = religion is Map ? religion["id"]?.toString() : null;
    final religionLabel = religionId == null || religionId.isEmpty
        ? "religious"
        : _humanizeLabel(religionId);

    final ingredientFindings =
        result["ingredients"] is Map ? Map<String, dynamic>.from(result["ingredients"]) : const <String, dynamic>{};
    final additiveFindings =
        result["additives"] is Map ? Map<String, dynamic>.from(result["additives"]) : const <String, dynamic>{};

    for (final entry in [...ingredientFindings.entries, ...additiveFindings.entries]) {
      final finding = entry.value;
      if (finding is! Map) continue;

      final violates = _stringList(finding["violates"]);
      if (violates.isNotEmpty) {
        final ruleTitle = restrictionDefinitions[violates.first]?.title ??
            _humanizeLabel(violates.first);
        return "${_humanizeItem(entry.key)} may violate your $religionLabel preference because it matches $ruleTitle.";
      }

      final uncertain = _stringList(finding["uncertain"]);
      if (uncertain.isNotEmpty) {
        final ruleTitle = restrictionDefinitions[uncertain.first]?.title ??
            _humanizeLabel(uncertain.first);
        return "${_humanizeItem(entry.key)} may need caution for your $religionLabel preference because it could relate to $ruleTitle.";
      }
    }

    return fallbackMessage;
  }

  String _buildEthicalEvaluationMessage(Map result, String fallbackMessage) {
    final ingredientFindings =
        result["ingredients"] is Map ? Map<String, dynamic>.from(result["ingredients"]) : const <String, dynamic>{};
    final additiveFindings =
        result["additives"] is Map ? Map<String, dynamic>.from(result["additives"]) : const <String, dynamic>{};

    for (final entry in [...ingredientFindings.entries, ...additiveFindings.entries]) {
      final finding = entry.value;
      if (finding is! Map) continue;

      final violations = finding["violations"];
      if (violations is List && violations.isNotEmpty && violations.first is Map) {
        final first = Map<String, dynamic>.from(violations.first as Map);
        final preference = first["preference"]?.toString();
        final ruleId = first["rule"]?.toString();
        final preferenceLabel = preference == null || preference.isEmpty
            ? "ethical"
            : _humanizeLabel(preference);
        final ruleTitle = ruleId == null || ruleId.isEmpty
            ? null
            : restrictionDefinitions[ruleId]?.title ?? _humanizeLabel(ruleId);

        if (ruleTitle != null && ruleTitle.isNotEmpty) {
          return "${_humanizeItem(entry.key)} conflicts with your $preferenceLabel preference because it matches $ruleTitle.";
        }

        return "${_humanizeItem(entry.key)} conflicts with your $preferenceLabel preference.";
      }

      final uncertain = _stringList(finding["uncertain"]);
      if (uncertain.isNotEmpty) {
        return "${_humanizeItem(entry.key)} may conflict with one of your ethical preferences.";
      }
    }

    return fallbackMessage;
  }

  String _buildAllergyEvaluationMessage(Map result, String fallbackMessage) {
    final ruleBased = result["rule_based"];
    if (ruleBased is! Map) return fallbackMessage;

    final matched = ruleBased["matched"];
    if (matched is! Map) return fallbackMessage;

    final strict = matched["strict"];
    if (strict is List && strict.isNotEmpty && strict.first is Map) {
      final first = Map<String, dynamic>.from(strict.first as Map);
      final itemTitle = first["title"]?.toString();
      final restrictionId = first["restriction"]?.toString();
      final ruleTitle = restrictionId == null || restrictionId.isEmpty
          ? itemTitle
          : restrictionDefinitions[restrictionId]?.title ?? itemTitle;
      final displayTitle = itemTitle == null || itemTitle.isEmpty
          ? (ruleTitle ?? "an allergen")
          : itemTitle;
      if (ruleTitle != null && ruleTitle.isNotEmpty) {
        return "Contains $displayTitle, which violates your allergy preference for $ruleTitle.";
      }
      return "Contains $displayTitle, which violates your allergy preferences.";
    }

    final custom = matched["custom"];
    if (custom is List && custom.isNotEmpty && custom.first is Map) {
      final first = Map<String, dynamic>.from(custom.first as Map);
      final keyword = first["keyword"]?.toString();
      if (keyword != null && keyword.isNotEmpty) {
        return "Contains $keyword, which matches one of your custom allergy keywords.";
      }
    }

    final sensitivities = matched["sensitivities"];
    if (sensitivities is List && sensitivities.isNotEmpty && sensitivities.first is Map) {
      final first = Map<String, dynamic>.from(sensitivities.first as Map);
      final sensitivity = first["id"]?.toString();
      if (sensitivity != null && sensitivity.isNotEmpty) {
        return "${_humanizeLabel(sensitivity)} may be relevant to one of your sensitivities.";
      }
    }

    return fallbackMessage;
  }

  String _humanizeItem(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return "${trimmed[0].toUpperCase()}${trimmed.substring(1)}";
  }

  Widget _buildLevelChip(String label, String value) {
    final normalized = value.toLowerCase();
    final colors = _levelColors(normalized);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.$2),
      ),
      child: Text(
        "$label: ${_capitalize(value)}",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.$3,
        ),
      ),
    );
  }

  List<(String, String, Color)> _nutritionRows() {
    final rows = <(String, String, Color)>[
      ("Energy", _formatEnergy(), const Color(0xFFFFFFFF)),
      ("Fat", _formatGrams(widget.nutriments["fat"]), const Color(0xFFFBFDF9)),
      (
        "Saturated Fat",
        _formatGrams(widget.nutriments["saturated_fat"]),
        const Color(0xFFFFFFFF),
      ),
      (
        "Carbohydrates",
        _formatGrams(widget.nutriments["carbohydrates"]),
        const Color(0xFFFBFDF9),
      ),
      (
        "Sugars",
        _formatGrams(widget.nutriments["sugars"]),
        const Color(0xFFFFFFFF),
      ),
      ("Fiber", _formatGrams(widget.nutriments["fiber"]), const Color(0xFFFBFDF9)),
      (
        "Protein",
        _formatGrams(widget.nutriments["protein"]),
        const Color(0xFFFFFFFF),
      ),
      ("Salt", _formatGrams(widget.nutriments["salt"]), const Color(0xFFFBFDF9)),
      (
        "Sodium",
        _formatGrams(widget.nutriments["sodium"]),
        const Color(0xFFFFFFFF),
      ),
    ];

    return rows.where((row) => row.$2 != "-").toList();
  }

  String _formatEnergy() {
    final value = widget.nutriments["energy_kcal"];
    if (value == null) return "-";
    final formatted = value % 1 == 0 ? value.toInt().toString() : value.toString();
    return "$formatted kcal";
  }

  String _formatGrams(double? value) {
    if (value == null) return "-";
    final formatted = value % 1 == 0 ? value.toInt().toString() : value.toString();
    return "$formatted g";
  }

  String _formatLevelLabel(String raw) {
    return raw
        .split("-")
        .map((part) => _capitalize(part))
        .join(" ");
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return "${value[0].toUpperCase()}${value.substring(1)}";
  }

  (Color, Color, Color) _levelColors(String level) {
    switch (level) {
      case "low":
        return (
          const Color(0xFFE8F6EC),
          const Color(0xFFCDE8D5),
          const Color(0xFF2B6B45),
        );
      case "moderate":
        return (
          const Color(0xFFFBF1DD),
          const Color(0xFFF1D59F),
          const Color(0xFF9A6414),
        );
      case "high":
        return (
          const Color(0xFFFBE7E4),
          const Color(0xFFF0C3BC),
          const Color(0xFF9B4233),
        );
      default:
        return (
          const Color(0xFFF1F4F2),
          const Color(0xFFD7E0D9),
          const Color(0xFF56685C),
        );
    }
  }

  (Map<String, Map<String, dynamic>>, Map<String, Map<String, dynamic>>)
  _buildNormalizedAnnotations() {
    final ingredients = <String, Map<String, dynamic>>{};
    final additives = <String, Map<String, dynamic>>{};

    for (final domain in widget.ranEvaluations) {
      final raw = widget.evaluationResults[domain];
      if (raw is! Map) continue;
      final result = raw["result"];
      if (result is! Map) continue;

      switch (domain) {
        case "religion":
        case "ethical":
        case "medical":
          _collectGenericItemIssues(
            domain: domain,
            result: result,
            ingredientTarget: ingredients,
            additiveTarget: additives,
          );
          break;
        case "allergy":
          _collectAllergyIssues(
            result: result,
            ingredientTarget: ingredients,
            additiveTarget: additives,
          );
          break;
        case "lifestyle":
          _collectLifestyleIssues(
            result: result,
            ingredientTarget: ingredients,
            additiveTarget: additives,
          );
          break;
      }
    }

    return (ingredients, additives);
  }

  void _collectGenericItemIssues({
    required String domain,
    required Map result,
    required Map<String, Map<String, dynamic>> ingredientTarget,
    required Map<String, Map<String, dynamic>> additiveTarget,
  }) {
    final ingredients = result["ingredients"];
    if (ingredients is Map) {
      ingredients.forEach((key, value) {
        _mergeIssueFromEntry(
          target: ingredientTarget,
          itemName: key.toString(),
          domain: domain,
          entry: value,
          itemType: "ingredient",
        );
      });
    }

    final additives = result["additives"];
    if (additives is Map) {
      additives.forEach((key, value) {
        _mergeIssueFromEntry(
          target: additiveTarget,
          itemName: key.toString(),
          domain: domain,
          entry: value,
          itemType: "additive",
        );
      });
    }
  }

  void _collectAllergyIssues({
    required Map result,
    required Map<String, Map<String, dynamic>> ingredientTarget,
    required Map<String, Map<String, dynamic>> additiveTarget,
  }) {
    final ruleBased = result["rule_based"];
    if (ruleBased is Map) {
      final matched = ruleBased["matched"];
      if (matched is Map) {
        _collectRuleBasedAllergyMatches(
          matches: matched["strict"],
          ingredientTarget: ingredientTarget,
          additiveTarget: additiveTarget,
          severity: "violation",
          matchType: "allergen",
        );
        _collectRuleBasedAllergyMatches(
          matches: matched["custom"],
          ingredientTarget: ingredientTarget,
          additiveTarget: additiveTarget,
          severity: "violation",
          matchType: "custom",
        );
        _collectRuleBasedAllergyMatches(
          matches: matched["sensitivities"],
          ingredientTarget: ingredientTarget,
          additiveTarget: additiveTarget,
          severity: "warning",
          matchType: "sensitivity",
        );
      }
    }

    final reasonBased = result["reason_based"];
    if (reasonBased is! Map) return;

    final ingredients = reasonBased["ingredients"];
    if (ingredients is Map) {
      ingredients.forEach((key, value) {
        _mergeIssueFromEntry(
          target: ingredientTarget,
          itemName: key.toString(),
          domain: "allergy",
          entry: value,
          itemType: "ingredient",
        );
      });
    }

    final additives = reasonBased["additives"];
    if (additives is Map) {
      additives.forEach((key, value) {
        _mergeIssueFromEntry(
          target: additiveTarget,
          itemName: key.toString(),
          domain: "allergy",
          entry: value,
          itemType: "additive",
        );
      });
    }
  }

  void _collectRuleBasedAllergyMatches({
    required dynamic matches,
    required Map<String, Map<String, dynamic>> ingredientTarget,
    required Map<String, Map<String, dynamic>> additiveTarget,
    required String severity,
    required String matchType,
  }) {
    if (matches is! List) return;

    for (final entry in matches) {
      if (entry is! Map) continue;

      final source = entry["source"]?.toString();
      final restrictionId = entry["restriction"]?.toString();
      final title = entry["title"]?.toString();
      final keyword = entry["keyword"]?.toString();
      final displayName = title ?? keyword ?? "Allergy match";

      final isAdditive = source == "additive";
      final targetMap = isAdditive ? additiveTarget : ingredientTarget;
      final candidates = isAdditive ? widget.additives : widget.ingredients;

      final matchedItems = _matchAllergyItems(
        candidates: candidates,
        restrictionId: restrictionId,
        keyword: keyword ?? title,
      );

      for (final itemName in matchedItems) {
        _mergeAnnotation(
          target: targetMap,
          itemName: itemName,
          itemType: isAdditive ? "additive" : "ingredient",
          severity: severity,
          domain: "allergy",
          reason: _allergyReason(matchType, displayName),
          parsedRuleId: restrictionId ?? _normalizeKey(displayName),
          parsedRuleTitle: _allergyLabel(matchType, displayName),
        );
      }
    }
  }

  List<String> _matchAllergyItems({
    required List<String> candidates,
    required String? restrictionId,
    required String? keyword,
  }) {
    final matches = <String>[];
    final examples = restrictionId != null
        ? restrictionDefinitions[restrictionId]?.examples ?? const <String>[]
        : const <String>[];
    final normalizedKeyword =
        keyword == null || keyword.isEmpty ? null : _normalizeKey(keyword);

    for (final candidate in candidates) {
      final normalizedCandidate = _normalizeKey(candidate);
      var matched = false;

      for (final example in examples) {
        final normalizedExample = _normalizeKey(example);
        if (normalizedCandidate == normalizedExample ||
            normalizedCandidate.contains(normalizedExample) ||
            normalizedExample.contains(normalizedCandidate)) {
          matched = true;
          break;
        }
      }

      if (!matched &&
          normalizedKeyword != null &&
          (normalizedCandidate.contains(normalizedKeyword) ||
              normalizedKeyword.contains(normalizedCandidate))) {
        matched = true;
      }

      if (matched) {
        matches.add(candidate);
      }
    }

    return matches;
  }

  String _allergyLabel(String matchType, String displayName) {
    switch (matchType) {
      case "custom":
        return "Custom allergy match: $displayName";
      case "sensitivity":
        return "Sensitivity match: $displayName";
      default:
        return displayName;
    }
  }

  String _allergyReason(String matchType, String displayName) {
    switch (matchType) {
      case "custom":
        return "This item matches your custom allergy keyword: $displayName.";
      case "sensitivity":
        return "This item may affect your sensitivity to $displayName.";
      default:
        return "This item appears to contain $displayName.";
    }
  }

  void _collectLifestyleIssues({
    required Map result,
    required Map<String, Map<String, dynamic>> ingredientTarget,
    required Map<String, Map<String, dynamic>> additiveTarget,
  }) {
    final restrictions = result["restriction_results"];
    if (restrictions is! Map) return;

    restrictions.forEach((goalKey, value) {
      if (value is! Map) return;
      final status = value["status"]?.toString().toLowerCase();
      final severity = status == "violation" ? "violation" : "warning";
      final goalTitle =
          value["goal_title"]?.toString() ?? _capitalize(goalKey.toString());
      final triggered = value["triggered_restrictions"];
      if (triggered is! List) return;

      for (final item in triggered) {
        if (item is! Map) continue;
        final reason = item["reason"]?.toString();
        if (reason == null || reason.isEmpty) continue;

        for (final ingredient in widget.ingredients) {
          if (_reasonMentionsItem(reason, ingredient)) {
            _mergeAnnotation(
              target: ingredientTarget,
              itemName: ingredient,
              itemType: "ingredient",
              severity: severity,
              domain: "lifestyle",
              reason: "$goalTitle: $reason",
            );
          }
        }

        for (final additive in widget.additives) {
          if (_reasonMentionsItem(reason, additive)) {
            _mergeAnnotation(
              target: additiveTarget,
              itemName: additive,
              itemType: "additive",
              severity: severity,
              domain: "lifestyle",
              reason: "$goalTitle: $reason",
            );
          }
        }
      }
    });
  }

  void _mergeIssueFromEntry({
    required Map<String, Map<String, dynamic>> target,
    required String itemName,
    required String domain,
    required dynamic entry,
    required String itemType,
  }) {
    if (entry is! Map) return;

    final violations = _extractViolationDetails(entry["violations"], domain);
    if (domain == "religion") {
      final religionViolates = _extractViolationDetails(entry["violates"], domain);
      violations.addAll(religionViolates);
    }

    for (final violation in violations) {
      _mergeAnnotation(
        target: target,
        itemName: itemName,
        itemType: itemType,
        severity: "violation",
        domain: domain,
        reason: violation.$1,
        parsedRuleId: violation.$2,
        parsedRuleTitle: violation.$3,
        parsedPreferenceTitle: violation.$4,
        parsedConditionTitle: violation.$5,
        parsedGoalTitle: violation.$6,
      );
    }

    final uncertain = _stringList(entry["uncertain"]);
    for (final reason in uncertain) {
      _mergeAnnotation(
        target: target,
        itemName: itemName,
        itemType: itemType,
        severity: "warning",
        domain: domain,
        reason: reason,
      );
    }
  }

  List<(String, String?, String?, String?, String?, String?)>
  _extractViolationDetails(dynamic value, String domain) {
    if (value is! List) return [];

    final results = <(String, String?, String?, String?, String?, String?)>[];

    for (final item in value) {
      if (item is String) {
        final parsed = _parseReasonDetails(item);
        results.add(parsed);
        continue;
      }

      if (item is Map) {
        final preference = item["preference"]?.toString();
        final ruleId = item["rule"]?.toString();
        final restriction = item["restriction"]?.toString();
        final allergenId = item["id"]?.toString();
        final allergenTitle = item["title"]?.toString();
        final detectedRuleId = ruleId ?? restriction;

        final ruleTitle = detectedRuleId != null
            ? restrictionDefinitions[detectedRuleId]?.title ??
                _humanizeLabel(detectedRuleId)
            : allergenTitle != null && allergenTitle.isNotEmpty
            ? allergenTitle
            : allergenId != null
            ? _allergenDisplayName(allergenId)
            : null;

        final preferenceTitle = preference == null ? null : _humanizeLabel(preference);

        String reason = _domainSummary(domain, "violation");
        if (domain == "allergy" && ruleTitle != null) {
          reason = "This item appears to contain $ruleTitle.";
        } else if (ruleTitle != null) {
          reason = "This item matches the rule $ruleTitle.";
        }

        results.add((
          reason,
          detectedRuleId ?? allergenId,
          ruleTitle,
          preferenceTitle,
          null,
          null,
        ));
      }
    }

    return results;
  }

  void _mergeAnnotation({
    required Map<String, Map<String, dynamic>> target,
    required String itemName,
    required String itemType,
    required String severity,
    required String domain,
    required String reason,
    String? parsedRuleId,
    String? parsedRuleTitle,
    String? parsedPreferenceTitle,
    String? parsedConditionTitle,
    String? parsedGoalTitle,
  }) {
    final key = _normalizeKey(itemName);
    final existing = target[key];
    final parsedReason = _parseReasonDetails(reason);
    final cleanedReason = parsedReason.$1;
    final ruleId = parsedRuleId ?? parsedReason.$2;
    final ruleTitle = parsedRuleTitle ?? parsedReason.$3;
    final preferenceTitle = parsedPreferenceTitle ?? parsedReason.$4;
    final conditionTitle = parsedConditionTitle ?? parsedReason.$5;
    final goalTitle = parsedGoalTitle ?? parsedReason.$6;
    final userSeverity = severity == "violation" ? "violation" : "warning";

    if (existing == null) {
      target[key] = {
        "name": itemName,
        "type": itemType,
        "severity": userSeverity,
        "domains": [domain],
        "reasons": [cleanedReason],
        "domainDetails": [
          {
            "domain": domain,
            "severity": userSeverity,
            "summary": _domainSummary(domain, userSeverity),
            "reason": cleanedReason,
            "ruleId": ruleId,
            "ruleTitle": ruleTitle,
            "preferenceTitle": preferenceTitle,
            "conditionTitle": conditionTitle,
            "goalTitle": goalTitle,
          },
        ],
      };
      return;
    }

    existing["severity"] = _strongerSeverity(
      existing["severity"]?.toString(),
      userSeverity,
    );

    final domains = List<String>.from(existing["domains"] as List);
    if (!domains.contains(domain)) {
      domains.add(domain);
      existing["domains"] = domains;
    }

    final reasons = List<String>.from(existing["reasons"] as List);
    if (!reasons.contains(cleanedReason)) {
      reasons.add(cleanedReason);
      existing["reasons"] = reasons;
    }

    final domainDetails = List<Map<String, dynamic>>.from(
      (existing["domainDetails"] as List?)?.map(
            (item) => Map<String, dynamic>.from(item as Map),
          ) ??
          const [],
    );

    final alreadyExists = domainDetails.any(
      (detail) =>
          detail["domain"] == domain &&
          detail["reason"] == cleanedReason &&
          detail["severity"] == userSeverity,
    );

    if (!alreadyExists) {
      domainDetails.add({
        "domain": domain,
        "severity": userSeverity,
        "summary": _domainSummary(domain, userSeverity),
        "reason": cleanedReason,
        "ruleId": ruleId,
        "ruleTitle": ruleTitle,
        "preferenceTitle": preferenceTitle,
        "conditionTitle": conditionTitle,
        "goalTitle": goalTitle,
      });
      existing["domainDetails"] = domainDetails;
    }
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item?.toString().trim() ?? "")
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _normalizeKey(String value) => value.trim().toLowerCase();

  bool _reasonMentionsItem(String reason, String item) {
    final normalizedReason = _normalizeKey(reason);
    final normalizedItem = _normalizeKey(item);

    if (normalizedReason.contains(normalizedItem)) return true;

    final itemTokens = normalizedItem.split(RegExp(r"[-_\s]+"));
    return itemTokens.length > 1 &&
        itemTokens.every(
          (token) => token.isNotEmpty && normalizedReason.contains(token),
        );
  }

  String _strongerSeverity(String? current, String next) {
    const priority = {
      "violation": 3,
      "warning": 2,
      "safe": 1,
    };

    final currentScore = priority[current] ?? 0;
    final nextScore = priority[next] ?? 0;
    return nextScore > currentScore ? next : (current ?? next);
  }

  String _annotationSummary(Map<String, dynamic>? annotation) {
    if (annotation == null) return "No issue detected";

    final severity = annotation["severity"]?.toString() ?? "warning";
    final domains = List<String>.from(annotation["domains"] as List)
        .map(_domainTitle)
        .toList();

    if (domains.isEmpty) {
      return severity == "violation"
          ? "This item conflicts with your preferences"
          : "This item may need extra attention";
    }

    if (severity == "violation") {
      return "This item conflicts with your ${_joinWithAnd(domains).toLowerCase()} preferences.";
    }

    return "This item may need extra attention for your ${_joinWithAnd(domains).toLowerCase()} preferences.";
  }

  List<String> _annotationDetails(Map<String, dynamic>? annotation) {
    if (annotation == null) {
      return const ["No evaluation issue detected for this item."];
    }

    final details = <String>[];
    final domainDetails = List<Map<String, dynamic>>.from(
      (annotation["domainDetails"] as List?)?.map(
            (item) => Map<String, dynamic>.from(item as Map),
          ) ??
          const [],
    );

    for (final detail in domainDetails) {
      final domain = _domainTitle(detail["domain"]?.toString() ?? "");
      final status = _displayStatus(detail["severity"]?.toString() ?? "warning");
      final summary = detail["summary"]?.toString();
      final reason = detail["reason"]?.toString();
      final preferenceTitle = detail["preferenceTitle"]?.toString();
      final conditionTitle = detail["conditionTitle"]?.toString();
      final goalTitle = detail["goalTitle"]?.toString();
      final ruleTitle = detail["ruleTitle"]?.toString();

      final buffer = StringBuffer()..writeln("$domain • $status");
      if (summary != null && summary.isNotEmpty) {
        buffer.writeln(summary);
      }
      if (preferenceTitle != null && preferenceTitle.isNotEmpty) {
        buffer.writeln("Your preference: $preferenceTitle");
      }
      if (conditionTitle != null && conditionTitle.isNotEmpty) {
        buffer.writeln("Your condition: $conditionTitle");
      }
      if (goalTitle != null && goalTitle.isNotEmpty) {
        buffer.writeln("Your goal: $goalTitle");
      }
      if (ruleTitle != null && ruleTitle.isNotEmpty) {
        final checkLabel = _detailCheckLabel(domain, ruleTitle);
        buffer.writeln("$checkLabel: $ruleTitle");
      }
      if (reason != null && reason.isNotEmpty) {
        buffer.write("Why it was flagged: $reason");
      }
      details.add(buffer.toString().trim());
    }

    if (details.isEmpty) {
      final reasons = List<String>.from(annotation["reasons"] as List? ?? const []);
      return reasons.isEmpty ? const ["This item was flagged by your preferences."] : reasons;
    }

    return details;
  }

  String _domainSummary(String domain, String severity) {
    final isViolation = severity == "violation";
    switch (domain) {
      case "religion":
        return isViolation
            ? "This item does not fit your religious preference."
            : "This item may not fit your religious preference.";
      case "ethical":
        return isViolation
            ? "This item does not fit your ethical preference."
            : "This item may not fit your ethical preference.";
      case "allergy":
        return isViolation
            ? "This item may trigger an allergy-related concern."
            : "This item may need allergy-related caution.";
      case "medical":
        return isViolation
            ? "This item may not fit your medical preference."
            : "This item may need extra medical caution.";
      case "lifestyle":
        return isViolation
            ? "This item does not fit your lifestyle goal."
            : "This item may work against your lifestyle goal.";
      default:
        return isViolation
            ? "This item was flagged by your preferences."
            : "This item may need attention.";
    }
  }

  String _detailCheckLabel(String domain, String ruleTitle) {
    if (domain != "Allergy") return "What was checked";

    if (ruleTitle.startsWith("Custom allergy match:")) {
      return "Found custom match";
    }
    if (ruleTitle.startsWith("Sensitivity match:")) {
      return "Found sensitivity";
    }
    return "Found allergen";
  }

  String _userFriendlyReason(String reason) {
    var value = reason.trim();
    if (value.isEmpty) return value;
    value = value.replaceAll(RegExp(r"\s+"), " ");
    value = value.replaceAll("Product contains", "This product contains");
    value = value.replaceAll("Contains", "This product contains");
    value = value.replaceAll(
      "No relationship found between",
      "No clear link was found between",
    );
    value = value.replaceAllMapped(
      RegExp(r"\bcontains_([a-z0-9_]+)\b"),
      (match) => _humanizeLabel(match.group(1) ?? ""),
    );
    return "${value[0].toUpperCase()}${value.substring(1)}";
  }

  (String, String?, String?, String?, String?, String?) _parseReasonDetails(
    String reason,
  ) {
    String? preferenceTitle;
    String? conditionTitle;
    String? goalTitle;
    String? ruleId;
    String? ruleTitle;

    String cleaned = reason.trim();
    if (cleaned.isEmpty) {
      return ("", null, null, null, null, null);
    }

    final preferenceMatch = RegExp(
      r"preference:\s*([^,}\]]+)",
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (preferenceMatch != null) {
      preferenceTitle = _humanizeLabel(preferenceMatch.group(1)!);
      cleaned = cleaned.replaceFirst(preferenceMatch.group(0)!, "");
    }

    final conditionMatch = RegExp(
      r"condition:\s*\[?([^,\]}]+)\]?",
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (conditionMatch != null) {
      conditionTitle = conditionMatch.group(1)!.trim();
      cleaned = cleaned.replaceFirst(conditionMatch.group(0)!, "");
    }

    final goalMatch = RegExp(
      r"goal:\s*([^,}\]]+)",
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (goalMatch != null) {
      goalTitle = _humanizeLabel(goalMatch.group(1)!);
      cleaned = cleaned.replaceFirst(goalMatch.group(0)!, "");
    }

    final restrictionMatch = RegExp(
      r"(restriction|rule):\s*([a-z0-9_]+)",
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (restrictionMatch != null) {
      ruleId = restrictionMatch.group(2)!.trim();
      ruleTitle = restrictionDefinitions[ruleId]?.title ?? _humanizeLabel(ruleId);
      cleaned = cleaned.replaceFirst(restrictionMatch.group(0)!, "");
    } else {
      final inferredRuleId = _findRestrictionIdInText(cleaned);
      if (inferredRuleId != null) {
        ruleId = inferredRuleId;
        ruleTitle =
            restrictionDefinitions[inferredRuleId]?.title ??
            _humanizeLabel(inferredRuleId);
      }
    }

    cleaned = cleaned
        .replaceAll(RegExp(r"[\{\}]"), "")
        .replaceAll(RegExp(r"\s*,\s*"), ", ")
        .replaceAll(RegExp(r"^,\s*"), "")
        .replaceAll(RegExp(r"\s+"), " ")
        .trim();

    if ((cleaned.isEmpty || cleaned == ruleId) && ruleTitle != null) {
      cleaned = "This product contains $ruleTitle.";
    }

    final userReason = _userFriendlyReason(cleaned);

    return (
      userReason,
      ruleId,
      ruleTitle,
      preferenceTitle,
      conditionTitle,
      goalTitle,
    );
  }

  String? _findRestrictionIdInText(String text) {
    for (final id in restrictionDefinitions.keys) {
      if (text.contains(id)) return id;
    }
    return null;
  }

  String _humanizeLabel(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r"[\[\]\{\}]"), "")
        .replaceAll("_", " ");
    if (cleaned.isEmpty) return cleaned;

    return cleaned
        .split(RegExp(r"\s+"))
        .map((word) {
          if (word.isEmpty) return word;
          return "${word[0].toUpperCase()}${word.substring(1)}";
        })
        .join(" ");
  }

  String _allergenDisplayName(String id) {
    switch (id.toLowerCase()) {
      case "eggs":
        return "Egg";
      case "peanuts":
        return "Peanut";
      case "treenuts":
        return "Tree nut";
      case "molluscs":
        return "Mollusc";
      default:
        return _humanizeLabel(id);
    }
  }

  String _joinWithAnd(List<String> items) {
    if (items.isEmpty) return "";
    if (items.length == 1) return items.first;
    if (items.length == 2) return "${items.first} and ${items.last}";
    return "${items.sublist(0, items.length - 1).join(", ")}, and ${items.last}";
  }

  (Color, Color, Color, Color) _bottomSheetColors(String tone) {
    switch (tone.toLowerCase()) {
      case "violation":
      case "unsafe":
        return (
          const Color(0xFFFBE7E4),
          const Color(0xFFF0C3BC),
          const Color(0xFF9B4233),
          const Color(0xFF6F3B33),
        );
      case "warning":
      case "cannot_assess":
        return (
          const Color(0xFFFBF1DD),
          const Color(0xFFF0D8A9),
          const Color(0xFF9A6414),
          const Color(0xFF73572D),
        );
      default:
        return (
          const Color(0xFFEAF5EC),
          const Color(0xFFD5DED5),
          const Color(0xFF2B6B45),
          const Color(0xFF496053),
        );
    }
  }

  (Color, Color, Color) _itemSeverityColors(String? severity) {
    switch ((severity ?? "").toLowerCase()) {
      case "warning":
        return (
          const Color(0xFFFBF1DD),
          const Color(0xFFF0D8A9),
          const Color(0xFF9A6414),
        );
      case "violation":
        return (
          const Color(0xFFFBE7E4),
          const Color(0xFFF0C3BC),
          const Color(0xFF9B4233),
        );
      default:
        return (
          const Color(0xFFF2F7F2),
          const Color(0xFFDCE9DE),
          const Color(0xFF355244),
        );
    }
  }

  String _domainTitle(String domain) {
    switch (domain) {
      case "religion":
        return "Religion";
      case "ethical":
        return "Ethical";
      case "allergy":
        return "Allergy";
      case "medical":
        return "Medical";
      case "lifestyle":
        return "Lifestyle";
      default:
        return _capitalize(domain);
    }
  }

  String _displayStatus(String status) {
    switch (status.toLowerCase()) {
      case "safe":
        return "Safe";
      case "warning":
        return "Warning";
      case "violation":
        return "Violation";
      case "unsafe":
        return "Unsafe";
      case "cannot_assess":
        return "Cannot Assess";
      default:
        return _capitalize(status.replaceAll("_", " "));
    }
  }

  String _extractDomainStatus(String domain) {
    final raw = widget.evaluationResults[domain];
    if (raw is! Map) return "missing";
    final result = raw["result"];
    if (result is! Map) return "missing";

    if (domain == "allergy") {
      final summary = result["summary"];
      if (summary is Map) {
        return summary["status"]?.toString() ?? "missing";
      }
    }

    return result["status"]?.toString() ?? "missing";
  }

  String _extractDomainMessage(String domain) {
    final raw = widget.evaluationResults[domain];
    if (raw is! Map) return "missing";
    final result = raw["result"];
    if (result is! Map) return "missing";

    String fallbackMessage = "missing";

    if (domain == "allergy") {
      final ruleBased = result["rule_based"];
      if (ruleBased is Map && ruleBased["message"] != null) {
        fallbackMessage = ruleBased["message"].toString();
      } else {
        fallbackMessage = result["message"]?.toString() ?? fallbackMessage;
      }
    } else {
      fallbackMessage = result["message"]?.toString() ?? fallbackMessage;
    }

    return _buildEvaluationCardMessage(
      domain: domain,
      result: result,
      fallbackMessage: fallbackMessage,
    );
  }

  int? _extractDomainConfidencePercent({
    required String domain,
    required Map result,
  }) {
    if (domain == "allergy") {
      final summary = result["summary"];
      if (summary is Map) {
        final percent = _confidenceValueToPercent(summary["confidence"]);
        if (percent != null) return percent;
      }
    }

    final direct = _confidenceValueToPercent(result["confidence"]);
    if (direct != null) return direct;

    if (domain == "lifestyle") {
      return _deriveLifestyleConfidencePercent(result);
    }

    return null;
  }

  int? _confidenceValueToPercent(dynamic confidence) {
    final value = confidence?.toString().trim().toLowerCase();
    switch (value) {
      case "high":
        return 90;
      case "medium":
        return 74;
      case "low":
        return 56;
      default:
        return null;
    }
  }

  int _deriveLifestyleConfidencePercent(Map result) {
    final restrictionResults =
        result["restriction_results"] is Map ? result["restriction_results"] as Map : const {};
    final awarenessResults =
        result["awareness_results"] is Map ? result["awareness_results"] as Map : const {};

    if (restrictionResults.isEmpty && awarenessResults.isEmpty) {
      return 52;
    }

    if (restrictionResults.isNotEmpty && awarenessResults.isNotEmpty) {
      return 82;
    }

    return 72;
  }

  String _overallDecisionTone() {
    var hasWarning = false;
    var hasCannotAssess = false;

    for (final domain in widget.ranEvaluations) {
      final status = _extractDomainStatus(domain).toLowerCase();
      if (status == "unsafe" || status == "violation") {
        return "unsafe";
      }
      if (status == "warning") {
        hasWarning = true;
      }
      if (status == "cannot_assess" || status == "unknown") {
        hasCannotAssess = true;
      }
    }

    if (hasWarning || hasCannotAssess) return "warning";
    return "safe";
  }

  String _overallDecisionStatusLabel() => _displayStatus(_overallDecisionTone());

  String _overallDecisionLine() {
    if (widget.ranEvaluations.isEmpty) {
      return "No personalized checks are active for this product yet.";
    }

    final unsafeDomains = <String>[];
    final warningDomains = <String>[];
    final limitedDomains = <String>[];

    for (final domain in widget.ranEvaluations) {
      final status = _extractDomainStatus(domain).toLowerCase();
      final title = _domainTitle(domain);
      if (status == "unsafe" || status == "violation") {
        unsafeDomains.add(title);
      } else if (status == "warning") {
        warningDomains.add(title);
      } else if (status == "cannot_assess" || status == "unknown") {
        limitedDomains.add(title);
      }
    }

    if (unsafeDomains.isNotEmpty) {
      return "Conflicts found in ${_joinWithAnd(unsafeDomains)} checks.";
    }
    if (warningDomains.isNotEmpty) {
      return "Caution is recommended for ${_joinWithAnd(warningDomains)} checks.";
    }
    if (limitedDomains.isNotEmpty) {
      return "Some checks had limited certainty: ${_joinWithAnd(limitedDomains)}.";
    }

    return "No conflicts were detected in your active preference checks.";
  }

  String? _evaluationEvidenceLine(String domain) {
    final matchedIngredients = ingredientAnnotations.entries
        .where((entry) => (entry.value["domains"] as List).contains(domain))
        .map((entry) => entry.value["name"]?.toString() ?? entry.key)
        .take(2)
        .toList();
    final matchedAdditives = additiveAnnotations.entries
        .where((entry) => (entry.value["domains"] as List).contains(domain))
        .map((entry) => entry.value["name"]?.toString() ?? entry.key)
        .take(2)
        .toList();

    if (matchedIngredients.isEmpty && matchedAdditives.isEmpty) {
      return "No direct ingredient or additive marker identified";
    }

    final parts = <String>[];
    if (matchedIngredients.isNotEmpty) {
      parts.add("Ingredients: ${matchedIngredients.join(", ")}");
    }
    if (matchedAdditives.isNotEmpty) {
      parts.add("Additives: ${matchedAdditives.join(", ")}");
    }

    return parts.join(" • ");
  }

  int? _overallAnalysisConfidencePercent() {
    const weights = {
      "allergy": 25,
      "religion": 22,
      "medical": 20,
      "ethical": 18,
      "lifestyle": 15,
    };

    var weightedSum = 0.0;
    var totalWeight = 0.0;

    for (final domain in widget.ranEvaluations) {
      final raw = widget.evaluationResults[domain];
      if (raw is! Map) continue;
      final result = raw["result"];
      if (result is! Map) continue;

      final confidence = _extractDomainConfidencePercent(
        domain: domain,
        result: result,
      );
      if (confidence == null) continue;

      final weight = (weights[domain] ?? 12).toDouble();
      weightedSum += confidence * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return null;
    return (weightedSum / totalWeight).round().clamp(0, 100);
  }

  void _showEvaluationDomainBottomSheet({
    required String domain,
    required String title,
    required String status,
    required String message,
  }) {
    final raw = widget.evaluationResults[domain];
    final result = raw is Map ? raw["result"] : null;
    final confidencePercent = result is Map
        ? _extractDomainConfidencePercent(domain: domain, result: result)
        : null;
    final matchedIngredients = ingredientAnnotations.entries
        .where((entry) => (entry.value["domains"] as List).contains(domain))
        .map((entry) => entry.value["name"]?.toString() ?? entry.key)
        .toList();
    final matchedAdditives = additiveAnnotations.entries
        .where((entry) => (entry.value["domains"] as List).contains(domain))
        .map((entry) => entry.value["name"]?.toString() ?? entry.key)
        .toList();

    final details = <String>[
      if (confidencePercent != null) "Confidence: $confidencePercent%",
      message,
    ];
    final isFlaggedStatus = status.toLowerCase() != "safe";

    if (matchedIngredients.isNotEmpty) {
      details.add(
        "${isFlaggedStatus ? "Flagged" : "Relevant"} ingredients: ${matchedIngredients.join(", ")}",
      );
    }

    if (matchedAdditives.isNotEmpty) {
      details.add(
        "${isFlaggedStatus ? "Flagged" : "Relevant"} additives: ${matchedAdditives.join(", ")}",
      );
    }

    if (matchedIngredients.isEmpty && matchedAdditives.isEmpty) {
      details.add("No specific ingredient or additive was identified.");
    }

    _showInfoBottomSheet(
      title: title,
      summary: _displayStatus(status),
      details: details,
      tone: status,
    );
  }

  bool _shouldShowSuggestionsSection() {
    for (final domain in widget.ranEvaluations) {
      if (_extractDomainStatus(domain).toLowerCase() == "unsafe") {
        return false;
      }
    }

    return true;
  }

  bool _shouldShowAlternativesSection() {
    for (final domain in widget.ranEvaluations) {
      if (_extractDomainStatus(domain).toLowerCase() == "unsafe") {
        return true;
      }
    }

    return false;
  }

  (Color, Color, Color) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case "safe":
        return (
          const Color(0xFF2F7A4B),
          const Color(0xFFE8F6EC),
          const Color(0xFFCDE7D4),
        );
      case "warning":
      case "cannot_assess":
        return (
          const Color(0xFF9A6414),
          const Color(0xFFFBF1DD),
          const Color(0xFFF0D8A9),
        );
      case "violation":
      case "unsafe":
        return (
          const Color(0xFF9B4233),
          const Color(0xFFFBE7E4),
          const Color(0xFFF0C3BC),
        );
      default:
        return (
          const Color(0xFF56685C),
          const Color(0xFFF1F4F2),
          const Color(0xFFD7E0D9),
        );
    }
  }

  Future<void> _loadSupplementarySection() async {
    if (_shouldShowAlternativesSection()) {
      final alternativesResult = await AlternativeSuggestionsService.fetchSuggestions(
        product: widget.product,
        ingredients: widget.ingredients,
        additives: widget.additives,
        allergens: widget.allergens,
        nutriments: widget.nutriments,
        nutrientLevels: widget.nutrientLevels,
        nutriScore: widget.nutriScore,
        novaGroup: widget.novaGroup,
        ranEvaluations: widget.ranEvaluations,
        evaluationResults: widget.evaluationResults,
        userMarketCountry: widget.userMarketCountry,
        marketCountrySource: widget.userMarketCountrySource,
      );

      if (!mounted) return;

      setState(() {
        _alternatives = alternativesResult.suggestions;
        _alternativesConfidencePercent = alternativesResult.confidencePercent;
        _alternativesLoading = false;
        _tips = const [];
        _tipsConfidencePercent = null;
        _tipsLoading = false;
      });
      await _saveHistorySnapshot();
      return;
    }

    if (_shouldShowSuggestionsSection()) {
      final tipsResult = await EnjoySuggestionsService.fetchSuggestions(
        product: widget.product,
        ingredients: widget.ingredients,
        origin: _originCountry(widget.product),
        ranEvaluations: widget.ranEvaluations,
        evaluationResults: widget.evaluationResults,
      );

      if (!mounted) return;

      setState(() {
        _tips = tipsResult.tips;
        _tipsConfidencePercent = tipsResult.confidencePercent;
        _tipsLoading = false;
        _alternatives = const [];
        _alternativesConfidencePercent = null;
        _alternativesLoading = false;
      });
      await _saveHistorySnapshot();
      return;
    }

    if (!mounted) return;
    setState(() {
      _tips = const [];
      _tipsConfidencePercent = null;
      _tipsLoading = false;
      _alternatives = const [];
      _alternativesConfidencePercent = null;
      _alternativesLoading = false;
    });
    await _saveHistorySnapshot();
  }

  Future<void> _saveHistorySnapshot() async {
    if (widget.isHistoryEntry || _historySaved) return;

    final entry = <String, dynamic>{
      "epochMillis": _historyEpochMillis,
      "productName": _productName(widget.product),
      "productImage": imageUrl,
      "overallStatus": _overallDecisionStatusLabel(),
      "overallLine": _overallDecisionLine(),
      "analysisConfidencePercent": _overallAnalysisConfidencePercent(),
      "product": widget.product,
      "ingredients": widget.ingredients,
      "additives": widget.additives,
      "allergens": widget.allergens,
      "nutriments": widget.nutriments,
      "nutrientLevels": widget.nutrientLevels,
      "nutriScore": widget.nutriScore,
      "novaGroup": widget.novaGroup,
      "ranEvaluations": widget.ranEvaluations,
      "evaluationResults": widget.evaluationResults,
      "userMarketCountry": widget.userMarketCountry,
      "userMarketCountrySource": widget.userMarketCountrySource,
      "tips": _tips,
      "tipsConfidencePercent": _tipsConfidencePercent,
      "alternatives": _alternatives
          .map(
            (item) => {
              "type": item.type,
              "title": item.title,
              "reason": item.reason,
              "fitTags": item.fitTags,
              "localExamples": item.localExamples,
            },
          )
          .toList(),
      "alternativesConfidencePercent": _alternativesConfidencePercent,
    };

    await ScanHistoryService.upsertEntry(entry);
    _historySaved = true;
  }

  (Color, Color, Color, Color) _alternativeColors(String type) {
    switch (type) {
      case "budget_friendly":
        return (
          const Color(0xFF8D5E11),
          const Color(0xFFEEDFB6),
          const Color(0xFFFBF1DD),
          const Color(0xFFF9F3E6),
        );
      case "healthier_pick":
        return (
          const Color(0xFF2E6D49),
          const Color(0xFFD6E7DB),
          const Color(0xFFEAF5EC),
          const Color(0xFFF2F8F3),
        );
      default:
        return (
          const Color(0xFF355A9B),
          const Color(0xFFD8E2F3),
          const Color(0xFFEAF0FB),
          const Color(0xFFF3F6FC),
        );
    }
  }

  String _alternativeLabel(String type) {
    switch (type) {
      case "budget_friendly":
        return "Budget-Friendly";
      case "healthier_pick":
        return "Healthier Pick";
      default:
        return "Best Match";
    }
  }

  String _buildStaticHeaderSummary() {
    final processing = _novaLabel(widget.novaGroup);
    final guidance = _nutriGuidance(widget.nutriScore);
    return "$processing • $guidance";
  }

  String _productName(Map<String, dynamic> product) {
    return product["product_name"]?.toString().trim().isNotEmpty == true
        ? product["product_name"].toString().trim()
        : "Unknown Product";
  }

  String _buildSubtitle(Map<String, dynamic> product) {
    final category = _category(product) ?? "Food Product";
    final brand = product["brands"]?.toString().trim();

    final parts = <String>[];
    if (brand != null && brand.isNotEmpty) {
      parts.add(brand);
    }
    parts.add(category);

    return parts.join(" • ");
  }

  String? _category(Map<String, dynamic> product) {
    final raw = product["categories"]?.toString();
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(",");
    return parts.isNotEmpty ? parts.last.trim() : null;
  }

  String? _originCountry(Map<String, dynamic> product) {
    final originsTags = product["origins_tags"];
    if (originsTags is List && originsTags.isNotEmpty) {
      final first = originsTags.first.toString();
      return _humanizeOriginTag(first);
    }

    final originsHierarchy = product["origins_hierarchy"];
    if (originsHierarchy is List && originsHierarchy.isNotEmpty) {
      final first = originsHierarchy.first.toString();
      return _humanizeOriginTag(first);
    }

    final countriesTags = product["countries_tags"];
    if (countriesTags is List && countriesTags.isNotEmpty) {
      final first = countriesTags.first.toString();
      return _humanizeOriginTag(first);
    }

    final origins = product["origins"]?.toString().trim();
    if (origins != null && origins.isNotEmpty) {
      return origins;
    }

    final countries = product["countries"]?.toString().trim();
    if (countries != null && countries.isNotEmpty) {
      return countries.replaceFirst(RegExp(r"^[a-z]{2}:"), "");
    }

    return null;
  }

  String? _displayOriginLabel({
    required String? originCountry,
    required String? geoCountry,
  }) {
    final cleanedOrigin = originCountry?.trim();
    if (cleanedOrigin == null || cleanedOrigin.isEmpty) return null;

    if (_sameCountry(cleanedOrigin, geoCountry)) {
      final flag = _countryFlagEmoji(cleanedOrigin);
      if (flag != null) {
        return "$cleanedOrigin $flag";
      }
    }

    return cleanedOrigin;
  }

  String? _displayScanFromLabel({
    required String? originCountry,
    required String? geoCountry,
  }) {
    final cleanedGeo = geoCountry?.trim();
    if (cleanedGeo == null || cleanedGeo.isEmpty) return null;
    if (_sameCountry(originCountry, cleanedGeo)) return null;

    final flag = _countryFlagEmoji(cleanedGeo);
    return flag == null ? cleanedGeo : "$cleanedGeo $flag";
  }

  bool _sameCountry(String? first, String? second) {
    final a = _normalizeCountryName(first);
    final b = _normalizeCountryName(second);
    if (a == null || a.isEmpty || b == null || b.isEmpty) return false;
    return a == b;
  }

  String _humanizeOriginTag(String tag) {
    final normalized = tag.contains(":") ? tag.split(":").last : tag;
    final words = normalized.split("-");
    return words
        .where((word) => word.isNotEmpty)
        .map((word) => "${word[0].toUpperCase()}${word.substring(1)}")
        .join(" ");
  }

  String? _countryFlagEmoji(String countryName) {
    const countryCodes = {
      "Argentina": "AR",
      "Australia": "AU",
      "Austria": "AT",
      "Belgium": "BE",
      "Brazil": "BR",
      "Canada": "CA",
      "China": "CN",
      "Croatia": "HR",
      "Czech Republic": "CZ",
      "Denmark": "DK",
      "Estonia": "EE",
      "Finland": "FI",
      "France": "FR",
      "Germany": "DE",
      "Greece": "GR",
      "Hungary": "HU",
      "India": "IN",
      "Ireland": "IE",
      "Italy": "IT",
      "Japan": "JP",
      "Latvia": "LV",
      "Lithuania": "LT",
      "Mexico": "MX",
      "Netherlands": "NL",
      "New Zealand": "NZ",
      "Norway": "NO",
      "Poland": "PL",
      "Portugal": "PT",
      "Romania": "RO",
      "Slovakia": "SK",
      "Slovenia": "SI",
      "South Korea": "KR",
      "Spain": "ES",
      "Sweden": "SE",
      "Switzerland": "CH",
      "Thailand": "TH",
      "Turkey": "TR",
      "Ukraine": "UA",
      "United Kingdom": "GB",
      "United States": "US",
    };

    final normalized = _normalizeCountryDisplay(countryName);
    final code = countryCodes[normalized];
    if (code == null || code.length != 2) return null;

    final first = code.codeUnitAt(0) - 65 + 0x1F1E6;
    final second = code.codeUnitAt(1) - 65 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }

  String? _normalizeCountryName(String? value) {
    final display = _normalizeCountryDisplay(value);
    return display.toLowerCase();
  }

  String _normalizeCountryDisplay(String? value) {
    final raw = (value ?? "")
        .replaceFirst(RegExp(r"^[a-z]{2}:"), "")
        .split(",")
        .first
        .trim();

    switch (raw.toLowerCase()) {
      case "suomi":
        return "Finland";
      case "deutschland":
        return "Germany";
      case "sverige":
        return "Sweden";
      case "norge":
        return "Norway";
      case "espana":
      case "españa":
        return "Spain";
      case "italia":
        return "Italy";
      case "france":
        return "France";
      default:
        return raw;
    }
  }

  String? _getBestImage(Map<String, dynamic> product) {
    try {
      final selectedImages = product["selected_images"];
      if (selectedImages is Map &&
          selectedImages["front"] is Map &&
          selectedImages["front"]["display"] is Map) {
        final displayMap =
            Map<String, dynamic>.from(selectedImages["front"]["display"]);
        if (displayMap.isNotEmpty) {
          return displayMap.values.first.toString();
        }
      }

      final imageFrontUrl = product["image_front_url"]?.toString();
      if (imageFrontUrl != null && imageFrontUrl.isNotEmpty) {
        return imageFrontUrl;
      }

      final imageUrl = product["image_url"]?.toString();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return imageUrl;
      }

      final imageSmallUrl = product["image_small_url"]?.toString();
      if (imageSmallUrl != null && imageSmallUrl.isNotEmpty) {
        return imageSmallUrl;
      }
    } catch (_) {}

    return null;
  }

  Color _nutriScoreColor(String? score) {
    switch ((score ?? "").toUpperCase()) {
      case "A":
        return const Color(0xFF1D8F47);
      case "B":
        return const Color(0xFF63A62F);
      case "C":
        return const Color(0xFFF2A623);
      case "D":
        return const Color(0xFFE67E22);
      case "E":
        return const Color(0xFFD64541);
      default:
        return const Color(0xFF8A97A6);
    }
  }

  Color _novaColor(int? group) {
    switch (group) {
      case 1:
        return const Color(0xFF1D8F47);
      case 2:
        return const Color(0xFF5EAE57);
      case 3:
        return const Color(0xFFF0A43A);
      case 4:
        return const Color(0xFFD96B2B);
      default:
        return const Color(0xFF8A97A6);
    }
  }

String _novaLabel(int? group) {
  switch (group) {
    case 1:
      return "Unprocessed or minimally processed";
    case 2:
      return "Processed culinary ingredients";
    case 3:
      return "Processed foods";
    case 4:
      return "Ultra-processed foods";
    default:
      return "Processing level unknown";
  }
}

  String _nutriGuidance(String? nutriScore) {
  switch ((nutriScore ?? "").toUpperCase()) {
    case "A":
      return "Suitable for regular consumption";
    case "B":
      return "Generally suitable for regular consumption";
    case "C":
      return "Consume in moderation";
    case "D":
      return "Limit consumption";
    case "E":
      return "Best consumed occasionally";
    default:
      return "Assess consumption based on dietary needs";
  }
}

}
