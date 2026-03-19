/// Validates and enforces the semantic contract of LLM reasoning output.
///
/// Rules enforced:
/// 1. status ↔ isSafe must be consistent
/// 2. unsafe MUST have structured findings
/// 3. safe MUST NOT have structured findings
/// 4. message text is NON-authoritative
///
/// Empty noisy items are REMOVED, not rejected.
///
/// Throws [StateError] only for true contradictions.
Map<String, dynamic> validateReasoningResult(
    Map<String, dynamic> raw,
    ) {
  if (raw.isEmpty || raw["result"] == null) {
    throw StateError("LLM response invalid: missing result object");
  }

  final result = Map<String, dynamic>.from(raw["result"]);

  final String? status = result["status"] as String?;
  final bool? isSafe = result["isSafe"] as bool?;

  if (status == null || isSafe == null) {
    throw StateError("LLM response invalid: missing status or isSafe");
  }

  final Map<String, dynamic> ingredients =
  result["ingredients"] is Map
      ? Map<String, dynamic>.from(result["ingredients"])
      : {};

  final Map<String, dynamic> additives =
  result["additives"] is Map
      ? Map<String, dynamic>.from(result["additives"])
      : {};

  // ------------------------------------------------------------
  // CLEAN NOISE (remove empty findings)
  // ------------------------------------------------------------
  void clean(Map<String, dynamic> m) {
    m.removeWhere((_, value) {
      if (value is! Map) return true;

      final List violates = (value["violates"] as List?) ?? const [];
      final List uncertain = (value["uncertain"] as List?) ?? const [];

      // 🔑 remove meaningless entries
      return violates.isEmpty && uncertain.isEmpty;
    });
  }

  clean(ingredients);
  clean(additives);

  final bool hasFindings =
      ingredients.isNotEmpty || additives.isNotEmpty;

  // ------------------------------------------------------------
  // 1️⃣ status ↔ isSafe must agree
  // ------------------------------------------------------------
  if (status == "safe" && isSafe != true) {
    throw StateError(
      "LLM response invalid: status=safe but isSafe=false",
    );
  }

  if (status == "unsafe" && isSafe != false) {
    throw StateError(
      "LLM response invalid: status=unsafe but isSafe=true",
    );
  }

  // ------------------------------------------------------------
  // 2️⃣ Unsafe requires structured evidence
  // ------------------------------------------------------------
  if (status == "unsafe" && !hasFindings) {
    throw StateError(
      "LLM response invalid: unsafe status without findings",
    );
  }

  // ------------------------------------------------------------
  // 3️⃣ Safe forbids structured evidence
  // ------------------------------------------------------------
  if (status == "safe" && hasFindings) {
    throw StateError(
      "LLM response invalid: safe status with findings present",
    );
  }

  // ------------------------------------------------------------
  // Passed all guards → safe to use
  // ------------------------------------------------------------
  result["ingredients"] = ingredients;
  result["additives"] = additives;

  return { "result": result };
}
