import '../../evaluation /lifestyle_evaluation.dart';
import '../../evaluation /medical_based_evaluation.dart';
import '../../evaluation /orchestrator/allergy_evaluator.dart';
import '../../evaluation /orchestrator/ethical_evaluator.dart';
import '../../evaluation /orchestrator/religion_evaluation.dart';

class FoodAnalysisInput {
  final Map<String, dynamic> product;
  final List<String> ingredients;
  final List<String> additives;
  final List<String> productAllergens;
  final Map<String, double> nutriments;
  final Map<String, String> nutrientLevels;
  final String? nutriScore;
  final int? novaGroup;

  const FoodAnalysisInput({
    required this.product,
    required this.ingredients,
    required this.additives,
    required this.productAllergens,
    required this.nutriments,
    required this.nutrientLevels,
    required this.nutriScore,
    required this.novaGroup,
  });
}

class FoodAnalysisResult {
  final List<String> ranEvaluations;
  final Map<String, dynamic> evaluationResults;

  const FoodAnalysisResult({
    required this.ranEvaluations,
    required this.evaluationResults,
  });
}

class FoodAnalysisProcessor {
  FoodAnalysisProcessor._();

  static Future<FoodAnalysisResult> process({
    required FoodAnalysisInput input,
    required Map<String, dynamic> prefs,
  }) async {
    final religionPrefRaw = prefs["religion"];
    final ethicalPrefRaw = prefs["ethical"];
    final medicalPrefRaw = prefs["medical"];
    final lifestylePrefRaw = prefs["lifestyle"];
    final allergyPrefRaw = prefs["allergy"];

    final Map<String, dynamic>? religionPref =
        religionPrefRaw is Map && religionPrefRaw.isNotEmpty
            ? Map<String, dynamic>.from(religionPrefRaw)
            : null;

    final List<Map<String, dynamic>> ethicalPrefs = ethicalPrefRaw is List
        ? ethicalPrefRaw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : [];

    final List<Map<String, dynamic>> medicalPrefs = medicalPrefRaw is List
        ? medicalPrefRaw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : [];

    final List<Map<String, dynamic>> lifestylePrefs = [];
    if (lifestylePrefRaw is Map) {
      final restrictGoals = lifestylePrefRaw["restrict_goals"];
      final awarenessGoals = lifestylePrefRaw["awareness_goals"];

      if (restrictGoals is List) {
        for (final goal in restrictGoals.whereType<Map>()) {
          lifestylePrefs.add({
            ...Map<String, dynamic>.from(goal),
            "type": "restriction",
          });
        }
      }

      if (awarenessGoals is List) {
        for (final goal in awarenessGoals.whereType<Map>()) {
          lifestylePrefs.add({
            ...Map<String, dynamic>.from(goal),
            "type": "awareness",
          });
        }
      }
    }

    final Map<String, dynamic>? allergyPrefs =
        allergyPrefRaw is Map && allergyPrefRaw.isNotEmpty
            ? Map<String, dynamic>.from(allergyPrefRaw)
            : null;

    final ranEvaluations = <String>[];
    final evaluationResults = <String, dynamic>{};

    if (religionPref != null) {
      final evaluation = ReligionEvaluation(
        religionRule: religionPref,
        ingredients: input.ingredients,
        additives: input.additives,
      );
      evaluationResults["religion"] = await evaluation.evaluate();
      ranEvaluations.add("religion");
    }

    if (ethicalPrefs.isNotEmpty) {
      final evaluation = EthicalEvaluation(
        ethicalPrefs: ethicalPrefs,
        ingredients: input.ingredients,
        additives: input.additives,
      );
      evaluationResults["ethical"] = await evaluation.evaluate();
      ranEvaluations.add("ethical");
    }

    if (allergyPrefs != null) {
      final evaluation = AllergyEvaluation(
        allergyPrefs: allergyPrefs,
        ingredients: input.ingredients,
        additives: input.additives,
        productAllergens: input.productAllergens,
      );
      evaluationResults["allergy"] = await evaluation.evaluate();
      ranEvaluations.add("allergy");
    }

    if (medicalPrefs.isNotEmpty) {
      final evaluation = ReasonBasedMedicalEvaluation(
        medicalPrefs: medicalPrefs,
        ingredients: input.ingredients,
        additives: input.additives,
        nutriments: input.nutriments,
        nutrientLevels: input.nutrientLevels,
        novaGroup: input.novaGroup,
        nutriScore: input.nutriScore,
      );
      evaluationResults["medical"] = await evaluation.evaluate();
      ranEvaluations.add("medical");
    }

    if (lifestylePrefs.isNotEmpty) {
      final evaluation = LifestyleEvaluation(
        lifestyleGoals: lifestylePrefs,
        ingredients: input.ingredients,
        additives: input.additives,
        nutriments: input.nutriments,
        nutrientLevels: input.nutrientLevels,
        novaGroup: input.novaGroup,
        nutriScore: input.nutriScore,
      );
      evaluationResults["lifestyle"] = await evaluation.evaluate();
      ranEvaluations.add("lifestyle");
    }

    return FoodAnalysisResult(
      ranEvaluations: ranEvaluations,
      evaluationResults: evaluationResults,
    );
  }
}
