// muslim_rules.dart
const muslimBasic = <String>[
  "contains_pork",
  "contains_alcohol",
  "contains_haram_processing_aids",
  "contains_blood_products",
];

const muslimStandard = <String>[
  // Everything from Basic
  "contains_pork",
  "contains_alcohol",
  "contains_haram_processing_aids",
  "contains_blood_products",

  // Additional common Standard rules:
  "contains_gelatin",
  "contains_animal_enzymes",
  "contains_animal_fats_unspecified",
  "contains_risky_e_numbers",
  "contains_ambiguous_flavorings",
  "contains_vinegar_from_wine",
  "contains_wine_extract_or_aroma",
  "contains_ethanol_carrier",
  "contains_unspecified_meat",

  // Seafood is allowed except non-kosher ones (no problem)
  // Fish gelatin may be processed with alcohol, so standard flags it:
  "contains_fish_gelatin",
];

const muslimStrict = <String>[
  // Everything from Standard
  "contains_pork",
  "contains_alcohol",
  "contains_haram_processing_aids",
  "contains_blood_products",

  "contains_gelatin",
  "contains_animal_enzymes",
  "contains_animal_fats_unspecified",
  "contains_risky_e_numbers",
  "contains_ambiguous_flavorings",
  "contains_vinegar_from_wine",
  "contains_wine_extract_or_aroma",
  "contains_ethanol_carrier",
  "contains_unspecified_meat",
  "contains_fish_gelatin",

  // Strict-only additions (the strongest checks):
  "requires_halal_certification",
  "requires_zabiha_only",

  // Non-meat but unsafe under strict halal
  "contains_non_vegetarian_additives",
  "contains_l_cysteine",

  // Fish/seafood is halal, but processing ambiguity must be flagged
  "contains_non_kosher_seafood",   // used as a "doubtful seafood" flag (optional but safe)
];
