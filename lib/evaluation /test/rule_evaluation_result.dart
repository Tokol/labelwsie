class RuleEvaluationResult {
  final String ruleId;
  final bool triggered;
  final List<String> matchedIngredients;

  const RuleEvaluationResult({
    required this.ruleId,
    required this.triggered,
    required this.matchedIngredients,
  });

  @override
  String toString() {
    return 'RuleEvaluationResult(ruleId: $ruleId, '
        'triggered: $triggered, '
        'matchedIngredients: $matchedIngredients)';
  }
}
